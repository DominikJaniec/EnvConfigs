function IsCurrentAdmin {
    $adminRole = [Security.Principal.WindowsBuiltInRole] "Administrator"
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $principal.IsInRole($adminRole)
}

if (IsCurrentAdmin) {
    Write-Output ">> PowerShell console's permissions already elevated to the Administrator role."
    exit
}

$logFile = Join-Path $PSScriptRoot "execution-transcript-$(Get-Date -Format yyyy-MM-dd).log"
$transcription = "Start-Transcript -Path '$logFile' -Append -IncludeInvocationHeader"
$initInnerCommand = "$transcription; Set-Location '$PSScriptRoot'"
$initArgs = "-NoExit -NoProfile -Command `"$initInnerCommand`""

Write-Output ">> Starting a new PowerShell console with elevated permissions (Admin)..."
Start-Process PowerShell.exe -Verb runAs -ArgumentList $initArgs
