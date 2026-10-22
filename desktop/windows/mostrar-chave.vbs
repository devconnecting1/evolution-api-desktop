Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

dataDir = shell.ExpandEnvironmentStrings("%APPDATA%") & "\evolution-api"
configFile = dataDir & "\config.json"

If Not fso.FileExists(configFile) Then
  MsgBox "Inicie o Evolution API primeiro.", 48, "Evolution API"
  WScript.Quit
End If

Set f = fso.OpenTextFile(configFile, 1)
content = f.ReadAll
f.Close

needle = Chr(34) & "apiKey" & Chr(34) & ": " & Chr(34)
pos = InStr(content, needle)

If pos = 0 Then
  MsgBox "API key nao encontrada.", 48, "Evolution API"
  WScript.Quit
End If

keyStart = pos + Len(needle)
keyEnd = InStr(keyStart, content, Chr(34))

If keyEnd = 0 Then
  MsgBox "API key invalida.", 48, "Evolution API"
  WScript.Quit
End If

key = Mid(content, keyStart, keyEnd - keyStart)
shell.Run "cmd.exe /c echo " & key & "| clip", 0, True
MsgBox "API key copiada para a area de transferencia:" & vbCrLf & vbCrLf & key, 64, "Evolution API"
