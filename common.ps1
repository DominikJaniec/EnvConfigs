Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

$ExpectedPath_GitBash = Join-Path $Env:PROGRAMFILES "Git\git-bash.exe"
$ExpectedPath_ConEmu = Join-Path $Env:PROGRAMFILES "ConEmu\ConEmu64.exe"
$ProfilePath_Repos = Join-Path $Env:USERPROFILE "Repos"
$ProfilePath_VMs = Join-Path $Env:USERPROFILE "Virtual Machines"

function CouldNotFindForConfig ($name, $fullPath) {
    $notFound = -not(Test-Path $fullPath)
    if ($notFound) {
        Write-Output ">> Could not find '$name' at: '$fullPath', configuration skipped."
    }

    return $notFound
}

function EnsurePathExists ($path) {
    if (-not(Test-Path $path)) {
        throw "Could not find anything under path: $path"
    }
}

function LoadLinesFrom ($sourceDir, $sourceFile) {
    $sourceFilePath = Join-Path $sourceDir $sourceFile
    EnsurePathExists $sourceFilePath

    return Get-Content $sourceFilePath -Force `
        | ForEach-Object { $_.trim() } `
        | Where-Object { $_ -ne "" } `
        | Where-Object { -not($_.StartsWith("#")) }
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

function RenameAsTimestamptedBackup ($filePath) {
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
        if (-not($backup)) {
            Remove-Item -Path $linkedPath -Force
            Write-Output "Existing file ('$fileName') had been deleted, linked file will replace it."
        }
        elseif (AreSameFiles $linkedPath $sourcePath) {
            Remove-Item -Path $linkedPath -Force
            Write-Output "Same existing file ('$fileName') will be replaced by hard link."
        }
        else {
            RenameAsTimestamptedBackup $linkedPath
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
            RenameAsTimestamptedBackup $targetPath
        }
    }

    Copy-Item -Path $sourcePath -Destination $targetPath -Force
}

function HideIt ($path) {
    EnsurePathExists $path
    Get-Item $path -Force `
        | ForEach-Object {
        $_.Attributes = $_.Attributes -bor "Hidden"
    }
}

function DumpObject ($obj, $name = "Given object") {
    if ($obj -eq $null) {
        Write-Host "===// Dump '$name' as NULL ===\\"
    }
    else {
        Write-Host "===// Dump '$name' of type: $($obj.GetType())"
        Write-Host ($obj | Format-Table | Out-String) -NoNewline
        Write-Host "===\\"
    }
}
