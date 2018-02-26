param([switch]$LinkBack)

. ".\common.ps1"

function EnsureGitAvailable {
    try {
        Write-Output "Git user configuration for version:"
        git --version
    }
    catch {
        Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Write-Output "Please install Git before executing this script."
        throw "Environment is not ready, use: https://git-scm.com/"
    }
}

function PrepareGit {
    Write-Output "`n  1. Linking Git configuration file to Home directory:"
    MakeHardLinkTo $Env:USERPROFILE $PSScriptRoot ".gitconfig"
}

function HardLinkConfigBack {
    Write-Output "`n  1. Linking Git configuration file from Home directory:"
    rakeHardLinkTo $PSScriptRoot $Env:USERPROFILE ".gitconfig" $false
}

#######################################################################################

EnsureGitAvailable

if ($LinkBack.IsPresent) {
    HardLinkConfigBack
}
else {
    PrepareGit
}

Write-Output ""
Write-Output "Git preparation: Done."
