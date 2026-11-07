@echo off
chcp 65001 >nul
cd /d "%~dp0.."
echo running > docs\reports\last_ai_smoke.status
call dart run tool/ai_smoke.dart --port 1235 > docs\reports\last_ai_smoke.txt 2>&1
echo exit %errorlevel% >> docs\reports\last_ai_smoke.txt
call tool\diag_lmstudio.bat
echo done > docs\reports\last_ai_smoke.status
