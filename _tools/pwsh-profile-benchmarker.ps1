param ([int]$Iterations = 42, [switch]$ToCSV, [switch]$SkipJustPwsh, [switch]$SkipJustModule)

$TotalWatch = [Diagnostics.Stopwatch]::StartNew()
$HorizontalLine = [string]::new("_", 69)


$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3.0

if ($Iterations -lt 1) {
    Write-Error "`$Iterations ($Iterations) value cannot be negative."
    exit 13
}


# Unique keys for each version of profile-ish script:
$Keys = "alpha", "beta", "gamma"

# Render profile-ish script lines based on key:
function Get-ProfileScriptLines ($Key) {
    @("Write-Host `"Hello '$Key'!`"")
}

# Special case of "just" Import-Module of simple module:
$JustModuleKey = "just-import-module"
$JustModuleLines = @("Import-Module -Name `"$PSScriptRoot\empty-ish-module.psm1`"")
if (-not $SkipJustModule.IsPresent) {
    $Keys = @($JustModuleKey) + $Keys
}

# Special case of "just" PowerShell run:
$JustPwshKey = "just-pwsh"
$JustPwshLines = @("exit 0")
if (-not $SkipJustPwsh.IsPresent) {
    $Keys = @($JustPwshKey) + $Keys
}

$KeysCount = $Keys.Length
"Benchmarking $KeysCount profile-ish scripts" `
    + " with $Iterations`x iterations each."
| Write-Host

function Show-ProfileScriptLines ($Key, $Lines) {
    Write-Host $HorizontalLine
    Write-Host "Rendered profile script for '$Key':"
    foreach ($line in $Lines) {
        Write-Host "`t> $line"
    }
    Write-Host ("`t+" + [string]::new("-", 61))
}

$script:PwshCounter = 0
function Start-PwshWith ($ProfileScript) {
    $command = "$ProfileScript"
    $bytes = [Text.Encoding]::Unicode.GetBytes($command)
    $codedCommand = [Convert]::ToBase64String($bytes)

    $watch = [Diagnostics.Stopwatch]::StartNew()
    $out = pwsh -NoLogo -NoProfile -NonInteractive `
        -EncodedCommand $codedCommand `
    | Out-String
    $gotError = -not $?

    return @{
        nth = ++$script:PwshCounter
        err = $gotError
        ms  = $watch.ElapsedMilliseconds
        out = $out.Trim()
    }
}

$Warmups = @{}
function Start-PwshScriptWarmup ($Key, $ScriptBlock) {
    $id = "Warmup: '$Key'"
    Write-Progress -Activity $id `
        -Status "Executin script..." `
        -PercentComplete 33

    $ret = Start-PwshWith $ScriptBlock
    Write-Progress -Activity $id `
        -Completed

    $Warmups[$Key] = $ret
    $exit = -not $ret.err
    $ms = $ret.ms
    $out = $ret.out

    Write-Host "`t`t*  successfully exited: $exit, within $ms [ms]"
        [String]::IsNullOrWhiteSpace($out) `
        ? "`t`t*  no-output" `
            : $out
    | Write-Host

    if (-not $exit) {
        Write-Error "Got $exit from '$Key'"
    }

    Write-Host ""

    # a hack, to fix progress bar:
    Start-Sleep -Milliseconds 609
}


$WarmupsWatch = [Diagnostics.Stopwatch]::StartNew()
$TestScripts = $Keys | ForEach-Object {
    $lines = switch ($_) {
        $JustPwshKey { @($JustPwshLines) }
        $JustModuleKey { @($JustModuleLines) }
        Default { @(Get-ProfileScriptLines -Key $_) }
    }

    Show-ProfileScriptLines $_ $lines

    $lines += "; exit `$? ? 0 : 13"
    $ps = $lines -join "`n"
    Start-PwshScriptWarmup $_ $ps

    [PSObject]@{
        Key    = $_;
        Script = $ps
    }
}
$warmupsElapsed = $WarmupsWatch.Elapsed

$Profiled = @{}
foreach ($key in $Keys) {
    $Profiled[$key] = @($Warmups[$key])
}


Write-Host ""
$id = "Benchmarking"

function Get-MeasuredKeysOrder ($Keys) {
    $ith = 1
    $level = 2

    while ($true) {
        if ($Iterations -lt $ith) {
            return
        }

        foreach ($key in $Keys) {
            $i = 0
            while ($i -lt $level) {
                $n = $ith + $i
                if ($Iterations -gt $n) {
                    Write-Output $key
                }

                $i++
            }
        }

        $ith += $level
        $level++
    }
}


$keysOrder = @(Get-MeasuredKeysOrder $Keys)
$totalCount = ($Iterations - 1) * $KeysCount

$initETA = [double]$totalCount / $KeysCount
$initETA *= $warmupsElapsed.TotalMilliseconds
$initETA = [TimeSpan]::FromMilliseconds($initETA)

Write-Host $HorizontalLine
"Measurement of $KeysCount profile-ish scripts" `
    + " with total $totalCount` tests." `
    + ($Keys | ForEach-Object { "`n`t- $_" })
| Write-Host
Write-Host ""

$percentFactor = 100.0 / $totalCount
$padding = [Math]::Log10($totalCount + 0.1)
$padding = [int]([Math]::Ceiling($padding))
$padding += 1 # just for nicer space before

$benchmarkingWatch = [Diagnostics.Stopwatch]::StartNew()

$i = 1
foreach ($key in $keysOrder) {
    $completed = $i * $percentFactor
    if ($completed -lt 1) { $completed = 1 }
    if ($completed -gt 100) { $completed = 100 }

    $elapsedMs = $benchmarkingWatch.ElapsedMilliseconds
    $leftMs = ([double]$elapsedMs / $i) * ($totalCount - $i)
    $left = [Timespan]::FromMilliseconds($leftMs)
    $left = $left.ToString("G")
    if ($left.Length -gt 12) {
        $left = $left.Substring(0, 12)
    }

    $total = $elapsedMs + $leftMs
    $diff = $total - $initETA.TotalMilliseconds
    $diff = $diff / 1000.0

    $eta = $diff -lt 0 ? " " : " +"
    $eta = $left + $eta + $diff.ToString("f1")

    $iter = "$i".PadLeft($padding)
    $status = "$iter. #$totalCount $eta | Runnin: $key"
    Write-Progress -Activity $id -Status $status `
        -PercentComplete $completed

    $scriptTarget = $TestScripts
    | Where-Object { $_.Key -eq $key }
    | ForEach-Object { $_.Script }
    | Select-Object -Unique

    $ret = Start-PwshWith $scriptTarget
    $times = $Profiled[$key]
    $Profiled[$key] = $times + $ret
    $i++
}

Write-Progress -Activity $id -Completed
$benchmarkingElapsed = $benchmarkingWatch.Elapsed


foreach ($key in $Keys) {
    $times = $Profiled[$key]
    | ForEach-Object { $_.ms }

    Write-Host $HorizontalLine
    Write-Host "Times for: $key"
    $stats = $times
    | Measure-Object -AllStats

    $len = $stats.Count
    $min = $stats.Minimum
    $max = $stats.Maximum
    $avg = [int][Math]::Round($stats.Average)
    $stdev = [int][Math]::Round($stats.StandardDeviation)
    "`tcount $len | [ms]" `
        + "  min:$min  max:$max" `
        + "  avg:~$avg  stdev:~$stdev"
    | Write-Host

    $i = 0
    $times = $times | ForEach-Object {
        $i++
        return ($i % 10 -eq 0) `
            ? "$_,`n`t" `
            : "$_, "
    }

    $times = [string]::Concat($times)
    $times = $times.TrimEnd(" ", ",")
    Write-Host "`t$times"
}


Write-Host ""
Write-Host $HorizontalLine

$totalCount += $KeysCount
Write-Host "Tested $KeysCount profile-ish scripts with $totalCount total runs."

if ($ToCSV.IsPresent) {
    # $now = Get-Date -Format "yyMMdd-HHmmss"
    # $file = Join-Path $PWD "results-$now.csv"
    $file = "pwsh-profile-results.csv"
    function Get-CSVResultRow ($iteration) {
        $row = [ordered]@{}
        foreach ($key in $Keys) {
            $it = $Profiled[$key][$iteration]
            $row.Add("$key(nth)", $it.nth)
            $row.Add("$key(ms)", $it.ms)
        }

        return $row
    }

    0..($Iterations - 1)
    | ForEach-Object { Get-CSVResultRow $_ }
    | Export-Csv -Path $file -Delimiter ";"

    Write-Host "`t- Results saved into: $file"
}

Write-Host ""
Write-Host "Whole benchmark executed within: $($TotalWatch.Elapsed)"
Write-Host "`t  * Warmup elapsed time: $warmupsElapsed"
Write-Host "`t    * Benchmarking time: $benchmarkingElapsed"
Write-Host "`t       * Estimated time: $initETA"
Write-Host ""
