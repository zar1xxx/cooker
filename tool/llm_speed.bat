@echo off
chcp 65001 >nul
cd /d "%~dp0.."
set OUT=docs\reports\last_llm_speed.txt
echo running > docs\reports\last_llm_speed.status
(
echo ===== tiny request, max_tokens 40
curl -s -m 120 -w "\nHTTP %%{http_code} TIME %%{time_total}s\n" http://127.0.0.1:1235/v1/chat/completions -H "Content-Type: application/json" -d "{\"model\":\"google/gemma-4-12b-qat\",\"messages\":[{\"role\":\"user\",\"content\":\"Say OK\"}],\"max_tokens\":40}"
echo.
echo ===== json_schema request, max_tokens 300
curl -s -m 180 -w "\nHTTP %%{http_code} TIME %%{time_total}s\n" http://127.0.0.1:1235/v1/chat/completions -H "Content-Type: application/json" -d "{\"model\":\"google/gemma-4-12b-qat\",\"messages\":[{\"role\":\"user\",\"content\":\"Назови 2 блюда из картофеля и лука. Ответ JSON.\"}],\"max_tokens\":300,\"response_format\":{\"type\":\"json_schema\",\"json_schema\":{\"name\":\"d\",\"strict\":true,\"schema\":{\"type\":\"object\",\"properties\":{\"dishes\":{\"type\":\"array\",\"items\":{\"type\":\"string\"}}},\"required\":[\"dishes\"]}}}}"
echo.
echo ===== lms ps after
lms ps
) > %OUT% 2>&1
echo done > docs\reports\last_llm_speed.status
