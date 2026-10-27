@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0TH20-GPU.ps1" -Action Apply
pause
