Unicode true
ManifestDPIAware true

!ifndef VERSION
  !define VERSION "2.3.7"
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
!define MUI_FINISHPAGE_RUN "$INSTDIR\start.bat"
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
  File /r "stage/*"
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateDirectory "$SMPROGRAMS\Evolution API"
  CreateShortCut "$SMPROGRAMS\Evolution API\Evolution API.lnk" "$INSTDIR\start.bat" "" "$INSTDIR\Uninstall.exe" 0 SW_SHOWMINIMIZED
  WriteINIStr "$SMPROGRAMS\Evolution API\Evolution API Manager.url" "InternetShortcut" "URL" "http://127.0.0.1:8080/manager"
  CreateShortCut "$DESKTOP\Evolution API.lnk" "$INSTDIR\start.bat" "" "$INSTDIR\Uninstall.exe" 0 SW_SHOWMINIMIZED

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
  Delete "$DESKTOP\Evolution API.lnk"
  Delete "$SMPROGRAMS\Evolution API\Evolution API.lnk"
  Delete "$SMPROGRAMS\Evolution API\Evolution API Manager.url"
  RMDir "$SMPROGRAMS\Evolution API"

  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EvolutionAPI"
  DeleteRegKey HKCU "Software\EvolutionAPI"

  MessageBox MB_YESNO|MB_DEFBUTTON2 "Deseja remover tambem os dados do Evolution API em $APPDATA\evolution-api?$\r$\n$\r$\nSe escolher Nao, seus dados (banco, midias e API key) serao mantidos." IDNO +2
  RMDir /r "$APPDATA\evolution-api"

  RMDir /r "$INSTDIR"
SectionEnd
