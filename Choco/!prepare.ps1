param([string]$PkgLevel = "full")

$PackagesLevels = @("core", "tools", "dev", "full")

. ".\common.ps1"

function EnsureChocoAvailable {
    try {
        Write-Output ">> Software installation via Chocolatey in version:"
        choco --version
    }
    catch {
        Write-Output ">> !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Write-Output ">> Please install Chocolatey before executing this script."
        throw "Environment is not ready, use: https://chocolatey.org/install"
    }
}

function EnableRememberedArguments {
    Write-Output ">> Enabling Chocolatey's feature: Use Remembered Arguments For Upgrades..."
    choco feature enable --name useRememberedArgumentsForUpgrades
    if ($LASTEXITCODE -ne 0) {
        throw "Could not enable feature 'useRememberedArgumentsForUpgrades'"
    }
}

function PackagesLevelToIndex($pkgLevel) {
    $lvl = "$pkgLevel".Trim().ToLower()
    if ($lvl -eq "") {
        return $PackagesLevels.Length
    }

    $index = $PackagesLevels.IndexOf($lvl)
    if ($index -ge 0) {
        return $index
    }

    $valid = $PackagesLevels -join "|"
    throw "Unknown packages level: '$pkgLevel', use: ($valid)" `
        + " where each value includes every previous one in order."
}

function PackagesInstallExpressionsFrom ($sourceFile) {
    return LoadMetaLinesFrom $PSScriptRoot $sourceFile `
    | ForEach-Object {
        $lvl = $_.Metadata
        $pkg = $_.Value

        return @{
            Level   = $lvl;
            Index   = PackagesLevelToIndex $lvl;
            Install = "choco install $pkg --yes"
        }
    }
}

function RefreshEnvWithChoco {
    # https://docs.chocolatey.org/en-us/create/functions/update-sessionenvironment
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    refreshenv
}

#######################################################################################

EnsureChocoAvailable
EnableRememberedArguments

$levelIdx = PackagesLevelToIndex $PkgLevel
$expressions = PackagesInstallExpressionsFrom "packages.txt" `
| Where-Object { $_.Index -le $levelIdx }

$total = @($expressions).Length
Write-Output "`n>> Requested $total installations of software with packages level up to $levelIdx (-PkgLevel $PkgLevel)."

$counter = 1
foreach ($expr in $expressions) {
    Write-Output "`n##############################################################################"
    Write-Output ">> >> [$counter/$total|lvl:$($expr.Level)] executing: $($expr.Install)"
    Invoke-Expression $expr.Install
    $counter += 1
}

Write-Output "`n##############################################################################"
RefreshEnvWithChoco

Write-Output "`n##############################################################################"
Write-Output ">> Software installation via Chocolatey: Done."
Write-Output "  -- Some packages may require a reboot."
Write-Output ""
