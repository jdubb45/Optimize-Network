<#
.SYNOPSIS
    Windows Network & Stream Optimization Utility
.DESCRIPTION
    Automates DNS optimization, TCP stack tuning, NIC power-saving throttle fixes,
    and DNS/network cache flushing to eliminate video buffering and packet latency.
.NOTES
    Author: Julian Williams
    Repository: https://github.com/yourusername/network-optimizer
#>

[CmdletBinding()]
param(
    [ValidateSet("Google", "Cloudflare", "Quad9")]
    [string]$DnsProvider = "Google"
)

# ---------------------------------------------------------
# Self-Elevation to Administrator
# ---------------------------------------------------------
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -DnsProvider {1}" -f $PSCommandPath,$DnsProvider)
    exit
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Windows Network & Stream Optimizer     " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# ---------------------------------------------------------
# 1. Identify Active Network Interface
# ---------------------------------------------------------
$activeAdapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1

if (-not $activeAdapter) {
    Write-Error "[-] No active network connection found. Exiting."
    exit 1
}

Write-Host "[+] Active Adapter Found: $($activeAdapter.Name) ($($activeAdapter.InterfaceDescription))" -ForegroundColor Green

# ---------------------------------------------------------
# 2. Configure High-Performance Anycast DNS
# ---------------------------------------------------------
$dnsServers = switch ($DnsProvider) {
    "Cloudflare" { @("1.1.1.1", "1.0.0.1") }
    "Quad9"      { @("9.9.9.9", "149.112.112.112") }
    Default      { @("8.8.8.8", "8.8.4.4") } # Google
}

Write-Host "[*] Applying $DnsProvider DNS ($($dnsServers -join ', '))..." -ForegroundColor Cyan
try {
    Set-DnsClientServerAddress -InterfaceAlias $activeAdapter.Name -ServerAddresses$dnsServers -ErrorAction Stop
    Write-Host "[+] DNS successfully updated." -ForegroundColor Green
} catch {
    Write-Warning "[-] Failed to set DNS: $_"
}

# ---------------------------------------------------------
# 3. Disable NIC Energy Throttling & Packet Offload Bugs
# ---------------------------------------------------------
Write-Host "[*] Tuning network adapter properties for low latency..." -ForegroundColor Cyan

$throttleProperties = @(
    "Energy Efficient Ethernet",
    "Green Ethernet",
    "Energy-Efficient Ethernet",
    "Advanced EEE",
    "Gigabit Lite",
    "Power Saving Mode"
)

foreach ($prop in$throttleProperties) {
    Set-NetAdapterAdvancedProperty -Name $activeAdapter.Name -DisplayName$prop -DisplayValue "Disabled" -ErrorAction SilentlyContinue
}
Write-Host "[+] NIC power-saving throttling disabled." -ForegroundColor Green

# ---------------------------------------------------------
# 4. Optimize Windows TCP Auto-Tuning Stack
# ---------------------------------------------------------
Write-Host "[*] Setting TCP Auto-Tuning to Normal (prevents stream throughput capping)..." -ForegroundColor Cyan
netsh int tcp set global autotuninglevel=normal | Out-Null
netsh int tcp set global congestionprovider=ctcp 2>$null | Out-Null
Write-Host "[+] TCP stack tuned." -ForegroundColor Green

# ---------------------------------------------------------
# 5. Flush Caches and Reset State
# ---------------------------------------------------------
Write-Host "[*] Flushing DNS and ARP tables..." -ForegroundColor Cyan
Clear-DnsClientCache
arp -d * 2>$null | Out-Null

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] Network optimization complete!" -ForegroundColor Green
Write-Host "Current DNS on $($activeAdapter.Name):" -ForegroundColor Gray
(Get-DnsClientServerAddress -InterfaceAlias $activeAdapter.Name -AddressFamily IPv4).ServerAddresses | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
Write-Host "==========================================" -ForegroundColor Cyan

# Safe exit pause (won't crash if invoked via non-interactive console or pipeline)
try {
    Write-Host "`nPress any key to exit..."
    $null =$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} catch {
    Start-Sleep -Seconds 3
}
