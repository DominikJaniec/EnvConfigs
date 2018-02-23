. ".\common.ps1"

function EnsureGitAvailable {
    try {
        Write-Output "Git user configuration for version:"
        git --version
    }
    catch {
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Write-Host "Please install Git before executing this script."
        throw "Environment is not ready, use: https://git-scm.com/"
    }
}

#######################################################################################

EnsureGitAvailable

Write-Output "`n  1. Linking configuration file of Git:"
MakeHardLinkTo $Env:USERPROFILE $PSScriptRoot ".gitconfig"

Write-Output "`n  2. Git configuratio: Done."
