param([switch]$LinkBack)

. ".\common.ps1"

$ExpectedPath_GitBash = Join-Path $Env:PROGRAMFILES "Git\git-bash.exe"

function EnsureGitAvailable {
    try {
        Write-Output ">> User's configuration for Git in version:"
        git --version
    }
    catch {
        Write-Output ">> !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Write-Output ">> Please install Git before executing this script."
        throw "Environment is not ready, use: https://git-scm.com/"
    }
}

function SetupGitConfiguration {
    Write-Output "`n>> Linking Git configuration file in Home directory:"
    if ($LinkBack.IsPresent) {
        MakeHardLinkTo $PSScriptRoot $Env:USERPROFILE ".gitconfig" $false
    }
    else {
        MakeHardLinkTo $Env:USERPROFILE $PSScriptRoot ".gitconfig"
    }
}

function SetupGitBashEnvironment {
    if (CouldNotFindForConfig "GitBash" $ExpectedPath_GitBash) {
        return
    }

    Write-Output "`n>> Linking Bash's configurations file in Home directory:"
    if ($LinkBack.IsPresent) {
        MakeHardLinkTo $PSScriptRoot $Env:USERPROFILE ".bash_profile" $false
        MakeHardLinkTo $PSScriptRoot $Env:USERPROFILE ".bashrc" $false
    }
    else {
        MakeHardLinkTo $Env:USERPROFILE $PSScriptRoot ".bash_profile"
        MakeHardLinkTo $Env:USERPROFILE $PSScriptRoot ".bashrc"
    }
}

#######################################################################################

EnsureGitAvailable

SetupGitConfiguration
SetupGitBashEnvironment

Write-Output "`n>> Git and Bash shell preparation: Done."

if ($LinkBack.IsPresent) {
    Write-Output ">> HardLink have been created into this Repository."
}
