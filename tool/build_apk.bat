@echo off
cd /d "%~dp0.."
call flutter build apk --release --split-per-abi > docs\reports\last_build.txt 2>&1
type docs\reports\last_build.txt
pause
