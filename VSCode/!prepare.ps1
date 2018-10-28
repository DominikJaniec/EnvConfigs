param(
    [switch]$LinkBack,
    [string]$Extensions = "all"
)

. ".\common.ps1"

$ExtensionsSeparator = ","
$ExtensionsGroups = @("all", "must", "tools", "coding", "haskell", "extra")
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

function Resolve-ExtensionsGroup ($group) {
    $group = $group.Trim().ToLower()
    if ($ExtensionsGroups -contains $group) {
        return $group
    }

    $valid = $ExtensionsGroups -join "|"
    throw "Unknown extensions group: '$group', use: ($valid)" `
        + " as well as multiple values concatenated with: '$ExtensionsSeparator'."
}

function Get-RequestedExtensionsGroups ($extensions) {
    $requested = $extensions.Split($ExtensionsSeparator) `
        | ForEach-Object { Resolve-ExtensionsGroup $_ }

    if ($requested -contains "all") {
        return $ExtensionsGroups
    }

    return $requested
}

function Test-ExtensionRequested ($requestedGroups, $extensionData) {
    $extensionGroup = Resolve-ExtensionsGroup $extensionData.Metadata
    return $requestedGroups -contains $extensionGroup
}

function InstallExtensionsFrom ($sourceFile, $extensions) {
    $requested = Get-RequestedExtensionsGroups $extensions
    $installArgs = LoadMetaLinesFrom $PSScriptRoot $sourceFile `
        | Where-Object { Test-ExtensionRequested $requested $_ } `
        | ForEach-Object {
        $group = $_.Metadata
        $group = $_.Metadata
        $extension = $_.Value
        Write-Host ">> >> Will install '$group': '$extension'."
        return "--install-extension '$extension'"
    }

    $installArgs = $installArgs -join " "
    $command = "code $installArgs"
    Invoke-Expression $command
}

function PrepareVSCode ($installExtensions) {
    Write-Output "`n>> Installing VS Code extensions:"
    InstallExtensionsFrom "extensions.txt" $installExtensions

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
    PrepareVSCode $Extensions
}

Write-Output "`n>> VS Code preparation: Done."
