@echo off
chcp 65001 >nul
cd /d "%~dp0.."
set OUT=docs\reports\last_gpu_diag.txt
(
echo ===== nvidia-smi
nvidia-smi
echo ===== gpu memory and clocks
nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free,utilization.gpu,temperature.gpu,clocks.sm,clocks.max.sm,power.draw,pstate,clocks_throttle_reasons.active --format=csv
echo ===== processes using gpu
nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv
echo ===== lms ps
lms ps
echo ===== tiny request now
curl -s -m 60 -o nul -w "HTTP %%{http_code} TIME %%{time_total}s\n" http://127.0.0.1:1235/v1/chat/completions -H "Content-Type: application/json" -d "{\"model\":\"google/gemma-4-12b-qat\",\"messages\":[{\"role\":\"user\",\"content\":\"Say OK\"}],\"max_tokens\":40}"
echo ===== nvidia-smi after
nvidia-smi --query-gpu=memory.used,utilization.gpu,temperature.gpu,clocks.sm,pstate --format=csv
) > %OUT% 2>&1
echo done >> %OUT%
