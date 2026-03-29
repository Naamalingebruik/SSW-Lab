param($mac, $apIP)
$r = @()
if (-not (Get-WindowsFeature DHCP).Installed) {
    Install-WindowsFeature DHCP -IncludeManagementTools | Out-Null
    try { Add-DhcpServerInDC -DnsName $env:COMPUTERNAME -ErrorAction SilentlyContinue } catch {}
    $r += "DHCP geinstalleerd."
} else { $r += "DHCP al aanwezig." }
if (-not (Get-DhcpServerv4Scope -ScopeId '10.50.10.0' -ErrorAction SilentlyContinue)) {
    Add-DhcpServerv4Scope -Name 'SSW-Lab' -StartRange '10.50.10.100' -EndRange '10.50.10.200' -SubnetMask '255.255.255.0' -State Active | Out-Null
    Set-DhcpServerv4OptionValue -ScopeId '10.50.10.0' -Router '10.50.10.1' -DnsServer '10.50.10.10' -ErrorAction SilentlyContinue | Out-Null
    $r += "Scope aangemaakt (10.50.10.100-200)."
} else { $r += "Scope bestond al." }
$ex = Get-DhcpServerv4Reservation -ScopeId '10.50.10.0' -ErrorAction SilentlyContinue | Where-Object { $_.ClientId -ieq $mac }
if ($ex) { Remove-DhcpServerv4Reservation -ScopeId '10.50.10.0' -IPAddress $ex.IPAddress | Out-Null }
Add-DhcpServerv4Reservation -ScopeId '10.50.10.0' -IPAddress $apIP -ClientId $mac -Description 'LAB-W11-AUTOPILOT vaste reservering' | Out-Null
$r += "Reservering $apIP voor MAC $mac aangemaakt."
$r
Get-DhcpServerv4Reservation -ScopeId '10.50.10.0' | Select-Object IPAddress, ClientId, Description

