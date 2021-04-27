Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

function CouldNotFindForConfig ($name, $fullPath) {
    $notFound = -not (Test-Path $fullPath)
    if ($notFound) {
        Write-Output ">> Could not find '$name' at: '$fullPath', configuration skipped."
    }

    return $notFound
}

function EnsurePathExists ($path) {
    if (-not (Test-Path $path)) {
        throw "Could not find anything under path: $path"
    }
}

function LoadLinesFrom ($sourceDir, $sourceFile) {
    $sourceFilePath = Join-Path $sourceDir $sourceFile
    EnsurePathExists $sourceFilePath

    return Get-Content $sourceFilePath -Force `
    | ForEach-Object { $_.trim() } `
    | Where-Object { $_ -ne "" } `
    | Where-Object { -not $_.StartsWith("#") }
}

function LoadMetaLinesFrom ($sourceDir, $sourceFile) {
    return LoadLinesFrom $sourceDir $sourceFile `
    | ForEach-Object {
        $parts = $_.Split("|")
        $props = [ordered]@{
            Metadata = $parts[0];
            Value    = $parts[1];
        }
        return New-Object PSObject -Property $props
    }
}

function AreSameFiles ($leftFilePath, $rightFilePath) {
    $left = Get-Content $leftFilePath -Force
    $right = Get-Content $rightFilePath -Force
    if (Compare-Object $left $right) {
        return $false
    }
    else {
        return $true
    }
}

function RenameAsTimestampedBackup ($filePath) {
    $timestamp = Get-Date -Format yyyyMMdd-HHmmss
    $newPath = "$filePath.$timestamp.bak"

    Rename-Item -Path $filePath -NewName $newPath -Force
    Write-Output "Existing path had been renamed as backup: '$newPath'."
}

function MakeHardLinkTo ($targetDir, $sourceDir, $fileName, $backup = $true) {
    $linkedPath = Join-Path $targetDir $fileName
    $sourcePath = Join-Path $sourceDir $fileName
    EnsurePathExists $sourcePath

    if (Test-Path $linkedPath) {
        if (-not $backup) {
            Remove-Item -Path $linkedPath -Force
            Write-Output "Existing file ('$fileName') had been deleted, linked file will replace it."
        }
        elseif (AreSameFiles $linkedPath $sourcePath) {
            Remove-Item -Path $linkedPath -Force
            Write-Output "Same existing file ('$fileName') will be replaced by hard link."
        }
        else {
            RenameAsTimestampedBackup $linkedPath
        }
    }

    cmd.exe /C mklink /H "$linkedPath" "$sourcePath"
}

function ReplaceWitBackupAt ($targetDir, $sourceDir, $fileName) {
    $targetPath = Join-Path $targetDir $fileName
    $sourcePath = Join-Path $sourceDir $fileName
    EnsurePathExists $sourcePath

    if (Test-Path $targetPath) {
        if (AreSameFiles $targetPath $sourcePath) {
            Write-Output "Target file ('$fileName') is same as source - Replacement skipped."
            return
        }
        else {
            RenameAsTimestampedBackup $targetPath
        }
    }

    Copy-Item -Path $sourcePath -Destination $targetPath -Force
}

function SetAttributesOf ($path, [System.IO.FileAttributes]$attributes) {
    EnsurePathExists $path

    $item = Get-Item $path -Force
    $value = $item.Attributes
    $item.Attributes = $value -bOR $attributes
}
