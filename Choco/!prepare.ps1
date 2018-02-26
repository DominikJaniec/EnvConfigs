param([string]$PkgLevel = "full")

. ".\common.ps1"

function EnsureChocoAvailable {
    try {
        Write-Output "Software installation via Chocolatey in version:"
        choco --version
    }
    catch {
        Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Write-Output "Please install Chocolatey before executing this script."
        throw "Environment is not ready, use: https://chocolatey.org/install"
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
    $expr = @{}
    $parts = "$packageInstallLine".Split("|");
    $expr.Level = PackagesLevelToIndex $parts[0].Trim()
    $expr.Install = "choco install $($parts[1].Trim())"
    return $expr
}

function PackagesInstallExpressionsFrom ($sourceFile, $levelIdx) {
    return LoadLinesFrom $PSScriptRoot $sourceFile `
        | ForEach-Object { MakeChocoExpression $_ } `
        | Where-Object { $_.Level -le $levelIdx }
}

#######################################################################################

EnsureChocoAvailable

$levelIdx = PackagesLevelToIndex $PkgLevel
$expressions = PackagesInstallExpressionsFrom "packages.txt" $levelIdx
$total = @($expressions).Count
Write-Output "`n  1. Requested $total installations of software with packages level up to $levelIdx (-PkgLevel $PkgLevel)."

$counter = 1
foreach ($expr in $expressions) {
    $installExpression = "$($expr.Install) --confirm"
    Write-Output "`n  2. [$counter/$total|lvl:$($expr.Level)] executing: '$installExpression'"
    Invoke-Expression $installExpression
    $counter += 1
}

Write-Output ""
Write-Output "Software installation via Chocolatey: Done."
