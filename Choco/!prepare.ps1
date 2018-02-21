param([string]$level = "full")

. ".\common.ps1"

function EnsureChocoAvailable {
    try {
        Write-Output "Software installation via Chocolatey in version:"
        choco --version
    }
    catch {
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Write-Host "Please install Chocolatey before executing this script."
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

function MakeExpression ($packageInstallLine) {
    $expr = @{}
    $parts = "$packageInstallLine".Split("|");
    $expr.Level = PackagesLevelToIndex $parts[0].Trim()
    $expr.Install = "choco install $($parts[1].Trim())"
    return $expr
}

function PackagesInstallExpressionsFrom ($sourceFile, $pkgLevel) {
    return LoadLinesFrom $PSScriptRoot $sourceFile `
        | ForEach-Object { MakeExpression $_ } `
        | Where-Object { $_.Level -le $pkgLevel }
}

#######################################################################################

EnsureChocoAvailable

$packagesLevel = PackagesLevelToIndex $level
$expressions = PackagesInstallExpressionsFrom "packages.txt" $packagesLevel
$total = @($expressions).Count
Write-Output "`n  1. Requested $total installations of software with packages level up to $packagesLevel (-level $level)."

$counter = 1
foreach ($expr in $expressions) {
    $installExpression = "$($expr.Install) --confirm"
    Write-Output "`n  2. [$counter/$total|lvl:$($expr.Level)] executing: '$installExpression'"
    Invoke-Expression $installExpression
    $counter += 1
}

Write-Output "`n  3. Software installation with choco: Done."
