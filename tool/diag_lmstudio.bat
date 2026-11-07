@echo off
chcp 65001 >nul
set OUT=%~dp0..\docs\reports\last_lmstudio_diag.txt
set LMS=lms
where lms >nul 2>nul || set LMS="%USERPROFILE%\.lmstudio\bin\lms.exe"
(
echo ===== time
date /t & time /t
echo ===== lms server status
%LMS% server status
echo ===== lms ps
%LMS% ps
echo ===== listening ports 1234/1235
netstat -ano | findstr /r ":1234 :1235" | findstr LISTENING
echo ===== ipconfig
ipconfig
echo ===== curl localhost 1235
curl -s -m 3 http://127.0.0.1:1235/v1/models
echo.
echo ===== curl localhost 1234
curl -s -m 3 http://127.0.0.1:1234/v1/models
echo.
echo ===== curl LAN IPs 1235
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do for /f "tokens=*" %%b in ("%%a") do (
  echo --- %%b
  curl -s -m 3 http://%%b:1235/v1/models
  echo.
)
echo ===== network profile
powershell -NoProfile -Command "Get-NetConnectionProfile | Format-Table Name,InterfaceAlias,NetworkCategory -AutoSize | Out-String -Width 200"
echo ===== firewall rules for 1234/1235 and LM Studio
powershell -NoProfile -Command "Get-NetFirewallRule -Enabled True -Direction Inbound | Where-Object { $_.DisplayName -match 'LM Studio|lmstudio|llmster|1235|1234' } | Format-Table DisplayName,Action,Profile -AutoSize | Out-String -Width 200"
echo ===== done
) > "%OUT%" 2>&1
