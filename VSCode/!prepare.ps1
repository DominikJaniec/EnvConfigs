param([switch]$LinkBack)

. ".\common.ps1"

$VSCodeProfile = Join-Path $env:USERPROFILE "AppData\Roaming\Code\User"

function EnsureVSCodeAvailable {
    try {
        Write-Output "Preparation of VSCode in version:"
        code --version
    }
    catch {
        Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Write-Output "Please install Visual Studio Code before executing this script."
        throw "Environment is not ready, use: https://code.visualstudio.com/"
    }
}

function InstallExtensionsFrom($sourceFile) {
    $installArgs = LoadLinesFrom $PSScriptRoot $sourceFile `
        | ForEach-Object { "--install-extension $_" }

    $command = "code $($installArgs -join " ")"
    Invoke-Expression $command
}

function PrepareVSCode {
    Write-Output "`n>> Installing VS Code extensions:"
    InstallExtensionsFrom "extensions.txt"

    Write-Output "`n>> Linking configuration files to the VS Code:"
    MakeHardLinkTo $VSCodeProfile $PSScriptRoot "keybindings.json"
    MakeHardLinkTo $VSCodeProfile $PSScriptRoot "settings.json"
}

function HardLinkConfigBack {
    Write-Output "`n>> Linking configuration files from the VS Code:"
    MakeHardLinkTo $PSScriptRoot $VSCodeProfile "keybindings.json" $false
    MakeHardLinkTo $PSScriptRoot $VSCodeProfile "settings.json" $false
}

#######################################################################################

EnsureVSCodeAvailable

if ($LinkBack.IsPresent) {
    HardLinkConfigBack
}
else {
    PrepareVSCode
}

Write-Output "`n>> VS Code preparation: Done."
