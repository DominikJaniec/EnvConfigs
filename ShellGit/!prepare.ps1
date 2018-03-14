param([switch]$LinkBack)

. ".\common.ps1"

$ConEmuPath = "C:\Program Files\ConEmu\ConEmu64.exe"
$GitBashPath = "C:\Program Files\Git\git-bash.exe"

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
    $installed = Test-Path $ConEmuPath
    if (-not($installed)) {
        Write-Output "`n>> Could not find 'ConEmu' at: '$ConEmuPath', configuration skipped..."
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

        Write-Output "`n>> Configuring Windwos context menu with Bash via ConEmu"
        New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null

        $regDirectories = @("HKCR:\Directory\shell", "HKCR:\Directory\Background\shell")
        foreach ($regKeyBase in $regDirectories) {
            $regKey = "$regKeyBase\ViaConEmu_GitBash"
            if (Test-Path $regKey) {
                continue
            }

            New-Item $regKey -Value "Open &Bash here" | Out-Null
            Set-ItemProperty $regKey Icon $GitBashPath

            $command = "`"$ConEmuPath`" -Reuse -Dir `"%1`" -run {Bash::Git bash}"
            New-Item "$regKey\command" -Value $command | Out-Null

            Write-Output ">> >> Windows context menu for Bash created at: '$regKey'."
        }

        # TODO : https://github.com/Maximus5/ConEmu/issues/1478
        # & $ConEmuPath -UpdateJumpList -Exit
        & $ConEmuPath -UpdateJumpList -run exit
        Write-Output ">> >> Windows ConEmu integration done."
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
