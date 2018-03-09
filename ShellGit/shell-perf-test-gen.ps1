# This file will generate "test file" to check performance of Bash Shell.
#
# Created file will contains multiple empty lines, to gather more preciuse
# information about: how long it take to render `PS1` Bash's prompt varaible.
# Reslut will be stored as row in a CSV file.

$testContentFile = "$PSScriptRoot\shell-perf-test.txt"

$iterNum = 16
$testName = "shell_performance_test_name"
$result = "perf-tests-result.csv"

$varTestName = "__perftestname"
$varStartTime = "__timestamp"
$getTimeMsCall = "``date +`"%s%3N`"``"
$avgExecutionExpr = "($getTimeMsCall - `${$varStartTime}) / $iterNum"

$header = "export $varTestName=`"$testName`"; export $varStartTime=$getTimeMsCall"
$footer = "echo `"`${$varTestName};`$(( $avgExecutionExpr )) ms;* $iterNum`" >> $result"

Write-Output $header > $testContentFile
for ($i = 1; $i -lt $iterNum; $i++) {
    Write-Output "" >> $testContentFile
}
Write-Output $footer >> $testContentFile
