$ExpectedPath_ProcessExplorer = "C:\ProgramData\chocolatey\lib\procexp\tools\procexp.exe"
$ExpectedPath_GitBash = "C:\Program Files\Git\git-bash.exe"
$ExpectedPath_ConEmu = "C:\Program Files\ConEmu\ConEmu64.exe"

function CouldNotFindForConfig ($name, $fullPath) {
    $notFound = -not(Test-Path $fullPath)
    if ($notFound) {
        Write-Output ">> Could not find '$name' at: '$fullPath', configuration skipped."
    }

    return $notFound
}

function EnsureFileExists ($filePath) {
    if (-not(Test-Path $filePath)) {
        throw "Could not find file under path: $filePath"
    }
}

function LoadLinesFrom ($sourceDir, $sourceFile) {
    $sourceFilePath = Join-Path $sourceDir $sourceFile
    EnsureFileExists $sourceFilePath

    return Get-Content $sourceFilePath `
        | ForEach-Object { $_.trim() } `
        | Where-Object { $_ -ne "" } `
        | Where-Object { -not($_.StartsWith("#")) }
}

function FilesAreSame ($leftFilePath, $rightFilePath) {
    $left = Get-Content $leftFilePath
    $right = Get-Content $rightFilePath
    $diff = Compare-Object $left $right
    return [string]::IsNullOrWhiteSpace($diff)
}

function MakeHardLinkTo ($targetDir, $sourceDir, $fileName, $backup = $true) {
    $linkedPath = Join-Path $targetDir $fileName
    $sourcePath = Join-Path $sourceDir $fileName
    EnsureFileExists $sourcePath

    if (Test-Path $linkedPath) {
        if (-not($backup)) {
            Remove-Item -Path $linkedPath
            Write-Output "Existing file had been deleted, linked file will replace it."
        }
        elseif (FilesAreSame $linkedPath $sourcePath) {
            Remove-Item -Path $linkedPath
            Write-Output "Same existing file will be replaced by hard link."
        }
        else {
            $timestamp = Get-Date -Format yyyyMMdd-HHmmss
            $newPath = "$linkedPath.$timestamp.bak"
            Rename-Item -Path $linkedPath -NewName $newPath
            Write-Output "Existing file had been renamed as: '$newPath'."
        }
    }

    cmd.exe /C mklink /H "$linkedPath" "$sourcePath"
}
