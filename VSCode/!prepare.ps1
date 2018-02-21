. ".\common.ps1"

$vsCodePath = Join-Path $env:USERPROFILE "AppData\Roaming\Code\User"
$oneDriveBasePath = Join-Path $env:USERPROFILE "OneDrive"
$oneDrivePath = Join-Path $oneDriveBasePath "Configurations\VS Code"

function EnsureVSCodeAvailable {
    try {
        Write-Output "Preparation of VSCode in version:"
        code --version
    }
    catch {
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Write-Host "Please install Visual Studio Code before executing this script."
        throw "Environment is not ready, use: https://code.visualstudio.com/"
    }
}

function InstallExtensionsFrom($sourceFile) {
    $installArgs = LoadLinesFrom $PSScriptRoot $sourceFile `
        | ForEach-Object { "--install-extension $_" }

    $command = "code $($installArgs -join " ")"
    Invoke-Expression $command
}

function HardLinkConfigurationTo ($targetDir) {
    MakeHardLinkTo $targetDir $PSScriptRoot "keybindings.json"
    MakeHardLinkTo $targetDir $PSScriptRoot "settings.json"
}

function HardLinkConfigurationToOneDrive {
    if (-not(Test-Path $oneDriveBasePath) ) {
        Write-Output "`t OneDrive synchronization skipped due unknown OneDrive location..."
        return
    }

    HardLinkConfigurationTo $oneDrivePath
}

#######################################################################################

EnsureVSCodeAvailable

Write-Output "`n  1. Installing extensions:"
InstallExtensionsFrom "extensions.txt"

Write-Output "`n  2. Linking configuration files to the VS Code:"
HardLinkConfigurationTo $vsCodePath

Write-Output "`n  3. Linking configuration files to the OneDrive:"
HardLinkConfigurationToOneDrive

Write-Output "`n  4. VSCode preparation: Done."
