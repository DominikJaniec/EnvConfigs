param([string]$PkgLevel = "full")

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
    choco feature enable -n useRememberedArgumentsForUpgrades
    if ($LASTEXITCODE -ne 0) {
        throw "Could not enable feature 'useRememberedArgumentsForUpgrades'"
    }
}

function PackagesLevelToIndex($pkgLevel) {
    $empty = ""
    switch ("$pkgLevel".ToLower().Trim()) {
        "core" { return 0 }
        "work" { return 1 }
        "full" { return 2 }
        $empty { return 2 }
        default {
            throw "Unknown packages level: '$pkgLevel', use: (core|work|full)."
        }
    }
}

function MakeChocoExpression ($packageInstallLine) {
    $parts = "$packageInstallLine".Split("|");
    $lvl = $parts[0].Trim()
    $pkg = $parts[1].Trim()
    return @{
        Level   = PackagesLevelToIndex $lvl;
        Install = "choco install $pkg --confirm"
    }
}

function PackagesInstallExpressionsFrom ($sourceFile, $levelIdx) {
    return LoadLinesFrom $PSScriptRoot $sourceFile `
        | ForEach-Object { MakeChocoExpression $_ } `
        | Where-Object { $_.Level -le $levelIdx }
}

#######################################################################################

EnsureChocoAvailable
EnableRememberedArguments

$levelIdx = PackagesLevelToIndex $PkgLevel
$expressions = PackagesInstallExpressionsFrom "packages.txt" $levelIdx
$total = @($expressions).Count
Write-Output "`n>> Requested $total installations of software with packages level up to $levelIdx (-PkgLevel $PkgLevel)."

$counter = 1
foreach ($expr in $expressions) {
    Write-Output "`n##############################################################################"
    Write-Output ">> >> [$counter/$total|lvl:$($expr.Level)] executing: $($expr.Install)"
    Invoke-Expression $expr.Install
    $counter += 1
}

Write-Output "`n##############################################################################"
Write-Output ">> Software installation via Chocolatey: Done."
Write-Output "  -- Some packages may require reboot."
