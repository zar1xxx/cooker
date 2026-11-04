# Checks GigaChat key: gets an access token and sends one chat request.
# Usage: $env:GIGACHAT_AUTH_KEY = '<authorization key>'; powershell -ExecutionPolicy Bypass -File tool\gigachat_ping.ps1
# Requires "Russian Trusted Root CA" installed in Windows (Trusted Root store), otherwise TLS fails.
param([string]$Base = 'https://gigachat.devices.sberbank.ru', [string]$Model = 'GigaChat-2')
$key = $env:GIGACHAT_AUTH_KEY
if (-not $key) { Write-Host 'Set $env:GIGACHAT_AUTH_KEY first.' -ForegroundColor Red; exit 1 }
try {
  $tok = Invoke-RestMethod -Method Post -Uri 'https://ngw.devices.sberbank.ru:9443/api/v2/oauth' `
    -Headers @{ Authorization = "Basic $key"; RqUID = [guid]::NewGuid().ToString(); Accept = 'application/json' } `
    -ContentType 'application/x-www-form-urlencoded' -Body 'scope=GIGACHAT_API_PERS' -TimeoutSec 20
} catch {
  Write-Host "FAIL token: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host 'If this is a TLS/certificate error: install Russian Trusted Root CA (see assets\certs\README.md).'
  exit 1
}
$exp = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$tok.expires_at).LocalDateTime
Write-Host "Token OK, expires at $exp"
$body = @{ model = $Model; messages = @(@{ role = 'user'; content = 'Назови одно простое блюдо из картофеля. Ответь JSON: {"dish": "...", "minutes": N}' }); temperature = 0.3 } | ConvertTo-Json -Depth 5
$resp = Invoke-RestMethod -Method Post -Uri "$Base/api/v1/chat/completions" -Headers @{ Authorization = "Bearer $($tok.access_token)" } `
  -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 60
Write-Host $resp.choices[0].message.content
Write-Host "usage: $($resp.usage | ConvertTo-Json -Compress)"
