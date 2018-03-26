param(
    [string]$VM_Name,
    [string]$VM_Directory
)

Write-Output "===================================================================="
Write-Output "=== ==   This is just dummy Virtual Machine' guest OS setup   == ==="
Write-Output "===================================================================="
Write-Output ""
Write-Output "    When there is defined setup for given VM - via field: 'SetupOS',"
Write-Output "the main '!prepare.ps1' script will call provided script"
Write-Output "(like this one) with two parameters:"
Write-Output "`t1. NAME: '$VM_Name'"
Write-Output "`t2. DIR: '$VM_Directory'"
Write-Output ""
Write-Output "    This script should exit with 0 when everything gone OK."
Write-Output "Any other value will be treated as error by parent script."
Write-Output ""
Write-Output "===================================================================="
exit 7
