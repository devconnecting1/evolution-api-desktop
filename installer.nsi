Unicode true
ManifestDPIAware true

!ifndef VERSION
  !define VERSION "2.3.8"
!endif

!ifndef SRCDIR
  !define SRCDIR "stage"
!endif

Name "Evolution API"
OutFile "EvolutionAPI-Setup-${VERSION}.exe"
InstallDir "$LOCALAPPDATA\Programs\EvolutionAPI"
InstallDirRegKey HKCU "Software\EvolutionAPI" "InstallDir"
RequestExecutionLevel user
SetCompressor zlib
ShowInstDetails nevershow
ShowUninstDetails nevershow

VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "Evolution API"
VIAddVersionKey "CompanyName" "Evolution API"
VIAddVersionKey "FileDescription" "Evolution API Desktop Installer"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "Evolution API"

!include "MUI2.nsh"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\start-hidden.vbs"
!define MUI_FINISHPAGE_RUN_TEXT "Iniciar o Evolution API agora"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\LEIA-ME.txt"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Abrir instrucoes (LEIA-ME)"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "PortugueseBR"
!insertmacro MUI_LANGUAGE "English"

Section "Evolution API" SecMain
  SectionIn RO
  SetOutPath "$INSTDIR"
  File /r "${SRCDIR}\*.*"
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateDirectory "$SMPROGRAMS\Evolution API"
  CreateShortCut "$SMPROGRAMS\Evolution API\Evolution API.lnk" "$SYSDIR\wscript.exe" '"$INSTDIR\start-hidden.vbs"' "$INSTDIR\Uninstall.exe" 0 SW_SHOWMINIMIZED "$INSTDIR"
  WriteINIStr "$SMPROGRAMS\Evolution API\Evolution API Manager.url" "InternetShortcut" "URL" "http://127.0.0.1:8080/manager"
  CreateShortCut "$SMPROGRAMS\Evolution API\Chave da API.lnk" "$SYSDIR\wscript.exe" '"$INSTDIR\mostrar-chave.vbs"' "$INSTDIR\Uninstall.exe" 0 SW_SHOWMINIMIZED "$INSTDIR"
  CreateShortCut "$SMPROGRAMS\Evolution API\Parar Evolution API.lnk" "$SYSDIR\wscript.exe" '"$INSTDIR\stop.vbs"' "$INSTDIR\Uninstall.exe" 0 SW_SHOWMINIMIZED "$INSTDIR"
  CreateShortCut "$SMPROGRAMS\Evolution API\Evolution API (console).lnk" "$INSTDIR\start.bat" "" "$INSTDIR\Uninstall.exe" 0 SW_SHOWMINIMIZED "$INSTDIR"
  CreateShortCut "$DESKTOP\Evolution API.lnk" "$SYSDIR\wscript.exe" '"$INSTDIR\start-hidden.vbs"' "$INSTDIR\Uninstall.exe" 0 SW_SHOWMINIMIZED "$INSTDIR"
  WriteINIStr "$DESKTOP\Evolution API Manager.url" "InternetShortcut" "URL" "http://127.0.0.1:8080/manager"

  WriteRegStr HKCU "Software\EvolutionAPI" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EvolutionAPI" "DisplayName" "Evolution API"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EvolutionAPI" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EvolutionAPI" "Publisher" "Evolution API"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EvolutionAPI" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EvolutionAPI" "DisplayIcon" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EvolutionAPI" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EvolutionAPI" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EvolutionAPI" "NoRepair" 1
SectionEnd

Section "Uninstall"
  CreateDirectory "$APPDATA\evolution-api"
  ClearErrors
  FileOpen $0 "$APPDATA\evolution-api\stop.request" w
  FileClose $0
  Sleep 4000
  IfFileExists "$APPDATA\evolution-api\launcher.pid" 0 no_pid
    FileOpen $0 "$APPDATA\evolution-api\launcher.pid" r
    FileRead $0 $1
    FileClose $0
    nsExec::Exec '"$SYSDIR\taskkill.exe" /PID $1 /T /F'
  no_pid:
  Delete "$APPDATA\evolution-api\stop.request"
  Delete "$APPDATA\evolution-api\launcher.pid"

  Delete "$DESKTOP\Evolution API.lnk"
  Delete "$DESKTOP\Evolution API Manager.url"
  Delete "$SMPROGRAMS\Evolution API\Evolution API.lnk"
  Delete "$SMPROGRAMS\Evolution API\Evolution API Manager.url"
  Delete "$SMPROGRAMS\Evolution API\Chave da API.lnk"
  Delete "$SMPROGRAMS\Evolution API\Parar Evolution API.lnk"
  Delete "$SMPROGRAMS\Evolution API\Evolution API (console).lnk"
  RMDir "$SMPROGRAMS\Evolution API"

  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EvolutionAPI"
  DeleteRegKey HKCU "Software\EvolutionAPI"

  MessageBox MB_YESNO|MB_DEFBUTTON2 "Deseja remover tambem os dados do Evolution API em $APPDATA\evolution-api?$\r$\n$\r$\nSe escolher Nao, seus dados (banco, midias e API key) serao mantidos." IDNO +2
  RMDir /r "$APPDATA\evolution-api"

  RMDir /r "$INSTDIR"
SectionEnd
