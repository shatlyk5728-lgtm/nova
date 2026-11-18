#define MyAppName "Nova VPN"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Nova"
#define BuildDir "..\\build\\windows\\x64\\runner\\Release"

[Setup]
AppId={{A6D41F29-8E5D-4F75-A0B8-62A3D1D9C9A1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\\Nova VPN
DefaultGroupName=Nova VPN
OutputDir=..\\dist
OutputBaseFilename=Nova-VPN-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\\nova.exe

[Files]
Source: "{#BuildDir}\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\\Nova VPN"; Filename: "{app}\\nova.exe"
Name: "{autodesktop}\\Nova VPN"; Filename: "{app}\\nova.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; GroupDescription: "Дополнительные параметры:"
