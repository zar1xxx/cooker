@echo off
cd /d "%~dp0.."
dart format lib test tool > docs\reports\last_format.txt 2>&1
type docs\reports\last_format.txt
pause
