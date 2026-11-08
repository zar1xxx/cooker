@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0.."
set R=docs\reports\bench
if not exist %R% mkdir %R%
echo running > %R%\status.txt
for %%M in (ornith-1.5-9b google/gemma-4-12b-qat qwen3.6-35b-a3b-1m ornith-1.5-35b-a3b) do (
  set N=%%M
  set N=!N:/=_!
  echo ===== %%M > %R%\!N!.txt
  lms load %%M -c 4096 --parallel 1 --estimate-only >> %R%\!N!.txt 2>&1
  lms unload --all >> %R%\!N!.txt 2>&1
  lms load %%M -c 4096 --parallel 1 -y >> %R%\!N!.txt 2>&1
  lms ps >> %R%\!N!.txt 2>&1
  nvidia-smi --query-gpu=memory.used,memory.free --format=csv >> %R%\!N!.txt 2>&1
  set LMSTUDIO_MODEL=%%M
  call dart run tool/ai_smoke.dart --port 1235 >> %R%\!N!.txt 2>&1
  echo exit !errorlevel! >> %R%\!N!.txt
  nvidia-smi --query-gpu=memory.used,memory.free --format=csv >> %R%\!N!.txt 2>&1
  echo %%M done >> %R%\status.txt
)
echo all done >> %R%\status.txt
