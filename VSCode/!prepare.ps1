param(
    [string]$Extensions = "all",
    [switch]$SkipExtra,
    [switch]$SkipWork
)

. ".\common.ps1"

$GrAll = "all"
$GrWork = "work"
$GrExtra = "extra"
$ExtensionsGroups = @("core", "tools", "dev", "webdev", $GrWork, $GrExtra)
$ValidExtensionsGroups = $ExtensionsGroups + $GrAll
$GroupsSeparator = ","

$VSCodeProfile = Join-Path $env:APPDATA "Code\User"

function EnsureVSCodeAvailableInAnyVersion {
    try {
        code --version
    }
    catch {
        Log "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Log "Please install Visual Studio Code before executing this script."
        throw "Environment is not ready, requires: https://code.visualstudio.com/"
    }
}

function Get-Normalized ($str) {
    return "$str".Trim().ToLower()
}

function Resolve-ExtensionsGroup ($group) {
    $gr = Get-Normalized $group
    if ($ValidExtensionsGroups -contains $gr) {
        return $gr
    }

    $valid = $ValidExtensionsGroups -join $GroupsSeparator
    throw "Unknown extensions group: '$group'" `
        + ", please use one or many: $valid."
}

function Get-RequestedExtensionsGroups {
    $requested = $Extensions.Split($GroupsSeparator) `
    | ForEach-Object { Resolve-ExtensionsGroup $_ }

    if ($requested -contains $GrAll) {
        $requested = $ExtensionsGroups
    }

    if ($SkipWork.IsPresent) {
        $requested = $requested `
        | Where-Object { $_ -ne $GrWork }
    }

    if ($SkipExtra.IsPresent) {
        $requested = $requested `
        | Where-Object { $_ -ne $GrExtra }
    }

    return $requested
}

function Test-RequestedGroup ($requested, $group) {
    $gr = Resolve-ExtensionsGroup $group
    return $requested -contains $gr
}

function InstallExtensions ($extensionsNames) {
    $installArgs = $extensionsNames `
    | ForEach-Object { "--install-extension '$_'" }

    $installArgs = $installArgs -join " "
    $command = "code $installArgs"
    Invoke-Expression $command
}

function InstallRequestedExtensions {
    LogLines2 -Bar "Installing requested VS Code extensions groups:"

    $requested = Get-RequestedExtensionsGroups
    LogLines3 ($requested -join ", ")

    LoadMetaLinesGroupedFrom $PSScriptRoot "extensions.txt" `
    | Where-Object { Test-RequestedGroup $requested $_.Metadata } `
    | ForEach-Object {
        $group = $_.Metadata
        LogLines -Bar -lvl 2 "Will install '$group' group:"
        InstallExtensions $_.Values
    }
}

function LinkConfigFiles {
    LogLines2 -Bar "Linking configuration files at VS Code profile directory:"

    MakeSymLinksAt $VSCodeProfile $PSScriptRoot "keybindings.json"
    MakeSymLinksAt $VSCodeProfile $PSScriptRoot "settings.json"
}

#######################################################################################

LogLines -Bar "Preparation of VSCode:"
EnsureVSCodeAvailableInAnyVersion

LinkConfigFiles
InstallRequestedExtensions

LogLines -Bar "VS Code preparation: Done."
