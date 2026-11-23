$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Stop-DevScript {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host $Message -ForegroundColor Red
    exit 1
}

function Read-DotEnvValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $found = $null
    $lines = @(Get-Content -LiteralPath $Path)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = [string]$lines[$i]
        if ($i -eq 0) {
            $line = $line.TrimStart([char]0xFEFF)
        }
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) {
            continue
        }
        $separator = $trimmed.IndexOf('=')
        if ($separator -lt 1) {
            continue
        }
        $key = $trimmed.Substring(0, $separator).Trim()
        if ($key -ne $Name) {
            continue
        }
        $value = $trimmed.Substring($separator + 1).Trim()
        $quoted = ($value.Length -ge 2) -and (
            ($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))
        )
        if ($quoted) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        $found = $value
    }

    return $found
}

function Get-LanIPv4 {
    if (-not [string]::IsNullOrWhiteSpace($env:LAN_IP)) {
        return $env:LAN_IP.Trim()
    }

    $skip = 'Loopback|vEthernet|Virtual|VMware|VirtualBox|Hyper-V|WSL|Bluetooth|Pseudo|Teredo|isatap|Npcap|Tunnel|Docker|VBox|TAP-|TUN-|WireGuard'
    $bestIp = $null
    $bestMetric = [int]::MaxValue
    $loopback = [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback
    $tunnel = [System.Net.NetworkInformation.NetworkInterfaceType]::Tunnel
    $up = [System.Net.NetworkInformation.OperationalStatus]::Up
    $ipv4 = [System.Net.Sockets.AddressFamily]::InterNetwork
    $preferred = [System.Net.NetworkInformation.DuplicateAddressDetectionState]::Preferred

    foreach ($nic in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
        if ($nic.OperationalStatus -ne $up) { continue }
        if ($nic.NetworkInterfaceType -eq $loopback -or $nic.NetworkInterfaceType -eq $tunnel) { continue }
        if ($nic.Name -match $skip -or $nic.Description -match $skip) { continue }

        $properties = $nic.GetIPProperties()
        try {
            $metric = [int]$properties.GetIPv4Properties().Metric
        } catch {
            continue
        }

        foreach ($address in $properties.UnicastAddresses) {
            if ($address.Address.AddressFamily -ne $ipv4) { continue }
            $ip = $address.Address.ToString()
            if ($ip -match '^(127\.|169\.254\.)') { continue }
            if ($address.DuplicateAddressDetectionState -ne $preferred) { continue }
            if ($metric -lt $bestMetric) {
                $bestMetric = $metric
                $bestIp = $ip
            }
        }
    }

    return $bestIp
}

function Write-DevUrls {
    param([string]$LanIp)

    Write-Host ''
    Write-Host 'API:              http://127.0.0.1:8000/api'
    Write-Host 'WebSocket:        ws://127.0.0.1:8080'
    Write-Host 'Website:          http://127.0.0.1:5173'
    Write-Host 'Phone (emulator): http://10.0.2.2:8000/api'
    if ([string]::IsNullOrWhiteSpace($LanIp)) {
        Write-Host 'Phone (device):   set LAN_IP to your Wi-Fi IPv4, then the app uses http://<LAN_IP>:8000/api'
        return
    }

    Write-Host "API on LAN:       http://${LanIp}:8000/api"
    Write-Host "WebSocket on LAN: ws://${LanIp}:8080"
    Write-Host "Website on LAN:   http://${LanIp}:5173"
    Write-Host "Phone (device):   http://${LanIp}:8000/api"
}

function Get-HttpStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 5
    )

    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -UseBasicParsing -TimeoutSec $TimeoutSec
        return [int]$response.StatusCode
    } catch {
        $webResponse = $_.Exception.Response
        if ($null -eq $webResponse) {
            return $null
        }
        try {
            return [int]$webResponse.StatusCode
        } catch {
            return $null
        }
    }
}
