$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$PSNativeCommandUseErrorActionPreference = $false

. (Join-Path $PSScriptRoot 'dev-common.ps1')

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
    Stop-DevScript 'PHP was not found on PATH. Install PHP 8.3 or newer and reopen the terminal.'
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Stop-DevScript 'Node.js was not found on PATH. Install Node.js 20 or newer and reopen the terminal.'
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Stop-DevScript 'Flutter was not found on PATH. Install the Flutter SDK and reopen the terminal.'
}

$autoload = Join-Path $Root 'backend\vendor\autoload.php'
if (-not (Test-Path -LiteralPath $autoload)) {
    Stop-DevScript 'Composer dependencies are missing (backend/vendor/autoload.php). From the backend directory run: composer install'
}

$envFile = Join-Path $Root 'backend\.env'
if (-not (Test-Path -LiteralPath $envFile)) {
    Stop-DevScript 'backend/.env is missing. Copy backend/.env.example to backend/.env, set APP_ENV=local, then from the backend directory run: php artisan key:generate'
}

$connection = Read-DotEnvValue -Path $envFile -Name 'DB_CONNECTION'
if ([string]::IsNullOrWhiteSpace($connection)) {
    Stop-DevScript 'backend/.env does not set DB_CONNECTION. Set DB_CONNECTION=pgsql.'
}
if ($connection -ne 'pgsql') {
    Stop-DevScript "backend/.env must set DB_CONNECTION=pgsql (found: $connection). This setup uses the PostgreSQL database from backend/docker-compose.yml."
}

Push-Location (Join-Path $Root 'backend')
try {
    $migrateOutput = & php artisan migrate:status 2>&1 | Out-String
    $migrateCode = $LASTEXITCODE
} finally {
    Pop-Location
}

if ($migrateCode -ne 0) {
    Write-Host $migrateOutput
    Stop-DevScript @"
The database is not reachable or migrations cannot be read (php artisan migrate:status failed).
If the output says there is no application encryption key, from the backend directory run: php artisan key:generate
Otherwise start PostgreSQL (from the backend directory: docker compose up -d), check DB_HOST, DB_PORT, DB_DATABASE, DB_USERNAME, and DB_PASSWORD in backend/.env, then run: php artisan migrate
"@
}

$appEnv = Read-DotEnvValue -Path $envFile -Name 'APP_ENV'
if ([string]::IsNullOrWhiteSpace($appEnv) -or $appEnv -eq 'production') {
    Write-Host 'Warning: set APP_ENV=local and APP_DEBUG=true in backend/.env. Production turns off the dev CORS defaults and dev:seed-users will refuse.'
}

Write-Host 'Preflight passed.'
Write-DevUrls -LanIp (Get-LanIPv4)
