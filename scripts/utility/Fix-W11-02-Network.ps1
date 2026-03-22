$idx = 4
Get-NetIPAddress -InterfaceIndex $idx -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Get-NetRoute -InterfaceIndex $idx -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
New-NetIPAddress -InterfaceIndex $idx -IPAddress '10.50.10.31' -PrefixLength 24 -DefaultGateway '10.50.10.1' | Out-Null
Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses '10.50.10.10'
Start-Sleep -Seconds 3
Write-Host "IP: $((Get-NetIPAddress -InterfaceIndex $idx -AddressFamily IPv4).IPAddress)"
Write-Host "GW: $((Get-NetRoute -InterfaceIndex $idx -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue).NextHop)"
Write-Host "DNS: $((Get-DnsClientServerAddress -InterfaceIndex $idx -AddressFamily IPv4).ServerAddresses)"
Test-NetConnection -ComputerName 8.8.8.8 -InformationLevel Quiet
