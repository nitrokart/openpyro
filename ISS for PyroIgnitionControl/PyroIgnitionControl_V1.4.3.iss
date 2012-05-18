; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "PyroIgnitionControl_V.1.4.3"
#define MyAppVersion "1.4.3"
#define MyAppPublisher "www.OpenPyro.com"
#define MyAppURL "http://blamaster.bplaced.net/Joomla/"
#define MyAppExeName "PyroIgnitionControl.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
;AppId={{3BC9A521-5683-4F35-99D4-5C4EBB8E3B9D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename=PyroIgnitionControl_V1.4.3
Compression=lzma
SolidCompression=true
RestartIfNeededByRun=false
PrivilegesRequired=none
AlwaysShowDirOnReadyPage=true
AlwaysShowGroupOnReadyPage=true
LanguageDetectionMethod=locale
ShowUndisplayableLanguages=true
UsePreviousTasks=false

[Languages]
Name: english; MessagesFile: compiler:Default.isl; LicenseFile: .\txt\license_en.txt; InfoBeforeFile: .\txt\readme_en.txt
Name: german; MessagesFile: compiler:Languages\German.isl; LicenseFile: .\txt\license_de.txt; InfoBeforeFile: .\txt\readme_de.txt
Name: russian; MessagesFile: compiler:Languages\Russian.isl; LicenseFile: .\txt\license_ru.txt; InfoBeforeFile: .\txt\readme_ru.txt

[Tasks]
Name: desktopicon; Description: {cm:CreateDesktopIcon}; GroupDescription: {cm:AdditionalIcons}; Flags: checkablealone

[Files]
Source: .\PyroIgnitionControl_V1.4.3\PyroIgnitionControl.exe; DestDir: {app}; Flags: ignoreversion
Source: .\PyroIgnitionControl_V1.4.3\*; DestDir: {app}; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: {group}\{#MyAppName}; Filename: {app}\{#MyAppExeName}
Name: {group}\{cm:ProgramOnTheWeb,{#MyAppName}}; Filename: {#MyAppURL}
Name: {group}\{cm:UninstallProgram,{#MyAppName}}; Filename: {uninstallexe}
Name: {commondesktop}\{#MyAppName}; Filename: {app}\{#MyAppExeName}; Tasks: desktopicon

[Run]
Filename: {app}\{#MyAppExeName}; Flags: nowait postinstall skipifsilent

[INI]
Filename: {app}\einstellungen.ini; Section: Allgemein; Key: Language; String: en; Languages: english
Filename: {app}\einstellungen.ini; Section: Allgemein; Key: Language; String: de; Languages: german
Filename: {app}\einstellungen.ini; Section: Allgemein; Key: Language; String: ru; Languages: russian

Filename: {app}\einstellungen.ini; Section: Allgemein; Key: GlobalDelay; String: 00.000
Filename: {app}\einstellungen.ini; Section: Listenoptionen; Key: Option1; String: 1
Filename: {app}\einstellungen.ini; Section: ComPort; Key: Port; String: 1
Filename: {app}\einstellungen.ini; Section: ComPort; Key: Open; String: 1
Filename: {app}\einstellungen.ini; Section: Plugin; Key: Aktiv; String: PyroTronic.dll
Filename: {app}\einstellungen.ini; Section: Spectrum; Key: C_Spectrum; String: 65280
Filename: {app}\einstellungen.ini; Section: Spectrum; Key: C_Timeline; String: 16777215
Filename: {app}\einstellungen.ini; Section: Spectrum; Key: C_Duration; String: 255
Filename: {app}\einstellungen.ini; Section: Spectrum; Key: C_SelLine; String: 65535
Filename: {app}\einstellungen.ini; Section: Spectrum; Key: C_TimeMarks; String: 65535
Filename: {app}\einstellungen.ini; Section: Spectrum; Key: C_CueLine; String: 255
Filename: {app}\einstellungen.ini; Section: Spectrum; Key: C_Darktime; String: 8388736
Filename: {app}\einstellungen.ini; Section: Spectrum; Key: ShowCueline; String: 1
Filename: {app}\einstellungen.ini; Section: Spectrum; Key: ShowDarktime; String: 1
Filename: {app}\einstellungen.ini; Section: Spectrum; Key: CueLineHeight; String: 100
Filename: {app}\einstellungen.ini; Section: Handfire; Key: ListCheck; String: 1
Filename: {app}\einstellungen.ini; Section: Handfire; Key: StartMusic; String: 0
Filename: {app}\einstellungen.ini; Section: Handfire; Key: ShowIgnition; String: 0
Filename: {app}\einstellungen.ini; Section: Handfire; Key: UseCounter; String: 0
Filename: {app}\einstellungen.ini; Section: Window; Key: Maximize; String: 0
Filename: {app}\einstellungen.ini; Section: Window; Key: Width; String: 1147
Filename: {app}\einstellungen.ini; Section: Window; Key: Height; String: 645
Filename: {app}\einstellungen.ini; Section: Window; Key: Top; String: 0
Filename: {app}\einstellungen.ini; Section: Window; Key: Left; String: 0
Filename: {app}\einstellungen.ini; Section: ZoomSpec; Key: TimeMarks; String: 7
