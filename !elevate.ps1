function IsCurrentAdmin {
    $adminRole = [Security.Principal.WindowsBuiltInRole] "Administrator"
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $principal.IsInRole($adminRole)
}

if (IsCurrentAdmin) {
    Write-Output ">> PowerShell console's permissions already elevated to the Administrator role."
    exit
}

Write-Output ">> Starting a new PowerShell console with elevated permissions (Admin)..."

$init = "-NoExit -Command Set-Location '$PSScriptRoot'"
Start-Process powershell.exe -Verb runAs -ArgumentList $init
