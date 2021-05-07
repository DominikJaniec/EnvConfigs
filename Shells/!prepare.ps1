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
    function InstalModules {
        LogLines -lvl 2 "Installing expected pwsh Modules:"

        $repo = "PSGallery"
        LogLines -lvl 3 "Setting standard '$repo' as trusted repository for pwsh..."
        pwsh -Command "Set-PSRepository -Name $repo -InstallationPolicy Trusted"

        $modules = @("posh-git", "oh-my-posh")
        $total = $modules.Length
        $counter = 1
        foreach ($module in $modules) {
            $expr = "Install-Module -Name $module -Repository $repo"
            LogLines -lvl 3 "[$counter/$total] executing within pwsh:`n$($expr)"
            pwsh -Command $expr
            $counter += 1
        }
    }

    function LinkProfile {
        LogLines -lvl 2 "Linking Profile file of current User:"
        $profileDir = Join-Path $HOME "Documents"
        EnsurePathExists $profileDir
        $profileDir = Join-Path $profileDir "PowerShell"
        CreateMissingDirectory $profileDir
        MakeSymLinksAt $profileDir $PSScriptRoot "Profile.ps1"
    }

    LogLines -Bar "Configuring PowerShell for current User:"
    InstalModules
    LinkProfile
}

#######################################################################################

Write-Output "Preparing shells configuration..."
PrepareGit
PrepareBash
PreparePwsh
