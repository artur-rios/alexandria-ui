<#
.SYNOPSIS
Builds the Alexandria core, wires it into this checkout, and runs the
application against it.

.DESCRIPTION
The whole product is two repositories: this front end and the core it links in
process over FFI. Running the real thing locally means building the core,
putting its shared library where IR-04's resolver looks, keeping the generated
FFI bindings in step with the core's header, and only then starting the app.
This does all four.

Nothing here is needed to package or ship — that is the release workflow's job.
This is the loop for changing code and seeing the change.

.PARAMETER Core
The core checkout to build. Defaults to $env:ALEXANDRIA_CORE_REPO, then to a
sibling directory named alexandria-api.

.PARAMETER SkipCore
Do not rebuild the core. Use it when only Dart changed — the library already in
native\windows is reused, which turns a cargo build into nothing at all.

.PARAMETER DebugBuild
Build the core unoptimised. Much faster to compile and appreciably slower to
run; indexing a large folder will drag. Worth it when iterating on core code,
not when judging how the product feels.

Named DebugBuild rather than Debug because CmdletBinding already defines -Debug
as a common parameter, and declaring a second one is an error. tools/dev.sh
spells the same thing --debug, where nothing is in the way.

.PARAMETER RealData
Run against the real catalog instead of a scratch one. Off by default so that
re-indexing, deleting, and purging while testing cannot touch a catalog you
care about.

.PARAMETER Generate
Run build_runner and gen-l10n before starting. Needed after changing anything
they generate from — models, or the localisation ARB files.

.PARAMETER NoRun
Do everything except start the application. For checking that the core builds
and the bindings are current.

.EXAMPLE
.\tools\dev.ps1
Build the core, sync the bindings, run against a scratch catalog.

.EXAMPLE
.\tools\dev.ps1 -SkipCore
Dart-only change: skip straight to running.

.EXAMPLE
.\tools\dev.ps1 -Core D:\somewhere\alexandria-api -DebugBuild
Build a core from elsewhere, unoptimised.
#>

[CmdletBinding()]
param(
    [string] $Core,
    [switch] $SkipCore,
    [switch] $DebugBuild,
    [switch] $RealData,
    [switch] $Generate,
    [switch] $NoRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $RepoRoot
try {
    function Write-Step($message) { Write-Host "==> $message" -ForegroundColor Cyan }
    function Write-Note($message) { Write-Host "    $message" -ForegroundColor DarkGray }
    function Fail($message) { Write-Host "error: $message" -ForegroundColor Red; exit 1 }

    # ---------------------------------------------------------------- preflight

    # Checked here rather than left to a compiler error four minutes in. Each of
    # these has its own confusing failure: cargo's is legible, ffmpeg's is a
    # bindgen error about a header it cannot find, and a missing ffmpeg bin on
    # PATH does not fail the build at all — it fails at launch, as an
    # unrelated-looking "the core could not be loaded".
    Write-Step 'Checking the toolchain'

    foreach ($tool in 'cargo', 'flutter') {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Fail "$tool is not on PATH. See the Building from source section of README.md."
        }
    }

    if (-not $SkipCore) {
        if (-not $env:FFMPEG_DIR) {
            Fail @'
FFMPEG_DIR is not set, and the core cannot build without ffmpeg's headers and
import libraries. It must point at a directory holding include\, lib\ and bin\
together — a "shared" or "dev" build, not one that only ships ffmpeg.exe. The
core repository's README walks through installing one.
'@
        }
        if (-not (Test-Path (Join-Path $env:FFMPEG_DIR 'include'))) {
            Fail "FFMPEG_DIR has no include\ directory: $env:FFMPEG_DIR"
        }
    }

    # The runtime half of the same dependency. The core links avcodec and the
    # rest by name, and Windows resolves those from PATH.
    $ffmpegBin = if ($env:FFMPEG_DIR) { Join-Path $env:FFMPEG_DIR 'bin' } else { $null }
    if ($ffmpegBin -and (Test-Path $ffmpegBin)) {
        if (($env:PATH -split ';') -notcontains $ffmpegBin) {
            Write-Note "adding ffmpeg's bin to PATH for this run only: $ffmpegBin"
            $env:PATH = "$ffmpegBin;$env:PATH"
        }
    }

    # ------------------------------------------------------------ the core repo

    if (-not $SkipCore) {
        if (-not $Core) { $Core = $env:ALEXANDRIA_CORE_REPO }
        if (-not $Core) { $Core = Join-Path (Split-Path -Parent $RepoRoot) 'alexandria-api' }

        if (-not (Test-Path (Join-Path $Core 'Cargo.toml'))) {
            Fail @"
No core checkout at: $Core

Pass -Core <path>, set ALEXANDRIA_CORE_REPO, or clone it beside this one:
  git clone https://github.com/artur-rios/alexandria-api.git
"@
        }
        $Core = (Resolve-Path $Core).Path
        Write-Note "core: $Core"
    }

    # ------------------------------------------------------------ build the core

    $profileName = if ($DebugBuild) { 'debug' } else { 'release' }

    if ($SkipCore) {
        Write-Step 'Skipping the core build'
    } else {
        Write-Step "Building the core ($profileName)"
        $cargoArgs = @('build', '-p', 'alexandria-ffi')
        if (-not $DebugBuild) { $cargoArgs += '--release' }

        Push-Location $Core
        try {
            & cargo @cargoArgs
            if ($LASTEXITCODE -ne 0) { Fail 'the core did not build' }
        } finally { Pop-Location }

        $built = Join-Path $Core "target\$profileName\alexandria_ffi.dll"
        if (-not (Test-Path $built)) { Fail "cargo reported success but produced no library at $built" }

        # Where IR-04's resolver looks when running from a checkout.
        $destination = Join-Path $RepoRoot 'native\windows\alexandria_ffi.dll'
        New-Item -ItemType Directory -Force (Split-Path $destination) | Out-Null
        Copy-Item $built $destination -Force
        Write-Note "placed $([math]::Round((Get-Item $destination).Length / 1MB, 1)) MB at native\windows\alexandria_ffi.dll"

        # -------------------------------------------------------- the bindings

        # The header is generated by the core's own build, so it only exists
        # once the core has been built — which is why this follows rather than
        # precedes it.
        #
        # Compared with line endings normalised. This checkout stores the
        # vendored copy with CRLF and cbindgen writes LF, so a plain comparison
        # reports drift on every single run and quickly teaches you to ignore
        # it.
        $generated = Join-Path $Core 'crates\alexandria-ffi\src\header.h'
        $vendored = Join-Path $RepoRoot 'native\include\alexandria_ffi.h'

        if (-not (Test-Path $generated)) {
            Write-Note 'the core produced no header; leaving the bindings alone'
        } else {
            $normalise = { (Get-Content $args[0] -Raw) -replace "`r`n", "`n" }
            $before = & $normalise $vendored
            $after = & $normalise $generated

            if ($before -eq $after) {
                Write-Step 'Bindings are current'
            } else {
                Write-Step 'The core''s header changed; regenerating the bindings'
                Copy-Item $generated $vendored -Force
                & dart run ffigen --config ffigen.yaml
                if ($LASTEXITCODE -ne 0) { Fail 'ffigen failed' }
                Write-Note 'native\include\alexandria_ffi.h and lib\core\bindings updated - review and commit them'
            }
        }
    }

    # -------------------------------------------------------------- Dart codegen

    Write-Step 'Resolving Dart dependencies'
    & flutter pub get | Out-Null
    if ($LASTEXITCODE -ne 0) { Fail 'flutter pub get failed' }

    if ($Generate) {
        Write-Step 'Running the generators'
        & dart run build_runner build --delete-conflicting-outputs
        if ($LASTEXITCODE -ne 0) { Fail 'build_runner failed' }
        & flutter gen-l10n
        if ($LASTEXITCODE -ne 0) { Fail 'gen-l10n failed' }
    }

    # ------------------------------------------------------------------ the data

    if ($RealData) {
        Write-Step 'Running against the real catalog'
        Write-Note 'indexing, deleting and purging will affect it'
    } else {
        $scratch = Join-Path $RepoRoot '.dev\catalog.db'
        New-Item -ItemType Directory -Force (Split-Path $scratch) | Out-Null
        $env:ALEXANDRIA_DB_PATH = $scratch
        Write-Step 'Running against a scratch catalog'
        Write-Note $scratch
        Write-Note 'delete that file to start over; -RealData uses the real one'
        # Only the catalog is redirected. Settings and the log still live in the
        # application-support directory, shared with an installed copy — worth
        # knowing before blaming the scratch database for remembered state.
    }

    # ----------------------------------------------------------------- run it

    if ($NoRun) {
        Write-Step 'Built and wired up; not starting the application (-NoRun)'
        exit 0
    }

    Write-Step 'Starting Alexandria'
    Write-Note 'r hot-reloads Dart changes, R restarts, q quits'
    Write-Note 'core changes need this script again - the library is loaded once, at startup'
    & flutter run -d windows
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
