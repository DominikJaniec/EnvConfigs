param ($Iterations = 69)

function profile ($file) {
    $file = "$PSScriptRoot\$file"
    Write-Host "======================================================================================"
    Write-Host "=== Profiling with $Iterations iterations using profile-ish file for `$UseProfileFile:"
    Write-Host "=== `t$file"
    Write-Host "==="

    & "$PSScriptRoot\profile-profile.ps1" `
        -UseProfileFile $file `
        -Iterations $Iterations

    Write-Host ""
}


profile "test-posh-git-no-prompt.ps1"
profile "test-posh-git-v1.1.0.ps1"
