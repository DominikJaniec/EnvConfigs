param([switch]$LinkBack)

. ".\common.ps1"

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

function CheckConEmuInstalled {
    $path = "C:\Program Files\ConEmu\ConEmu64.exe"
    $installed = Test-Path $path
    if (-not($installed)) {
        Write-Output "`n>> Could not find 'ConEmu', configuration skipped..."
    }

    return $installed
}

function PrepareEnvironment {
    Write-Output "`n>> Linking Git configuration file to Home directory:"
    MakeHardLinkTo $Env:USERPROFILE $PSScriptRoot ".gitconfig"

    Write-Output "`n>> Linking Bash configuration files to Home directory:"
    MakeHardLinkTo $Env:USERPROFILE $PSScriptRoot ".bash_profile"
    MakeHardLinkTo $Env:USERPROFILE $PSScriptRoot ".bashrc"

    if (CheckConEmuInstalled) {
        Write-Output "`n>> Linking ConEmu configuration file to 'AppData` directory:"
        MakeHardLinkTo $Env:APPDATA $PSScriptRoot "ConEmu.xml"
    }
}

function HardLinkConfigBack {
    Write-Output "`n>> Linking Git configuration file from Home directory:"
    MakeHardLinkTo $PSScriptRoot $Env:USERPROFILE ".gitconfig" $false

    Write-Output "`n>> Linking Bash configurations file from Home directory:"
    MakeHardLinkTo $PSScriptRoot $Env:USERPROFILE ".bash_profile" $false
    MakeHardLinkTo $PSScriptRoot $Env:USERPROFILE ".bashrc" $false

    if (CheckConEmuInstalled) {
        Write-Output "`n>> Linking ConEmu configuration file from 'AppData` directory:"
        MakeHardLinkTo $PSScriptRoot $Env:APPDATA "ConEmu.xml" $false
    }
}

#######################################################################################

EnsureGitAvailable

if ($LinkBack.IsPresent) {
    HardLinkConfigBack
}
else {
    PrepareEnvironment
}

Write-Output "`n>> Git and Bash shell preparation: Done."
