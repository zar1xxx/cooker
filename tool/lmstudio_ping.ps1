# Checks that LM Studio is reachable and returns structured JSON.
# Usage: powershell -ExecutionPolicy Bypass -File tool\lmstudio_ping.ps1 [-PcHost 192.168.1.10] [-Model <id>]
param([string]$PcHost = 'localhost', [int]$Port = 1234, [string]$Model = '')
$base = "http://${PcHost}:${Port}/v1"
Write-Host "GET $base/models"
try {
  $models = Invoke-RestMethod -Uri "$base/models" -TimeoutSec 5
} catch {
  Write-Host "FAIL: LM Studio not reachable at $base. Is the server started? 'Serve on Local Network' on? Firewall rule (tool\firewall_lmstudio.ps1)?" -ForegroundColor Red
  exit 1
}
$models.data | ForEach-Object { Write-Host "  model: $($_.id)" }
if (-not $Model) { $Model = ($models.data | Select-Object -First 1).id }
Write-Host "Using model: $Model"

$schema = @{ type = 'object'; properties = @{ dish = @{ type = 'string' }; minutes = @{ type = 'integer' } }; required = @('dish','minutes') }
$body = @{
  model = $Model
  messages = @(
    @{ role = 'system'; content = 'Reply only with JSON.' },
    @{ role = 'user'; content = 'Name one simple potato dish and its cooking time in minutes. Answer in Russian.' }
  )
  temperature = 0.3
  stream = $false
  response_format = @{ type = 'json_schema'; json_schema = @{ name = 'ping'; strict = $true; schema = $schema } }
} | ConvertTo-Json -Depth 10
$sw = [Diagnostics.Stopwatch]::StartNew()
$resp = Invoke-RestMethod -Uri "$base/chat/completions" -Method Post -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 180
$sw.Stop()
Write-Host "Response in $([int]$sw.Elapsed.TotalSeconds) s:"
Write-Host $resp.choices[0].message.content
Write-Host "usage: $($resp.usage | ConvertTo-Json -Compress)"
try { $resp.choices[0].message.content | ConvertFrom-Json | Out-Null; Write-Host 'OK: valid JSON' -ForegroundColor Green }
catch { Write-Host 'FAIL: response is not valid JSON - try another model (7B+)' -ForegroundColor Red; exit 1 }
