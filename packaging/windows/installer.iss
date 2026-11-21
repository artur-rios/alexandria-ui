; IR-16: the Windows installer executable.
;
; Inno Setup rather than an MSI: the product installs into the owner's own
; profile, registers nothing system-wide, and has no service to configure —
; which is the whole of what this script needs to express.
;
; The installer is produced unsigned. Code signing needs a certificate the
; project does not hold yet, recorded as deliberately deferred in
; Operations & Infrastructure Document §7.2.
;
; The [Code] section at the bottom is what makes an upgrade an upgrade rather
; than an overlay. Inno's own "same AppId in the same directory" handling
; covers the ordinary case, but not the two that matter here: a directory the
; owner picked by hand that already holds Alexandria, and an installation left
; behind somewhere else when they change the directory. Both are found and
; offered for removal, and the removal is targeted — see RemovePayload.
;
; A replacement is staged (update-check design §3 step 4): the new files are
; copied into a folder inside the install directory, and only once every one
; is there are the old program files moved aside and the new ones moved in —
; renames on one volume — restoring the old ones if that fails. A setup that
; dies part-way, a full disk, or a cancelled install leaves the previous
; version as it was. The in-app updater runs this setup silently with
; /UPDATE, which answers this script's own questions with their defaults and
; starts the application again afterwards.

#define AppName "Alexandria"
#define AppPublisher "Artur Rios"
#define AppExeName "alexandria.exe"
#define AppVersion GetEnv('ALEXANDRIA_VERSION')

; The GUID lives here rather than being spelled out twice. `{{#AppGuid}` below
; expands to `{{<guid>}`, which is Inno's escape for a literal brace, and
; `{#AppGuid}` inside [Code] expands to the bare `{<guid>}` the uninstall
; registry key is named after. A GUID that drifted between the two would make
; the code silently stop finding what the installer itself registered.
#define AppGuid "{8F2A6C41-9B3E-4D77-A5C2-1E6D0B9F4A38}"

[Setup]
AppId={{#AppGuid}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppSupportURL=https://github.com/artur-rios/alexandria-ui
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=alexandria-setup-{#AppVersion}
; The wizard wears the application's own icon, rather than Inno Setup's
; default one. The same file the executable embeds through Runner.rc, so the
; icon the owner clicks to install is the icon they end up with.
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; NFR-07: the application is usable at 1024 x 640, so Windows 10 x64 and later.
MinVersion=10.0

; The Restart Manager closes a running Alexandria before files are replaced.
; Without it, upgrading while the application is open fails on a locked
; alexandria.exe or a loaded alexandria_ffi.dll — and a half-replaced
; bundle is worse than a refused one. Nothing is restarted afterwards: the
; [Run] entry below already offers to launch it.
CloseApplications=yes
RestartApplications=no

; DefaultDirName is {autopf}, so the owner may reasonably want either a
; per-machine install under Program Files or a per-user one. Letting them
; choose is also what makes the per-user uninstall key under HKCU worth
; searching for in [Code].
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[CustomMessages]
english.ReplaceHere=%1 is already installed in:%n%n%2%n%nIt will be replaced by %3 once %3 has been copied; if that fails, it is kept as it is. Your library, catalog, and settings are left where they are and are not touched.%n%nReplace it and continue?
brazilianportuguese.ReplaceHere=O %1 já está instalado em:%n%n%2%n%nEle será substituído pela versão %3 assim que ela for copiada; se isso falhar, ele é mantido como está. Sua biblioteca, seu catálogo e suas configurações permanecem onde estão e não são alterados.%n%nSubstituir e continuar?

english.RemoveElsewhere=%1 is also installed in another location:%n%n%2%n%nYou chose to install into a different directory, so that copy would be left behind.%n%nRemove it as well?
brazilianportuguese.RemoveElsewhere=O %1 também está instalado em outro local:%n%n%2%n%nVocê escolheu instalar em um diretório diferente, então aquela cópia ficaria para trás.%n%nRemover também?

english.SwapFailed=The new version could not be put in place, so the previous installation was kept as it was.
brazilianportuguese.SwapFailed=A nova versão não pôde ser colocada no lugar, então a instalação anterior foi mantida como estava.

english.UninstallFailed=The previous installation's uninstaller did not finish cleanly. Setup will remove the program files in that directory itself.
brazilianportuguese.UninstallFailed=O desinstalador da instalação anterior não terminou corretamente. A instalação removerá os arquivos do programa naquele diretório por conta própria.

[Files]
; The whole release bundle, which already carries alexandria_ffi.dll beside the
; executable — that is what IR-04's "resolved relative to the installed
; application" resolves to.
;
; Excluding the MSIX is not tidiness. `dart run msix:create` writes
; alexandria.msix into this same directory, and the release workflow (release-windows.yml) builds it
; before this installer, so without the exclusion the setup executable carries
; a complete second copy of the application inside itself — roughly doubling
; its size — and then installs that copy beside the program as a stray file.
; Excluded here rather than fixed by reordering the workflow, because the order
; of two independent packaging steps is not something this script should have
; to depend on.
Source: "..\..\build\windows\x64\runner\Release\*"; \
  DestDir: "{app}\.staging-update"; Excludes: "*.msix"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

; Files are copied into the staging folder and moved into place by [Code], so
; the uninstall log names the staging paths. These name the real ones —
; exactly the paths RemovePayload removes, and nothing else in the directory.
[UninstallDelete]
Type: files; Name: "{app}\{#AppExeName}"
Type: files; Name: "{app}\FFMPEG-LICENSE.txt"
Type: files; Name: "{app}\*.dll"
Type: filesandordirs; Name: "{app}\data"
Type: dirifempty; Name: "{app}\.staging-update"
Type: dirifempty; Name: "{app}"

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; \
  GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Run]
Filename: "{app}\{#AppExeName}"; \
  Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; \
  Flags: nowait postinstall skipifsilent
; An update started from inside the application: it closed itself to be
; replaced, so it is started again — as the owner, not as setup's own token.
Filename: "{app}\{#AppExeName}"; Check: IsUpdate; \
  Flags: nowait runasoriginaluser

; Nothing is uninstalled separately: the core is a library inside the bundle,
; not a service (§7.3). The owner's catalog and settings live in their
; application-support directory and are deliberately left in place.

[Code]
const
  UninstallKey =
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppGuid}_is1';

var
  RecordedLocation: String;
  { Decided on the directory page, carried out once the files are staged. }
  RemoveElsewhere: Boolean;

{ Whether the application started this setup to update itself. }
function IsUpdate(): Boolean;
begin
  Result := Pos('/UPDATE', UpperCase(GetCmdTail())) > 0;
end;

{ Where a previous install registered itself, if it did.

  All four views are searched rather than just the one this run would write to.
  A per-machine install registers under HKLM in the 64-bit view; a per-user one
  registers under HKCU; and PrivilegesRequiredOverridesAllowed means the owner
  can pick a different one this time than last time. Searching only the current
  view would miss exactly the case this code exists for. }
function FindRecordedLocation(): String;
var
  Views: array[0..3] of Integer;
  Index: Integer;
  Location: String;
begin
  Result := '';

  Views[0] := HKLM64;
  Views[1] := HKLM32;
  Views[2] := HKCU64;
  Views[3] := HKCU32;

  for Index := 0 to 3 do
  begin
    if RegQueryStringValue(Views[Index], UninstallKey, 'InstallLocation', Location) then
    begin
      Location := RemoveBackslashUnlessRoot(Trim(Location));
      if (Location <> '') and DirExists(Location) then
      begin
        Result := Location;
        Exit;
      end;
    end;
  end;
end;

{ An installation is "there" if what matters is there: the executable, or the
  uninstaller a previous Inno-built setup left beside it. A directory holding
  only leftovers still counts — clearing it is the point. }
function DirectoryHoldsInstall(const Directory: String): Boolean;
begin
  Result := (Directory <> '') and
            (FileExists(Directory + '\{#AppExeName}') or
             FileExists(Directory + '\unins000.exe'));
end;

{ Inno's uninstaller relaunches itself from a temporary copy and the first
  process returns immediately, so Exec's wait says nothing about whether the
  uninstall finished. What does say so is unins000.exe itself disappearing —
  it is deleted once the uninstall completes. Bounded at a minute so a stuck
  uninstaller leaves the wizard responsive rather than hung; the caller falls
  back to removing the files directly. }
function WaitForUninstaller(const UninstallerPath: String): Boolean;
var
  Waited: Integer;
begin
  Waited := 0;
  while FileExists(UninstallerPath) and (Waited < 120) do
  begin
    Sleep(500);
    Waited := Waited + 1;
  end;
  Result := not FileExists(UninstallerPath);
end;

{ Removes only the paths this payload writes. Deliberately not a DelTree of the
  directory: the owner chooses it by hand on the directory page, and one who
  points setup at a folder holding unrelated files must not lose them. }
procedure RemovePayload(const Directory: String);
begin
  if Directory = '' then
    Exit;

  DeleteFile(Directory + '\{#AppExeName}');
  DeleteFile(Directory + '\FFMPEG-LICENSE.txt');

  { The Flutter runner, its plugins, the core, and the ffmpeg libraries all
    land flat beside the executable, and their names carry versions that move.
    Matching them is what keeps a stale alexandria_ffi.dll or an avcodec from
    the previous release out of the new bundle — the leftover that surfaces
    later as an unrelated-looking "core could not be loaded". }
  DelTree(Directory + '\*.dll', False, True, False);
  DelTree(Directory + '\data', True, True, True);

  { Empty afterwards, or holding something that was not ours. Either way this
    only succeeds in the first case. }
  RemoveDir(Directory);
end;

{ Runs the uninstaller a previous setup registered, and reports whether it
  actually finished. }
function RunPreviousUninstaller(const Directory: String): Boolean;
var
  UninstallerPath: String;
  ResultCode: Integer;
begin
  UninstallerPath := Directory + '\unins000.exe';

  if not FileExists(UninstallerPath) then
  begin
    Result := False;
    Exit;
  end;

  if not Exec(UninstallerPath,
              '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART',
              '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    Result := False;
    Exit;
  end;

  Result := WaitForUninstaller(UninstallerPath);
end;

{ Uninstaller first, then a targeted sweep of whatever it left. The sweep runs
  either way: a clean uninstall leaves nothing for it to find, and a failed one
  is exactly when it is needed. }
procedure RemoveInstallation(const Directory: String; const WarnOnFailure: Boolean);
begin
  if FileExists(Directory + '\unins000.exe') then
    if (not RunPreviousUninstaller(Directory)) and WarnOnFailure then
      MsgBox(CustomMessage('UninstallFailed'), mbInformation, MB_OK);

  RemovePayload(Directory);
end;

function InitializeSetup(): Boolean;
begin
  RecordedLocation := FindRecordedLocation();
  Result := True;
end;

{ Note on formatting throughout this section: no line may *begin* with `[`,
  even inside Pascal code and even indented. The compiler decides what is a
  section header before it decides what is code, and a wrapped line whose first
  non-blank character is an open bracket is read as a section tag — which is
  what "Invalid section tag" on a line in the middle of a function means. Every
  argument array below is therefore built on a line that starts with
  something else. }

function NextButtonClick(CurPageID: Integer): Boolean;
var
  Chosen: String;
  Prompt: String;
begin
  Result := True;

  if CurPageID <> wpSelectDir then
    Exit;

  Chosen := RemoveBackslashUnlessRoot(WizardDirValue);

  { Nothing is removed here: the decisions are recorded, and carried out by
    SwapIn once the new files are staged. }
  RemoveElsewhere := False;

  { 1. An installation in the directory the owner actually chose. Refusing
       keeps them on the directory page rather than cancelling setup, so they
       can pick somewhere else. An update replaces it without asking: that is
       what the owner asked the application for. }
  if DirectoryHoldsInstall(Chosen) then
  begin
    if not IsUpdate() then
    begin
      Prompt := FmtMessage(CustomMessage('ReplaceHere'), ['{#AppName}', Chosen, '{#AppVersion}']);

      if MsgBox(Prompt, mbConfirmation, MB_YESNO) <> IDYES then
      begin
        Result := False;
        Exit;
      end;
    end;
  end;

  { 2. An installation somewhere else entirely — the owner changed the
       directory. Asked separately, and answering no is a real choice rather
       than a blocked one: two copies is a state they may want. An update
       leaves it alone. }
  if (not IsUpdate()) and
     (RecordedLocation <> '') and
     (CompareText(RecordedLocation, Chosen) <> 0) and
     DirectoryHoldsInstall(RecordedLocation) then
  begin
    Prompt := FmtMessage(CustomMessage('RemoveElsewhere'), ['{#AppName}', RecordedLocation]);

    if MsgBox(Prompt, mbConfirmation, MB_YESNO) = IDYES then
      RemoveElsewhere := True;
  end;
end;

{ Moves the entries of FromDir into ToDir — only the program's own files when
  PayloadOnly. Renames only, on one volume. False at the first that fails. }
function MoveEntries(const FromDir, ToDir: String; const PayloadOnly: Boolean): Boolean;
var
  Found: TFindRec;
  Name: String;
begin
  Result := True;
  if not FindFirst(FromDir + '\*', Found) then
    Exit;
  try
    repeat
      Name := Found.Name;
      if (Name = '.') or (Name = '..') or
         (CompareText(Name, '.staging-update') = 0) or
         (CompareText(Name, '.backup-update') = 0) then
        Continue;

      { The program's own files, as RemovePayload knows them: the executable,
        the ffmpeg licence, every DLL beside it, and the data folder. }
      if PayloadOnly and
         not ((CompareText(Name, '{#AppExeName}') = 0) or
              (CompareText(Name, 'FFMPEG-LICENSE.txt') = 0) or
              (CompareText(Name, 'data') = 0) or
              (CompareText(ExtractFileExt(Name), '.dll') = 0)) then
        Continue;

      if not RenameFile(FromDir + '\' + Name, ToDir + '\' + Name) then
      begin
        Log('could not move ' + FromDir + '\' + Name);
        Result := False;
        Exit;
      end;
    until not FindNext(Found);
  finally
    FindClose(Found);
  end;
end;

{ The swap: old program files aside, staged ones in, the backup gone. A failure
  part-way puts the old files back, so the previous version still runs. }
function SwapIn(const Directory: String): Boolean;
var
  Staging, Backup: String;
begin
  Staging := Directory + '\.staging-update';
  Backup := Directory + '\.backup-update';
  DelTree(Backup, True, True, True);
  ForceDirectories(Backup);

  Result := MoveEntries(Directory, Backup, True) and
            MoveEntries(Staging, Directory, False);

  if not Result then
  begin
    MoveEntries(Directory, Staging, True);
    MoveEntries(Backup, Directory, False);
  end;

  DelTree(Backup, True, True, True);
  DelTree(Staging, True, True, True);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Directory: String;
begin
  Directory := RemoveBackslashUnlessRoot(ExpandConstant('{app}'));

  { A staging folder a crashed run left behind would mix old files into new
    ones. }
  if CurStep = ssInstall then
    DelTree(Directory + '\.staging-update', True, True, True);

  if CurStep = ssPostInstall then
  begin
    if not SwapIn(Directory) then
    begin
      Log('the staged files could not be moved into place; the previous installation was kept');
      if not WizardSilent() then
        MsgBox(CustomMessage('SwapFailed'), mbError, MB_OK);
      Exit;
    end;

    if RemoveElsewhere then
      RemoveInstallation(RecordedLocation, False);
  end;
end;
