@echo off
setlocal
for %%I in ("%~f0") do set "SCRIPT_DIR=%%~dpI"
cd /d "%SCRIPT_DIR%"
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%launcher_zh.ps1"
