# Run as Administrator. Opens TCP 1234 for LM Studio on Private networks only.
$name = 'LM Studio (Chto prigotovit)'
if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) { Write-Host 'Rule already exists.'; exit 0 }
New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol TCP -LocalPort 1234 -Action Allow -Profile Private | Out-Null
Write-Host 'Rule added. Make sure your Wi-Fi network profile is Private:'
Get-NetConnectionProfile | Format-Table Name, InterfaceAlias, NetworkCategory
