$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$PSNativeCommandUseErrorActionPreference = $false

Write-Host ("PSVersion=" + $PSVersionTable.PSVersion.ToString())
Write-Host ("Edition=" + $PSVersionTable.PSEdition)
Write-Host ("autoload=" + $PSModuleAutoloadingPreference)
Write-Host ("TEMP=" + $env:TEMP)

$stderrFile = New-TemporaryFile
Write-Host ("OK " + $stderrFile.FullName)
Remove-Item -Force -LiteralPath $stderrFile
