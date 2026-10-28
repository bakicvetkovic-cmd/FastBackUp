@echo off
REM FastBackUp
REM Created by Bratislav Cvetković
REM Copyright (c) 2026 Bratislav Cvetković
REM Licensed under the MIT License. See LICENSE.txt for details.
setlocal
chcp 65001 >nul
title FastBackUp - Backup and Restore
color 0F


set "PS1=%~dp0FastBackUp_2.0.ps1"

if not exist "%PS1%" (
    echo.
    echo ERROR: FastBackUp.ps1 was not found.
    echo.
    echo Both files must be in the same folder:
    echo FastBackUp_2.0.bat
    echo FastBackUp_2.0.ps1
    echo.
    pause
    exit /b 1
)

:MENU
cls
echo ==================================================
echo                  FastBackUp
echo              BACKUP AND RESTORE
echo ==================================================
echo.
echo   1 - Repeat one of the last 20 operations
echo   2 - Create a new backup
echo   3 - Restore data from a backup
echo   4 - Exit
echo.
choice /C 1234 /N /M "Select an option (1-4): "

if errorlevel 4 goto EXIT
if errorlevel 3 goto RESTORE
if errorlevel 2 goto BACKUP
if errorlevel 1 goto HISTORY

:HISTORY
cls
echo Opening operation history...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%PS1%" -Mode History
echo.
pause
goto MENU

:BACKUP
cls
echo Starting FastBackUp...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%PS1%" -Mode Backup
echo.
pause
goto MENU

:RESTORE
cls
echo Starting data restore...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%PS1%" -Mode Restore
echo.
pause
goto MENU

:EXIT
endlocal
exit /b
