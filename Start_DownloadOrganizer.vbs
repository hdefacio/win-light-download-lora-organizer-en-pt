' developed by hmnd-team

' Inicia o organizador sem abrir janela preta do PowerShell.
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
scriptFile = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "DownloadOrganizer.ps1")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -Sta -File """ & scriptFile & """", 0, False
