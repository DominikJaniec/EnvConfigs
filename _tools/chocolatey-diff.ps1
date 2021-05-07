# This file will render two lists of Chocolatey packages:
# - Installed by not Defined
# - Defined by not Installed
# Based on `..\Choco\packages.txt`


$packagesDefinition = Join-Path $PSScriptRoot "..\Choco\packages.txt"
$packagesDefinition = Resolve-Path $packagesDefinition

$defined = @()
Get-Content -Path $packagesDefinition `
| Where-Object { $_ -notmatch "#" } `
| Where-Object { -not [String]::IsNullOrWhiteSpace($_) } `
| ForEach-Object { "$_".Split("|")[1].Split(" ")[0] } `
| Sort-Object `
| ForEach-Object { $defined += $_ }

$installed = @()
& choco list --local-only `
| Select-Object -Skip 1 `
| Where-Object { -not [String]::IsNullOrWhiteSpace($_) } `
| Where-Object { $_ -notmatch "packages installed" } `
| ForEach-Object { "$_".Split(" ")[0] } `
| Sort-Object `
| ForEach-Object { $installed += "$_" }

Write-Output ""
Write-Output "# Installed by not Defined:"
$installed | Where-Object { $defined -notcontains $_ }

Write-Output ""
Write-Output "# Defined by not Installed:"
$defined | Where-Object { $installed -notcontains $_ }
