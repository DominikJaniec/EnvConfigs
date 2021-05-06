. ".\common.ps1"

function PrepareGit {
    Write-Output "`n>> Linking Git configuration file at Home directory:"
    MakeSymLinksAt $Env:USERPROFILE $PSScriptRoot ".gitconfig"
}

function PrepareBash {
    Write-Output "`n>> Linking Bash profile files at Home directory:"
    MakeSymLinksAt $Env:USERPROFILE $PSScriptRoot @(".bash_profile", ".bashrc")
}

function PreparePowerShell {
    Write-Output "`n>> Linking PowerShell profile file of current User:"
    $pwshProfileDir = Join-Path $HOME "Documents"
    EnsurePathExists $pwshProfileDir
    $pwshProfileDir = Join-Path $pwshProfileDir "PowerShell"
    CreateMissingDirectory $pwshProfileDir
    MakeSymLinksAt $pwshProfileDir $PSScriptRoot "Profile.ps1"
}

#######################################################################################

Write-Output "Preparing shells configuration..."
PrepareGit
PrepareBash
PreparePowerShell
