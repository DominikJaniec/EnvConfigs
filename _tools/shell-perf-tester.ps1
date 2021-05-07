# This file will generate "test-spammer file" to check performance of target Shell.
# Created file will contains multiple empty lines, to spam terminal, to gather
# information about: how long it take to render Prompt under current conditions.
# Result will be stored as row in a CSV file.

param(
    $Iterations = 42,
    [switch]$Bash,
    [switch]$Pwsh
)

if ($Iterations -le 0) {
    throw "Should be positive int: -Iterations"
}

if (-not ($Bash.IsPresent -or $Pwsh.IsPresent) `
        -or ($Bash.IsPresent -and $Pwsh.IsPresent)) {
    throw "Chose one target: -Bash or -Pwsh"
}


$spammerFile = "shell-perf-spammer-src.txt"
$measureFile = "shell-perf-spam-tests.csv"


$varStartTime = "__perftest_timestamp"
$csvHeaders = "AverageRenderMs;Iterations"
$preCommand = "exit -1"
$postCommand = "exit -1"

if ($Bash.IsPresent) {
    $getTimeMsCall = "``date +`"%s%3N`"``"
    $avgExecutionExpr = "($getTimeMsCall - `${$varStartTime}) / $Iterations"

    $preCommand = "echo `"$csvHeaders`" >> $measureFile" `
        + "; export $varStartTime=$getTimeMsCall"

    $postCommand = `
        "echo `"`$(( $avgExecutionExpr ));$Iterations`" >> $measureFile"
}

if ($Pwsh.IsPresent) {
    $avgExecutionExpr = "[int]((((Get-Date) - `$$varStartTime).TotalMilliseconds) / $Iterations)"

    $preCommand = "Write-Output `"$csvHeaders`"" `
        + " | Out-File $measureFile -Encoding ascii -Append" `
        + "; `$$varStartTime=Get-Date"

    $postCommand = "Write-Output `"`$($avgExecutionExpr);$Iterations`"" `
        + " | Out-File $measureFile -Encoding ascii -Append"
}

### Render Spammer file:

Write-Output $preCommand > $spammerFile
1..$Iterations | ForEach-Object {
    Write-Output "" >> $spammerFile
}
Write-Output $postCommand >> $spammerFile
