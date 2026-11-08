@echo off
chcp 65001 >nul
cd /d "%~dp0.."
set OUT=docs\reports\last_models_list.txt
(
echo ===== lms ls
lms ls
echo ===== lms ls --json
lms ls --json
echo ===== lms ps
lms ps
echo ===== gpu
nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free --format=csv
echo ===== ram
powershell -NoProfile -Command "Get-CimInstance Win32_ComputerSystem | Select-Object TotalPhysicalMemory | Format-List; Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores | Format-List"
echo ===== model files
powershell -NoProfile -Command "Get-ChildItem -Recurse -File \"$env:USERPROFILE\.lmstudio\models\" -Include *.gguf,*.safetensors | Select-Object @{n='GB';e={[math]::Round($_.Length/1GB,2)}},FullName | Format-Table -AutoSize | Out-String -Width 300"
echo done
) > %OUT% 2>&1
