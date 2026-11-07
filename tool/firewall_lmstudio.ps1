# Run as Administrator. Opens TCP 1234 and 1235 for LM Studio on Private networks only.
$name = 'LM Studio (Chto prigotovit)'
if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) {
    Set-NetFirewallRule -DisplayName $name -LocalPort 1234,1235 | Out-Null
    Write-Host 'Rule updated for ports 1234 and 1235.'
    exit 0
}
New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol TCP -LocalPort 1234,1235 -Action Allow -Profile Private | Out-Null
Write-Host 'Rule added for ports 1234 and 1235. Make sure your Wi-Fi network profile is Private:'
Get-NetConnectionProfile | Format-Table Name, InterfaceAlias, NetworkCategory
