; IR-16: the Windows installer executable.
;
; Inno Setup rather than an MSI: the product installs into the owner's own
; profile, registers nothing system-wide, and has no service to configure —
; which is the whole of what this script needs to express.
;
; The installer is produced unsigned. Code signing needs a certificate the
; project does not hold yet, recorded as deliberately deferred in
; Operations & Infrastructure Document §7.2.

#define AppName "Alexandria"
#define AppPublisher "Artur Rios"
#define AppExeName "alexandria_desktop.exe"
#define AppVersion GetEnv('ALEXANDRIA_VERSION')

[Setup]
AppId={{8F2A6C41-9B3E-4D77-A5C2-1E6D0B9F4A38}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppSupportURL=https://github.com/artur-rios/alexandria-desktop-front
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=alexandria-setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; NFR-07: the application is usable at 1024 x 640, so Windows 10 x64 and later.
MinVersion=10.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
; The whole release bundle, which already carries alexandria_ffi.dll beside the
; executable — that is what IR-04's "resolved relative to the installed
; application" resolves to.
Source: "..\..\build\windows\x64\runner\Release\*"; \
  DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

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

; Nothing is uninstalled separately: the core is a library inside the bundle,
; not a service (§7.3). The owner's catalog and settings live in their
; application-support directory and are deliberately left in place.
