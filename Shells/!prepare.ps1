param([switch]$PwshAllUsers)

. ".\common.ps1"

function PrepareGit {
    LogLines -Bar "Linking Git configuration file at Home directory:"
    MakeSymLinksAt $Env:USERPROFILE $PSScriptRoot ".gitconfig"
}

function PrepareBash {
    LogLines -Bar "Linking Bash profile files at Home directory:"
    MakeSymLinksAt $Env:USERPROFILE $PSScriptRoot ".bash_profile", ".bashrc"
}

function PreparePwsh {
    function CallPwsh ($expression) {
        pwsh -NoProfile -Command $expression
    }

    function InstalModulesAtScope ($scope) {
        LogLines -lvl 2 "Installing expected pwsh Modules at '$scope' Scope:"

        $repo = "PSGallery"
        LogLines -lvl 3 "Setting standard '$repo' as trusted repository for pwsh..."
        CallPwsh "Set-PSRepository -Name $repo -InstallationPolicy Trusted"

        $modules = @("posh-git", "oh-my-posh")
        $total = $modules.Length
        $counter = 1
        foreach ($module in $modules) {
            $expr = "Install-Module -Name $module -Repository $repo -Scope $scope"
            LogLines -lvl 3 "[$counter/$total] executing within pwsh:`n$($expr)"
            CallPwsh $expr
            $counter += 1
        }
    }

    function LinkProfileToAllUsers {
        LogLines -lvl 2 "Linking Profile file of All User:"
        $profilePath = CallPwsh "`$PROFILE.AllUsersAllHosts"
        $profileDir = Split-Path $profilePath -Parent
        EnsurePathExists $profileDir
        MakeSymLinksAt $profileDir $PSScriptRoot "Profile.ps1"
    }

    function LinkProfileToCurrentUser {
        LogLines -lvl 2 "Linking Profile file of Current User:"
        $profileDir = Join-Path $HOME "Documents"
        EnsurePathExists $profileDir
        $profileDir = Join-Path $profileDir "PowerShell"
        CreateMissingDirectory $profileDir
        MakeSymLinksAt $profileDir $PSScriptRoot "Profile.ps1"
    }

    LogLines -Bar "Configuring PowerShell Core:"

    if ($PwshAllUsers.IsPresent) {
        InstalModulesAtScope "AllUsers"
        LinkProfileToAllUsers
    }
    else {
        InstalModulesAtScope "CurrentUser"
        LinkProfileToCurrentUser
    }
}

#######################################################################################

Log -Bar "Preparing shells configuration:"

PrepareGit
PrepareBash
PreparePwsh

Log -Bar "Configuration of shells succeeded."
