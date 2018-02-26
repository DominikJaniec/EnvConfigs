. ".\common.ps1"

function TextFilesExtensionsFrom($sourceFile) {
    return LoadLinesFrom $PSScriptRoot $sourceFile `
        | ForEach-Object { "$_".Trim() }
}

#######################################################################################

$extensions = TextFilesExtensionsFrom "extensions.txt"
$total = @($extensions).Count
Write-Output "`n  1. Requested $total extensions of files which will be treated as text-based files."

$counter = 1
foreach ($ext in $extensions) {
    $setupExpression = "assoc $ext=txtfile"
    Write-Output "`n  2. [$counter/$total] executing: '$setupExpression'"
    cmd.exe /C $setupExpression
    $counter += 1
}

Write-Output ""
Write-Output "`System preparation: Done."
