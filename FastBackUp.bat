@echo off
REM FastBackUp
REM Created by Bratislav Cvetkovic
REM Copyright (c) 2026 Bratislav Cvetkovic
REM Licensed under the MIT License.
REM See the LICENSE file for details.


setlocal
chcp 65001 >nul
title FastBackUp - Backup and Restore
color 0F

set "PS1=%~dp0FastBackUp.ps1"

if not exist "%PS1%" (
    echo.
    echo ERROR: FastBackUp.ps1 was not found
    echo.
    echo Both files must be in the same folder:
    echo FastBackUp.bat
    echo FastBackUp.ps1
    echo.
    pause
    exit /b 1
)

:MENU
cls
echo ==================================================
echo             FastBackUp
echo       BACKUP AND RESTORE
echo ==================================================
echo.
echo   1 - Create a backup
echo   2 - Restore from a backup
echo   3 - Exit
echo.
choice /C 123 /N /M "Select an option (1-3): "

if errorlevel 3 goto KRAJ
if errorlevel 2 goto VRACANJE
if errorlevel 1 goto REZERVA

:REZERVA
cls
echo Starting FastBackUp...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%PS1%" -Mode Backup
echo.
pause
goto MENU

:VRACANJE
cls
echo Starting data restoration...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%PS1%" -Mode Restore
echo.
pause
goto MENU

:KRAJ
endlocal
exit /b
