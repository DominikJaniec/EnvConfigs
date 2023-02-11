param ([int]$Iterations = 13, [switch]$SkipJustPwsh)

$TotalWatch = [Diagnostics.Stopwatch]::StartNew()
$HorizontalLine = [string]::new("_", 69)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3.0


# Unique keys for each version of profile-ish script:
$Keys = "alpha", "beta", "gamma"

# Render profile-ish script lines based on key:
function Get-ProfileScriptLines ($Key) {
    @("Write-Host `"Hello '$Key'!`"")
}


# Special case of "just" PowerShell run:
$JustPwshKey = "just-pwsh"
$JustPwshLines = @("exit 0")
if (-not $SkipJustPwsh.IsPresent) {
    $Keys = @($JustPwshKey) + $Keys
}

$KeysCount = $Keys.Length
"Benchmarking $KeysCount profile-ish scripts" `
    + " with $Iterations`x iterations each." `
| Write-Host

function Show-ProfileScriptLines ($Key, $Lines) {
    Write-Host $HorizontalLine
    Write-Host "Rendered profile script for '$Key':"
    foreach ($line in $Lines) {
        Write-Host "`t> $line"
    }
}

$ProfilingScripts = $Keys | ForEach-Object {
    $lines = $_ -ne $JustPwshKey `
        ? @(Get-ProfileScriptLines -Key $_) `
        : @($JustPwshLines)

    Show-ProfileScriptLines $_ $lines

    $ps = $lines -join "`n"
    [PSObject]@{
        Key    = $_;
        Script = $ps
    }
}

$ProfiledTimes = @{}
foreach ($key in $Keys) {
    $times = New-Object Collections.Generic.List[int]
    $ProfiledTimes[$key] = $times
}


Write-Host ""
$id = "Benchmarking"

function Get-ProfilingKeysOrder ($Keys) {
    $ith = 0
    $level = 1

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

function Measure-Script ($ProfileScript, $MeasuredTimes) {
    $command = "$ProfileScript"
    $bytes = [Text.Encoding]::Unicode.GetBytes($command)
    $codedCommand = [Convert]::ToBase64String($bytes)

    $watch = [Diagnostics.Stopwatch]::StartNew()
    pwsh -NoProfile -NoLogo -NonInteractive `
        -EncodedCommand $codedCommand `
    | Out-Null

    $MeasuredTimes.Add($watch.ElapsedMilliseconds)
}


$totalCount = $Iterations * $KeysCount
$percentFactor = 100.0 / $totalCount
$padding = [Math]::Log10($totalCount + 0.1)
$padding = [int]([Math]::Ceiling($padding))
$padding += 1 # just for nicer space before

$i = 1
$keysOrder = @(Get-ProfilingKeysOrder $Keys)
foreach ($key in $keysOrder) {
    $completed = $i * $percentFactor
    if ($completed -lt 1) { $completed = 1 }
    if ($completed -gt 100) { $completed = 100 }

    $iter = "$i".PadLeft($padding)
    $status = "$iter. Runnin: $key"
    Write-Progress -Activity $id -Status $status `
        -PercentComplete $completed

    $scriptTimes = $ProfiledTimes[$key]
    $scriptTarget = $ProfilingScripts `
    | Where-Object { $_.Key -eq $key } `
    | ForEach-Object { $_.Script } `
    | Select-Object -Unique

    Measure-Script $scriptTarget $scriptTimes
    $i++
}

Write-Progress -Activity $id -Completed


foreach ($key in $Keys) {
    $times = $ProfiledTimes[$key] `
    | ForEach-Object { [int]$_ }

    Write-Host $HorizontalLine
    Write-Host "Times for: $key"
    $stats = $times `
    | Measure-Object -AllStats

    $len = $stats.Count
    $min = $stats.Minimum
    $max = $stats.Maximum
    $avg = [int][Math]::Round($stats.Average)
    $stdev = [int][Math]::Round($stats.StandardDeviation)
    "`tcount $len | [ms]" `
        + "  min:$min  max:$max" `
        + "  avg:~$avg  stdev:~$stdev" `
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
"Whole benchmark executed within:" `
    + " $($TotalWatch.Elapsed)`n" `
| Write-Host
