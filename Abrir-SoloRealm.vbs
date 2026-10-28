Option Explicit

Dim shell, files, root, powershell, manager, command, desktop
Set shell = CreateObject("WScript.Shell")
Set files = CreateObject("Scripting.FileSystemObject")
root = files.GetParentFolderName(WScript.ScriptFullName)
desktop = root & "\launcher\SoloRealm.Desktop\bin\Release\net9.0-windows\SoloRealm.exe"
If Not files.FileExists(desktop) Then
    desktop = root & "\SoloRealm.exe"
End If
If files.FileExists(desktop) Then
    shell.Run """" & desktop & """", 1, False
    WScript.Quit 0
End If
powershell = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
manager = root & "\launcher\Start-Manager.ps1"
If Not files.FileExists(manager) Then
    MsgBox "Não foi encontrado o inicializador do SoloRealm:" & vbCrLf & manager, vbCritical, "SoloRealm Control Center"
    WScript.Quit 1
End If
command = """" & powershell & """ -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File """ & manager & """"
shell.Run command, 0, True
