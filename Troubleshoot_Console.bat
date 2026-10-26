@echo off
REM developed by hmnd-team
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Sta -File "%~dp0DownloadOrganizer.ps1"
echo.
echo O programa foi encerrado. Se houve um erro, ele aparecera acima.
pause
