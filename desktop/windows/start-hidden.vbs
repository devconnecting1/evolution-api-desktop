Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

dir = fso.GetParentFolderName(WScript.ScriptFullName)
dataDir = shell.ExpandEnvironmentStrings("%APPDATA%") & "\evolution-api"
pidFile = dataDir & "\launcher.pid"

If fso.FileExists(pidFile) Then
  Set f = fso.OpenTextFile(pidFile, 1)
  pid = Trim(f.ReadAll)
  f.Close

  If Len(pid) > 0 Then
    running = False
    On Error Resume Next
    Set wmi = GetObject("winmgmts:\\.\root\cimv2")
    Set procs = wmi.ExecQuery("SELECT ProcessId FROM Win32_Process WHERE ProcessId = " & pid)
    If Err.Number = 0 Then
      If procs.Count > 0 Then running = True
    End If
    Err.Clear
    On Error GoTo 0

    If running Then
      shell.Run "explorer.exe http://127.0.0.1:8080/manager", 0, False
      WScript.Quit
    End If
  End If
End If

If Not fso.FolderExists(dataDir) Then fso.CreateFolder(dataDir)

logFile = dataDir & "\launcher.log"
q = Chr(34)
cmd = "cmd.exe /c " & q & q & dir & "\runtime\node.exe" & q & " " & q & dir & "\desktop\launcher.js" & q & " >> " & q & logFile & q & " 2>&1" & q
shell.Run cmd, 0, False
