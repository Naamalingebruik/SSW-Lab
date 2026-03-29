# Zoek adapter op naam i.p.v. hardcoded index (werkt machine-onafhankelijk)
$vmAdapter = Get-NetAdapter | Where-Object { $_.Name -like 'vEthernet*' -and $_.Status -eq 'Up' } |
    Where-Object { (Get-NetAdapterBinding -Name $_.Name -ComponentID 'vms_pp' -ErrorAction SilentlyContinue) } |
    Select-Object -First 1
if (-not $vmAdapter) {
    # Fallback: eerste vEthernet adapter die Up is
    $vmAdapter = Get-NetAdapter | Where-Object { $_.Name -like 'vEthernet*' -and $_.Status -eq 'Up' } | Select-Object -First 1
}
if (-not $vmAdapter) { Write-Error 'Geen actieve vEthernet adapter gevonden. Is de VM verbonden met SSW-Internal?'; exit 1 }
$idx = $vmAdapter.InterfaceIndex
Write-Host "Adapter: $($vmAdapter.Name) (index $idx)"

Get-NetIPAddress -InterfaceIndex $idx -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Get-NetRoute -InterfaceIndex $idx -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
New-NetIPAddress -InterfaceIndex $idx -IPAddress '10.50.10.31' -PrefixLength 24 -DefaultGateway '10.50.10.1' -ErrorAction Stop | Out-Null
Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses '10.50.10.10' -ErrorAction Stop
Start-Sleep -Seconds 3
Write-Host "IP: $((Get-NetIPAddress -InterfaceIndex $idx -AddressFamily IPv4).IPAddress)"
Write-Host "GW: $((Get-NetRoute -InterfaceIndex $idx -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue).NextHop)"
Write-Host "DNS: $((Get-DnsClientServerAddress -InterfaceIndex $idx -AddressFamily IPv4).ServerAddresses)"
Test-NetConnection -ComputerName 8.8.8.8 -InformationLevel Quiet



