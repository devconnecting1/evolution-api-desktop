Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

dataDir = shell.ExpandEnvironmentStrings("%APPDATA%") & "\evolution-api"
pidFile = dataDir & "\launcher.pid"

If Not fso.FolderExists(dataDir) Or Not fso.FileExists(pidFile) Then
  MsgBox "Evolution API nao esta em execucao.", 48, "Evolution API"
  WScript.Quit
End If

Set f = fso.OpenTextFile(pidFile, 1)
pid = Trim(f.ReadAll)
f.Close

If Len(pid) = 0 Then
  MsgBox "Evolution API nao esta em execucao.", 48, "Evolution API"
  WScript.Quit
End If

stopFile = dataDir & "\stop.request"
Set f = fso.CreateTextFile(stopFile, True)
f.Close

WScript.Sleep 5000

If fso.FileExists(stopFile) Then
  shell.Run "taskkill /PID " & pid & " /T /F", 0, True
  If fso.FileExists(stopFile) Then fso.DeleteFile stopFile, True
  If fso.FileExists(pidFile) Then fso.DeleteFile pidFile, True
  MsgBox "Evolution API foi encerrado a forca.", 48, "Evolution API"
Else
  MsgBox "Evolution API parado.", 64, "Evolution API"
End If
