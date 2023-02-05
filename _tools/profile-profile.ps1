param ($Iterations = 6.9, [switch]$TestUPDATECHECK, $UseProfileFile)

if ($Iterations -lt 1) {
    Write-Warning "Assuming `$Iterations = 0"
    $Iterations = 1
}

if ($null -ne $UseProfileFile `
        -and -not (Test-Path $UseProfileFile) `
) {
    throw "Unknown given Profile path: '$UseProfileFile'"
}

. $PSScriptRoot\profile-test.ps1


$headerline = [String]::new("-", 96)
Write-Host $headerline
Write-Host "Let's profile how pwsh behaves on startup..."


function nsprint ($number, $decimals = 2) {
    return ([double]$number).ToString(
        "F" + $decimals,
        [CultureInfo]::InvariantCulture)
}

function Start-Benchmark ($Expression, $Title) {
    $total = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Host ""
    $what = "Runnin: '$Title'"

    Write-Progress -Activity $what -PercentComplete 1
    Write-Host $headerline
    Write-Host "Benchmarking expression: $Expression"
    $warmup = [System.Diagnostics.Stopwatch]::StartNew()
    Invoke-Command $Expression | Out-Host
    $warmup = [int]$warmup.ElapsedMilliseconds

    $n = [int]$Iterations
    $percentFactor = 100.0
    if ($n -gt 1) {
        $percentFactor /= $n
    }

    $measured = 0
    $minimum = [int]::MaxValue
    $maximum = [int]::MinValue

    if ($n -eq 1) {
        $measured = $minimum = $maximum = $warmup
    }
    else {
        2..$n | ForEach-Object {
            $completed = ($_ - 1) * $percentFactor
            Write-Progress -Activity $what -PercentComplete $completed
            $execution = (Measure-Command $Expression).TotalMilliseconds

            if ($execution -lt $minimum) {
                $minimum = $execution
            }
            if ($maximum -lt $execution) {
                $maximum = $execution
            }
            $measured += $execution
        }
    }

    Write-Progress -Activity $what -Completed
    $average = nsprint ($measured / $n)
    $minimum = nsprint $minimum
    $maximum = nsprint $maximum
    $warmup = nsprint $warmup
    $total.Stop()

    Write-Host "Result: '$Title'"
    Write-Host ("Within $($total.Elapsed)" `
            + " / $n times." `
            + "`n`t- warm up: $warmup ms" `
            + "`n`t- average: $average ms" `
            + "`n`t- minimum: $minimum ms" `
            + "`n`t- maximum: $maximum ms" `
    )

    return $average
}


#####################################################################

$testedRun = 0
$baseRun = Start-Benchmark -Title "Default NoProfile pwsh startup" `
    -Expression { Start-PwshNoProfile { exit 0 } }


if ($TestUPDATECHECK.IsPresent) {
    $current = $Env:POWERSHELL_UPDATECHECK

    # The following values are supported:
    # * is the same as not defining POWERSHELL_UPDATECHECK
    # $Env:POWERSHELL_UPDATECHECK = "Default"
    # * releases notify of updates to GA releases
    # $Env:POWERSHELL_UPDATECHECK = "GA"
    # * releases notify of updates to GA and preview releases
    # $Env:POWERSHELL_UPDATECHECK = "RC" # = "Preview"
    # * only notifies of updates to long-term-servicing (LTS) GA releases
    # $Env:POWERSHELL_UPDATECHECK = "LTS"
    # * turns off the update notification feature
    $Env:POWERSHELL_UPDATECHECK = "Off"

    $testedRun = Start-Benchmark -Title "Startup pwsh under POWERSHELL_UPDATECHECK" `
        -Expression { Start-PwshNoProfile { exit 0 } }

    Write-Host "Under `$Env:POWERSHELL_UPDATECHECK:" `
        $Env:POWERSHELL_UPDATECHECK

    $Env:POWERSHELL_UPDATECHECK = $current
}
elseif ($null -ne $UseProfileFile) {
    $testedRun = Start-Benchmark -Title "Startup pwsh with given script Profile" `
        -Expression { Start-PwshWithFile $UseProfileFile }
}
else {
    $testedRun = Start-Benchmark -Title "Startup of pwsh with own Profile" `
        -Expression { Start-PwshDefaults }
}


Write-Host ""
Write-Host $headerline

$timeOver = $testedRun - $baseRun
$timeOver = nsprint $timeOver
$baseRun = nsprint $baseRun
$testedRun = nsprint $testedRun

Write-Host "Avarage time-over-much-difference"
Write-Host "`t- value: $timeOver ms"
Write-Host "`t- base run: $baseRun ms"
Write-Host "`t- tested run: $testedRun ms"
