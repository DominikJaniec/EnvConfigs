function EnsureFileExists ($filePath) {
    if (-not(Test-Path $filePath)) {
        throw "Could not find file under path: $filePath"
    }
}

function LoadLinesFrom($sourceDir, $sourceFile) {
    $sourceFilePath = Join-Path $sourceDir $sourceFile
    EnsureFileExists $sourceFilePath

    return Get-Content $sourceFilePath `
        | ForEach-Object { $_.trim() } `
        | Where-Object { $_ -ne "" } `
        | Where-Object { -not($_.StartsWith("#")) }
}

function MakeHardLinkTo($targetDir, $sourceDir, $fileName, $backup = $true) {
    $linkedPath = Join-Path $targetDir $fileName
    $sourcePath = Join-Path $sourceDir $fileName
    EnsureFileExists $sourcePath

    if (Test-Path $linkedPath) {
        if ($backup) {
            $timestamp = Get-Date -Format yyyyMMdd-HHmmss
            $newPath = "$linkedPath.$timestamp.bak"
            Rename-Item -Path $linkedPath -NewName $newPath
            Write-Output "Existing file had been renamed as: '$newPath'."
        }
        else {
            Remove-Item -Path $linkedPath
            Write-Output "Existing file had been deleted, linked file will replace it."
        }
    }

    cmd.exe /C mklink /H "$linkedPath" "$sourcePath"
}
