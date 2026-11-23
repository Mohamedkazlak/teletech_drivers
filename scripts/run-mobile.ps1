$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$PSNativeCommandUseErrorActionPreference = $false

. (Join-Path $PSScriptRoot 'dev-common.ps1')

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Wait-DevApi {
    param([Parameter(Mandatory = $true)][string]$ApiBase)

    $probe = "$($ApiBase.TrimEnd('/'))/places"
    if ($ApiBase -eq 'http://10.0.2.2:8000/api') {
        $emulatorStatus = Get-HttpStatus -Url 'http://10.0.2.2:8000/api/places' -TimeoutSec 2
        if ($emulatorStatus -eq 401) {
            Write-Host 'API reachable (401 expected)'
            return
        }
        if ($null -ne $emulatorStatus) {
            Stop-DevScript "GET http://10.0.2.2:8000/api/places returned HTTP $emulatorStatus. Expected 401 (places requires a token). Not starting Flutter."
        }
        Write-Host '10.0.2.2 did not answer from this PC (that address is only for the Android emulator). Checking http://127.0.0.1:8000/api/places instead.'
        $probe = 'http://127.0.0.1:8000/api/places'
    }

    for ($attempt = 1; $attempt -le 20; $attempt++) {
        $status = Get-HttpStatus -Url $probe -TimeoutSec 3
        if ($status -eq 401) {
            Write-Host 'API reachable (401 expected)'
            return
        }
        if ($null -ne $status) {
            Stop-DevScript "GET $probe returned HTTP $status. Expected 401 (places requires a token). Not starting Flutter."
        }
        if ($attempt -eq 1) {
            Write-Host "Waiting for the API at $probe ..."
        }
        Start-Sleep -Seconds 1
    }

    Write-Host "The API did not respond at $probe."
    Write-Host 'Start the backend with npm run dev (php artisan serve listens on 0.0.0.0:8000).'
    Write-Host 'If a phone on the LAN still cannot connect, Windows Firewall may be blocking port 8000. Open it by running this yourself (this script does not run it):'
    Write-Host 'netsh advfirewall firewall add rule name="TeleTech API 8000" dir=in action=allow protocol=TCP localport=8000'
    exit 1
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Stop-DevScript 'Flutter was not found on PATH. Install the Flutter SDK and reopen the terminal.'
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Stop-DevScript 'Node.js was not found on PATH. It is required to read flutter devices.'
}

$lanIp = Get-LanIPv4
if (-not [string]::IsNullOrWhiteSpace($lanIp)) {
    $env:LAN_IP = $lanIp
}

# [System.IO.Path]::GetTempFileName works on Windows PowerShell 5.1 and PowerShell 7.
# New-TemporaryFile is not always present in the host npm launches.
$stderrFile = [System.IO.Path]::GetTempFileName()
$devicesFile = [System.IO.Path]::GetTempFileName()
try {
    $raw = & flutter devices --machine 2>$stderrFile | Out-String
    $flutterCode = $LASTEXITCODE
    if ($flutterCode -ne 0) {
        $flutterError = ''
        if (Test-Path -LiteralPath $stderrFile) {
            $flutterError = Get-Content -Raw -LiteralPath $stderrFile -ErrorAction SilentlyContinue
        }
        Stop-DevScript "flutter devices failed (exit $flutterCode). $flutterError"
    }

    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($devicesFile, $raw, $utf8)

    $selector = Join-Path $PSScriptRoot 'select-flutter-device.mjs'
    $selectionText = & node $selector $devicesFile | Out-String
    $selectCode = $LASTEXITCODE
} finally {
    Remove-Item -Force -LiteralPath $stderrFile, $devicesFile -ErrorAction SilentlyContinue
}

if ($selectCode -ne 0) {
    exit $selectCode
}

$selection = $selectionText | ConvertFrom-Json
Write-Host "Flutter device: $($selection.name) ($($selection.id))"
Write-Host "API_BASE_URL=$($selection.apiBaseUrl)"
Wait-DevApi -ApiBase ([string]$selection.apiBaseUrl)

$defines = @("--dart-define=API_BASE_URL=$([string]$selection.apiBaseUrl)")
$envFile = Join-Path $Root 'backend\.env'
$reverbKey = Read-DotEnvValue -Path $envFile -Name 'REVERB_APP_KEY'
$reverbPort = Read-DotEnvValue -Path $envFile -Name 'REVERB_PORT'
$reverbScheme = Read-DotEnvValue -Path $envFile -Name 'REVERB_SCHEME'
if (-not [string]::IsNullOrWhiteSpace($reverbKey)) {
    $defines += "--dart-define=REVERB_APP_KEY=$reverbKey"
    if ([string]::IsNullOrWhiteSpace($reverbPort)) { $reverbPort = '8080' }
    if ([string]::IsNullOrWhiteSpace($reverbScheme)) { $reverbScheme = 'http' }
    $defines += "--dart-define=REVERB_PORT=$reverbPort"
    $defines += "--dart-define=REVERB_SCHEME=$reverbScheme"
    Write-Host "REVERB_PORT=$reverbPort"
}

& flutter run -d ([string]$selection.id) @defines
exit $LASTEXITCODE
