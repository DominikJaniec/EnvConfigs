param ([int]$Iterations = 42, [switch]$SkipJustPwsh, [switch]$SkipJustModule)

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
$linesOfKeys = $Keys | ForEach-Object { "`n`t- $_" }
"Benchmarking $KeysCount profile-ish scripts" `
    + " with $Iterations`x iterations each." `
    + $linesOfKeys
| Write-Host

function Show-ProfileScriptLines ($Key, $Lines) {
    Write-Host $HorizontalLine
    Write-Host "Rendered profile script for '$Key':"
    foreach ($line in $Lines) {
        Write-Host "`t> $line"
    }
}

function Start-PwshWith ($ProfileScript) {
    $command = "$ProfileScript"
    $bytes = [Text.Encoding]::Unicode.GetBytes($command)
    $codedCommand = [Convert]::ToBase64String($bytes)

    $watch = [Diagnostics.Stopwatch]::StartNew()
    $out = pwsh -NoLogo -NoProfile -NonInteractive `
        -EncodedCommand $codedCommand `
    | Out-String

    $exit = $?
    $ms = $watch.ElapsedMilliseconds
    return , $exit, $ms, $out.Trim()
}

function Start-PwshScriptWarmup ($Key, $ScriptBlock) {
    Write-Host $HorizontalLine
    Write-Host "Script warmup of '$Key':"

    $ret = Start-PwshWith $ScriptBlock
    $exit = $ret[0]
    $ms = $ret[1]
    $out = $ret[2]

    $Warmups[$Key] = $ms
    Write-Host "`t *  successfully exited: $exit, within $ms [ms]"
    Write-Host $(
        [String]::IsNullOrWhiteSpace($out) `
            ? "`t *  no-output" `
            : $out
    )

    if (-not $exit) {
        Write-Error "Got $exit from '$Key'"
    }

    Write-Host ""
}


$Warmups = @{}
$ProfilingScripts = $Keys | ForEach-Object {
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

$ProfiledTimes = @{}
foreach ($key in $Keys) {
    $times = New-Object Collections.Generic.List[int]
    $times.Add($Warmups[$key])

    $ProfiledTimes[$key] = $times
}


Write-Host ""
$id = "Benchmarking"

function Get-ProfilingKeysOrder ($Keys) {
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


$keysOrder = @(Get-ProfilingKeysOrder $Keys)
$Iterations-- # due to warmup runs

$totalCount = $Iterations * $KeysCount
$percentFactor = 100.0 / $totalCount
$padding = [Math]::Log10($totalCount + 0.1)
$padding = [int]([Math]::Ceiling($padding))
$padding += 1 # just for nicer space before

$i = 1
foreach ($key in $keysOrder) {
    $completed = $i * $percentFactor
    if ($completed -lt 1) { $completed = 1 }
    if ($completed -gt 100) { $completed = 100 }

    $iter = "$i".PadLeft($padding)
    $status = "$iter. [$totalCount] Runnin: $key"
    Write-Progress -Activity $id -Status $status `
        -PercentComplete $completed

    $scriptTimes = $ProfiledTimes[$key]
    $scriptTarget = $ProfilingScripts `
    | Where-Object { $_.Key -eq $key } `
    | ForEach-Object { $_.Script } `
    | Select-Object -Unique

    $ret = Start-PwshWith $scriptTarget
    $ms = $ret[1]

    $scriptTimes.Add($ms)
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
