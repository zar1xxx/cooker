@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0.."
echo running > docs\reports\last_ai_smoke_x3.status
call tool\diag_lmstudio.bat
for %%i in (1 2 3) do (
  call dart run tool/ai_smoke.dart --port 1235 > docs\reports\last_ai_smoke_run%%i.txt 2>&1
  echo exit !errorlevel! >> docs\reports\last_ai_smoke_run%%i.txt
  echo run %%i done >> docs\reports\last_ai_smoke_x3.status
)
echo done >> docs\reports\last_ai_smoke_x3.status
