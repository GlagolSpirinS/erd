; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "erd"
#define MyAppVersion "1.5"
#define MyAppPublisher "erd"
#define MyAppExeName "erd.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{FC8F1590-DB40-4419-A3DB-E75D3D21A100}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\erd
UninstallDisplayIcon={app}\{#MyAppExeName}
; "ArchitecturesAllowed=x64compatible" specifies that Setup cannot run
; on anything but x64 and Windows 11 on Arm.
ArchitecturesAllowed=x64compatible
; "ArchitecturesInstallIn64BitMode=x64compatible" requests that the
; install be done in "64-bit mode" on x64 or Windows 11 on Arm,
; meaning it should use the native 64-bit Program Files directory and
; the 64-bit view of the registry.
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
; Uncomment the following line to run in non administrative install mode (install for current user only).
;PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=C:\Users\root\Documents\GitHub\erd\installer
OutputBaseFilename=erdsetup
SetupIconFile=C:\Users\root\Documents\GitHub\erd\installer\icon.ico
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\Users\root\Documents\GitHub\erd\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\root\Documents\GitHub\erd\build\windows\x64\runner\Release\cloud_firestore_plugin.lib"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\root\Documents\GitHub\erd\build\windows\x64\runner\Release\erd.exp"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\root\Documents\GitHub\erd\build\windows\x64\runner\Release\erd.lib"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\root\Documents\GitHub\erd\build\windows\x64\runner\Release\firebase_core_plugin.lib"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\root\Documents\GitHub\erd\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\root\Documents\GitHub\erd\build\windows\x64\runner\Release\sqlite3.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\root\Documents\GitHub\erd\build\windows\x64\runner\Release\sqlite3_flutter_libs_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\root\Documents\GitHub\erd\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

