<#
.SYNOPSIS
Deletes everything previous runs of Alexandria left behind, so the next one
starts as a first launch.

.DESCRIPTION
State outlives a run in three places: the scratch catalog under .dev, the
application-support folder holding the preferences, the real catalog and the
log, and the core's thumbnail cache. Testing what an owner sees the first time
they open the application means removing all three, and nothing else writes
down where they are.

Runtime state only. build\, .dart_tool\, native\windows\*.dll and the core's
target\ are left alone: this is a fresh install, not a fresh clone, and a clean
run should not cost a full rebuild.

Nothing here can reach a library source folder. The paths are fixed and none of
them is derived from the catalog, so no indexed music, video or image is
reachable from this script.

tools\dev.ps1 -Clean runs this first and then builds and starts as usual.

.PARAMETER RealCatalog
Also delete the real catalog — the one -RealData runs against. Off by default:
without it the application-support folder is emptied around the catalog,
preferences and logs included, and the catalog is left where it is.

.PARAMETER WhatIf
List what would be removed and touch nothing.

.PARAMETER Confirm
Ask before each removal.

.EXAMPLE
.\tools\clean.ps1 -WhatIf
See what a clean would remove.

.EXAMPLE
.\tools\clean.ps1
Start the next run from nothing, keeping the real catalog.

.EXAMPLE
.\tools\clean.ps1 -RealCatalog
The same, and delete the real catalog too.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch] $RealCatalog
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot

function Write-Step($message) { Write-Host "==> $message" -ForegroundColor Cyan }
function Write-Note($message) { Write-Host "    $message" -ForegroundColor DarkGray }
function Fail($message) { Write-Host "error: $message" -ForegroundColor Red; exit 1 }

# ------------------------------------------------------------------- the paths

# Windows resolves the application-support directory as
# CompanyName\ProductName read from the executable's VERSIONINFO, which
# windows\runner\Runner.rc sets. These two constants must agree with that file.
$Company = 'com.arturrios'
$Product = 'Alexandria'

# The folder the application itself creates inside that one; must agree with
# CorePaths.applicationFolderName in lib\core\startup\core_paths.dart.
$ApplicationFolder = 'Alexandria'

# What the application was called before commit d86b493 renamed it. A stale
# preferences file here is not merely clutter for anyone who still has an
# older build around.
$LegacyProduct = 'alexandria_desktop'

$AppData = $env:APPDATA
if (-not $AppData) { Fail 'APPDATA is not set; cannot find the application-support folder.' }

$SupportFolder = Join-Path (Join-Path $AppData $Company) $Product
$LegacyFolder = Join-Path (Join-Path $AppData $Company) $LegacyProduct
$Scratch = Join-Path $RepoRoot '.dev'
$Thumbnails = Join-Path $RepoRoot 'thumbnails'

# --------------------------------------------------------------------- removal

function Remove-Target {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $What
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Note "absent: $Path"
        return
    }

    # Rather than testing $WhatIfPreference and printing a line of our own: this
    # is what makes -Confirm mean something as well, and CmdletBinding puts
    # -Confirm in the syntax whether or not it is honoured.
    if (-not $PSCmdlet.ShouldProcess($Path, "remove the $What")) { return }

    try {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
    } catch {
        Fail @"
could not remove $Path

$($_.Exception.Message)

Alexandria is most likely still running: Windows holds catalog.db and
alexandria_ffi.dll open for as long as it is. Quit it and run this again.
"@
    }

    Write-Note "removed the $What`: $Path"
}

# Empties the application-support folder while leaving the catalog where it is.
#
# The -wal and -shm files go with it rather than being deleted around it:
# they are part of the database, and removing a write-ahead log from under a
# catalog is how a catalog stops opening.
function Clear-AroundCatalog {
    param([Parameter(Mandatory)] [string] $Path)

    $keep = @('catalog.db', 'catalog.db-wal', 'catalog.db-shm')
    $inner = Join-Path $Path $ApplicationFolder

    foreach ($child in Get-ChildItem -LiteralPath $Path -Force) {
        if ($child.FullName -eq $inner) { continue }
        Remove-Target -Path $child.FullName -What 'application state'
    }

    foreach ($child in Get-ChildItem -LiteralPath $inner -Force) {
        if ($keep -contains $child.Name) { continue }
        Remove-Target -Path $child.FullName -What 'application state'
    }

    Write-Note "preserved the real catalog: $(Join-Path $inner 'catalog.db')"
    Write-Note 'pass -RealCatalog to delete it as well'
}

# ------------------------------------------------------------------- the sweep

if ($WhatIfPreference) {
    Write-Step 'Listing what a clean would remove; nothing will be touched'
} else {
    Write-Step 'Removing what previous runs left behind'
}

Remove-Target -Path $Scratch -What 'scratch catalog'

$catalog = Join-Path (Join-Path $SupportFolder $ApplicationFolder) 'catalog.db'

if ((-not $RealCatalog) -and (Test-Path -LiteralPath $catalog)) {
    Clear-AroundCatalog -Path $SupportFolder
} else {
    Remove-Target -Path $SupportFolder -What 'application-support folder'
}

Remove-Target -Path $Thumbnails -What 'thumbnail cache'
Remove-Target -Path $LegacyFolder -What 'folder left by an earlier version'

if ($WhatIfPreference) {
    Write-Step 'Nothing was removed (-WhatIf)'
} else {
    Write-Step 'Clean'
    Write-Note 'the next run starts as a first launch'
}

# Explicit, so that dev.ps1 -Clean can read $LASTEXITCODE: a script that falls
# off its end leaves whatever the last command set there, which is nothing on a
# run where every path was already absent.
exit 0
