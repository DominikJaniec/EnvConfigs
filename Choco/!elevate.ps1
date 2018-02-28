function IsCurrentAdmin {
    $adminRole = [Security.Principal.WindowsBuiltInRole] "Administrator"
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $principal.IsInRole($adminRole)
}

if (-not(IsCurrentAdmin)) {
    $repositoryDirectory = Join-Path $PSScriptRoot ".." | Resolve-Path
    $init = "-NoExit -Command Set-Location '$repositoryDirectory'"

    Write-Output "Starting a new PowerShell console with elevated permissions..."
    Start-Process powershell.exe -Verb runAs -ArgumentList $init
}
else {
    Write-Output "PowerShell console's permissions already elevated to Admin role."
}
