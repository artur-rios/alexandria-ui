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

; The mutex the Windows runner holds while the application runs
; (windows/runner/main.cpp): how this setup knows Alexandria is open. The two
; spellings must match.
#define AppMutex "Alexandria.Running.8F2A6C41"

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

; Not the Restart Manager: it looks only at the files setup overwrites, and
; those are now in an empty staging folder, so it never sees a running
; Alexandria. InitializeSetup checks the runner's mutex instead — waiting for
; the application to close when it started this setup with /UPDATE, asking the
; owner to close it otherwise.
CloseApplications=no
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

english.CloseApp=%1 is running. Close it, then choose Retry to continue.
brazilianportuguese.CloseApp=O %1 está aberto. Feche-o e escolha Repetir para continuar.

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
; the uninstall log names the staging paths. The swap records the top-level
; entries it put in place in .alexandria-payload, which uninstall reads
; (CurUninstallStepChanged); these name the rest of what RemovePayload
; removes, and nothing else in the directory.
[UninstallDelete]
Type: files; Name: "{app}\.alexandria-payload"
Type: files; Name: "{app}\{#AppExeName}"
Type: files; Name: "{app}\FFMPEG-LICENSE.txt"
Type: files; Name: "{app}\*.dll"
Type: filesandordirs; Name: "{app}\data"
Type: filesandordirs; Name: "{app}\.stale-update-*"
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
  FILE_ATTRIBUTE_NORMAL = $80;

var
  RecordedLocation: String;
  { The registry root RecordedLocation was found under. }
  RecordedRoot: Integer;
  { Decided on the directory page, carried out once the files are staged. }
  RemoveElsewhere: Boolean;

{ Used to clear the read-only attribute some bundled files carry, which
  DeleteFile and DelTree do not get past. }
function SetFileAttributesW(lpFileName: String; dwFileAttributes: Cardinal): Boolean;
  external 'SetFileAttributesW@kernel32.dll stdcall';

{ Clears every attribute of Path and of everything below it. }
procedure ClearAttributes(const Path: String);
var
  Found: TFindRec;
begin
  SetFileAttributesW(Path, FILE_ATTRIBUTE_NORMAL);
  if DirExists(Path) and FindFirst(Path + '\*', Found) then
  try
    repeat
      if (Found.Name <> '.') and (Found.Name <> '..') then
        ClearAttributes(Path + '\' + Found.Name);
    until not FindNext(Found);
  finally
    FindClose(Found);
  end;
end;

{ Deletes a folder or file this setup is done with: attributes cleared, and
  retried for a few seconds while an antivirus holds a file just moved. }
function RemoveTree(const Path: String): Boolean;
var
  Attempt: Integer;
begin
  Attempt := 0;
  while (DirExists(Path) or FileExists(Path)) and (Attempt < 10) do
  begin
    if Attempt > 0 then
      Sleep(500);
    ClearAttributes(Path);
    if DirExists(Path) then
      DelTree(Path, True, True, True)
    else
      DeleteFile(Path);
    Attempt := Attempt + 1;
  end;
  Result := not (DirExists(Path) or FileExists(Path));
  if not Result then
    Log('could not remove ' + Path);
end;

{ Removes the backups earlier successful swaps could not delete at the time. }
procedure RemoveStaleBackups(const Directory: String);
var
  Found: TFindRec;
  Names: TStringList;
  Index: Integer;
begin
  Names := TStringList.Create;
  try
    if FindFirst(Directory + '\.stale-update-*', Found) then
    try
      repeat
        Names.Add(Found.Name);
      until not FindNext(Found);
    finally
      FindClose(Found);
    end;
    for Index := 0 to Names.Count - 1 do
      RemoveTree(Directory + '\' + Names.Strings[Index]);
  finally
    Names.Free;
  end;
end;

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
        RecordedRoot := Views[Index];
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

{ The record of the top-level entries the last swap put in place. }
function PayloadRecord(const Directory: String): String;
begin
  Result := Directory + '\.alexandria-payload';
end;

{ Removes the entries the payload record names, and the record. A name that
  is not a plain entry of Directory is ignored, so a damaged record cannot
  reach outside it. }
procedure RemoveRecordedEntries(const Directory: String);
var
  Names: TArrayOfString;
  Index: Integer;
  Path: String;
begin
  if not LoadStringsFromFile(PayloadRecord(Directory), Names) then
    Exit;
  for Index := 0 to GetArrayLength(Names) - 1 do
  begin
    if (Trim(Names[Index]) = '') or (Names[Index] = '.') or (Names[Index] = '..') or
       (Pos('\', Names[Index]) > 0) or (Pos('/', Names[Index]) > 0) or (Pos(':', Names[Index]) > 0) then
      Continue;
    Path := Directory + '\' + Names[Index];
    RemoveTree(Path);
  end;
  DeleteFile(PayloadRecord(Directory));
end;

{ Removes only the paths this payload writes. Deliberately not a DelTree of the
  directory: the owner chooses it by hand on the directory page, and one who
  points setup at a folder holding unrelated files must not lose them. }
procedure RemovePayload(const Directory: String);
begin
  if Directory = '' then
    Exit;

  RemoveRecordedEntries(Directory);
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

{ The copy the owner moved away from, once the new one is in place. Not
  through its uninstaller: that would remove the uninstall entry and the Start
  menu and desktop shortcuts this setup has just written, which have the same
  names. Its program files go, its uninstaller with them, and its uninstall
  entry only when it lives in the other registry hive — the one this setup
  did not just rewrite. }
procedure RemoveOtherCopy(const Directory: String);
var
  RecordedPerMachine: Boolean;
begin
  DeleteFile(Directory + '\unins000.exe');
  DeleteFile(Directory + '\unins000.dat');
  RemovePayload(Directory);

  RecordedPerMachine := (RecordedRoot = HKLM64) or (RecordedRoot = HKLM32);
  if RecordedPerMachine <> IsAdminInstallMode() then
    if not RegDeleteKeyIncludingSubkeys(RecordedRoot, UninstallKey) then
      Log('the other copy''s uninstall entry stays: it needs other rights');
end;

{ Waits, a minute at most, for the application to close: it closes itself
  once it has started this setup. }
function WaitForAppToClose(): Boolean;
var
  Waited: Integer;
begin
  Waited := 0;
  while CheckForMutexes('{#AppMutex}') and (Waited < 120) do
  begin
    Sleep(500);
    Waited := Waited + 1;
  end;
  Result := not CheckForMutexes('{#AppMutex}');
end;

function InitializeSetup(): Boolean;
begin
  RecordedLocation := FindRecordedLocation();
  Result := True;

  { Files a running application holds cannot be moved aside, and the swap
    would fail. Nothing has changed yet, so stopping here keeps everything as
    it is. Suppressed message boxes answer Cancel, so a silent run that is not
    an update stops rather than waits forever. }
  if IsUpdate() then
  begin
    if not WaitForAppToClose() then
    begin
      Log('Alexandria did not close; nothing was changed');
      Result := False;
    end;
  end
  else
    while Result and CheckForMutexes('{#AppMutex}') do
      if SuppressibleMsgBox(FmtMessage(CustomMessage('CloseApp'), ['{#AppName}']),
                            mbError, MB_RETRYCANCEL, IDCANCEL) <> IDRETRY then
        Result := False;
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

{ The program's own files, as RemovePayload knows them: the executable, the
  ffmpeg licence, every DLL beside it, and the data folder. }
function IsPayloadEntry(const Name: String): Boolean;
begin
  Result := (CompareText(Name, '{#AppExeName}') = 0) or
            (CompareText(Name, 'FFMPEG-LICENSE.txt') = 0) or
            (CompareText(Name, 'data') = 0) or
            (CompareText(ExtractFileExt(Name), '.dll') = 0);
end;

{ The entries of Directory — only the program's own when PayloadOnly — listed
  before anything moves, so the listing is never read while it changes. }
function ListEntries(const Directory: String; const PayloadOnly: Boolean): TStringList;
var
  Found: TFindRec;
begin
  Result := TStringList.Create;
  if FindFirst(Directory + '\*', Found) then
  try
    repeat
      if (Found.Name <> '.') and (Found.Name <> '..') and
         (CompareText(Found.Name, '.staging-update') <> 0) and
         (CompareText(Found.Name, '.backup-update') <> 0) and
         (Pos('.stale-update-', Found.Name) <> 1) and
         ((not PayloadOnly) or IsPayloadEntry(Found.Name)) then
        Result.Add(Found.Name);
    until not FindNext(Found);
  finally
    FindClose(Found);
  end;
end;

{ Writes Names to FileName, one per line. }
procedure SaveNames(const Names: TStringList; const FileName: String);
var
  Lines: TArrayOfString;
  Index: Integer;
begin
  SetArrayLength(Lines, Names.Count);
  for Index := 0 to Names.Count - 1 do
    Lines[Index] := Names.Strings[Index];
  if not SaveStringsToFile(FileName, Lines, False) then
    Log('could not write ' + FileName);
end;

{ Adds Name to List when Directory holds an entry of that name and the list
  does not have it yet. }
procedure AddPresent(const List: TStringList; const Directory, Name: String);
begin
  if (FileExists(Directory + '\' + Name) or DirExists(Directory + '\' + Name)) and
     (List.IndexOf(Name) < 0) then
    List.Add(Name);
end;

{ The entries a replacement moves aside: the program's own as RemovePayload
  knows them, every entry the last swap recorded, and anything else under a
  name the new version brings — Chromium's .pak files, icudtl.dat and locales
  among them — whose name a rename could not otherwise take. Something the
  owner keeps in the folder under another name stays where it is. }
function AsideEntries(const Directory: String; const NewNames: TStringList): TStringList;
var
  Recorded: TArrayOfString;
  Index: Integer;
begin
  Result := ListEntries(Directory, True);
  for Index := 0 to NewNames.Count - 1 do
    AddPresent(Result, Directory, NewNames.Strings[Index]);
  if LoadStringsFromFile(PayloadRecord(Directory), Recorded) then
    for Index := 0 to GetArrayLength(Recorded) - 1 do
      if (Trim(Recorded[Index]) <> '') and (Pos('\', Recorded[Index]) = 0) and
         (Recorded[Index] <> '.') and (Recorded[Index] <> '..') then
        AddPresent(Result, Directory, Recorded[Index]);
end;

{ One rename, retried for a few seconds: an antivirus scanning a file just
  written holds it for a moment. }
function MoveEntry(const FromPath, ToPath: String): Boolean;
var
  Attempt: Integer;
begin
  Result := RenameFile(FromPath, ToPath);
  Attempt := 1;
  while (not Result) and (Attempt < 10) do
  begin
    Sleep(300);
    Result := RenameFile(FromPath, ToPath);
    Attempt := Attempt + 1;
  end;
  if not Result then
    Log('could not move ' + FromPath + ' to ' + ToPath);
end;

{ Moves Names from FromDir to ToDir in order, stopping at the first that
  fails; Moved says how many did. }
function MoveNames(const Names: TStringList; const FromDir, ToDir: String; var Moved: Integer): Boolean;
begin
  Result := True;
  Moved := 0;
  while Moved < Names.Count do
  begin
    if not MoveEntry(FromDir + '\' + Names.Strings[Moved], ToDir + '\' + Names.Strings[Moved]) then
    begin
      Result := False;
      Exit;
    end;
    Moved := Moved + 1;
  end;
end;

{ Moves the first Count of Names back from FromDir to ToDir, trying every one;
  true when all of them went. }
function MoveBack(const Names: TStringList; const Count: Integer; const FromDir, ToDir: String): Boolean;
var
  Index: Integer;
begin
  Result := True;
  for Index := 0 to Count - 1 do
    if not MoveEntry(FromDir + '\' + Names.Strings[Index], ToDir + '\' + Names.Strings[Index]) then
      Result := False;
end;

{ The swap: the old program files aside, the staged ones in, the backup gone.
  A failure undoes exactly what had moved — the new files that made it in go
  back to staging first, freeing their names, then the old ones come back — so
  the previous version runs as before. A backup that could not be put back is
  kept, never deleted, and so is one a previous run left. }
function SwapIn(const Directory: String): Boolean;
var
  Staging, Backup: String;
  OldNames, NewNames: TStringList;
  OldMoved, NewMoved: Integer;
  Restored: Boolean;
begin
  Staging := Directory + '\.staging-update';
  Backup := Directory + '\.backup-update';

  RemoveStaleBackups(Directory);
  RemoveDir(Backup);
  if DirExists(Backup) then
  begin
    Log('a previous update left its backup in ' + Backup + '; nothing was changed');
    Result := False;
    Exit;
  end;
  ForceDirectories(Backup);

  NewNames := ListEntries(Staging, False);
  OldNames := AsideEntries(Directory, NewNames);
  try
    Restored := True;
    NewMoved := 0;
    Result := MoveNames(OldNames, Directory, Backup, OldMoved);
    if Result then
    begin
      Result := MoveNames(NewNames, Staging, Directory, NewMoved);
      if not Result then
        Restored := MoveBack(NewNames, NewMoved, Directory, Staging);
    end;
    if not Result then
      Restored := MoveBack(OldNames, OldMoved, Backup, Directory) and Restored;

    if Result then
      SaveNames(NewNames, PayloadRecord(Directory));

    { A backup the swap no longer needs, which would otherwise stop the next
      update, is renamed out of the way if it will not go now, and removed by
      the next run. }
    if Result or Restored then
    begin
      if not RemoveTree(Backup) then
        if not RenameFile(Backup, Directory + '\.stale-update-' + GetDateTimeString('yyyymmddhhnnss', #0, #0)) then
          Log('the backup could not be removed or set aside: ' + Backup);
    end
    else
      Log('the previous program files are kept in ' + Backup);
    RemoveTree(Staging);
  finally
    OldNames.Free;
    NewNames.Free;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Directory: String;
begin
  Directory := RemoveBackslashUnlessRoot(ExpandConstant('{app}'));

  { A staging folder a crashed run left behind would mix old files into new
    ones. }
  if CurStep = ssInstall then
    RemoveTree(Directory + '\.staging-update');

  if CurStep = ssPostInstall then
  begin
    if not SwapIn(Directory) then
    begin
      Log('the staged files could not be moved into place; the previous installation was kept');
      if not WizardSilent() then
        MsgBox(CustomMessage('SwapFailed'), mbError, MB_OK);
      Exit;
    end;
    Log('the staged files were moved into place');

    if RemoveElsewhere then
      RemoveOtherCopy(RecordedLocation);
  end;
end;

{ Uninstalling: the entries the last swap put in place, which the uninstall
  log names only by their staging paths. }
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    RemoveRecordedEntries(RemoveBackslashUnlessRoot(ExpandConstant('{app}')));
end;
