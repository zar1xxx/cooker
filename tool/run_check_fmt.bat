@echo off
chcp 65001 >nul
rem Format, then the full check. Result: docs\reports\last_check.txt
cd /d "%~dp0.."
call dart format lib test tool > docs\reports\last_format.txt 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check.ps1"
exit
