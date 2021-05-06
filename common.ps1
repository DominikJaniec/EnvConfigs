Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

function CouldNotFindForConfig ($what, $path) {
    $notFound = -not (Test-Path $path)
    if ($notFound) {
        Write-Output ">> Could not find '$what' at: '$path', configuration skipped."
    }

    return $notFound
}

function CreateMissingDirectory ($dirPath) {
    if (Test-Path $dirPath -PathType Leaf) {
        throw "There is already a File under: '$dirPath'."
    }

    if (-not (Test-Path $dirPath -PathType Container)) {
        New-Item $dirPath -ItemType Directory -Force `
        | Out-Null
    }
}

function EnsurePathExists ($path, [switch]$AsFile) {
    if (-not (Test-Path $path)) {
        throw "Could not find anything under path: '$path'."
    }

    if ($asFile.IsPresent) {
        if (-not (Test-Path $path -PathType Leaf)) {
            throw "Expecting to find a File under: '$path'."
        }
    }
}

function LoadLinesFrom ($sourceDir, $sourceFile) {
    $sourceFilePath = Join-Path $sourceDir $sourceFile
    EnsurePathExists $sourceFilePath -AsFile

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
    function GetRaw ($filePath) {
        EnsurePathExists $filePath -AsFile

        if ($PSVersionTable.PSVersion.Major -ge 6) {
            return Get-Content $filePath -AsByteStream -Force
        }
        else {
            return Get-Content $filePath -Encoding Byte -Force
        }
    }

    try {
        $left = GetRaw $leftFilePath
        $right = GetRaw $rightFilePath
        $result = Compare-Object $left $right
        return $null -eq $result
    }
    catch [System.IO.DirectoryNotFoundException] {
        # Note: If file exist, but while loading we got this exception,
        #       we can assume, that it is broken/dead Symbolic-Link.
        return $false
    }
}

function RenameAsTimestampedBackup ($filePath) {
    $timestamp = Get-Date -Format yyyyMMdd-HHmmss
    $newPath = "$filePath.$timestamp.bak"

    Rename-Item $filePath -NewName $newPath -Force
    Write-Output "Existing path had been renamed as backup: '$newPath'."
}

function MakeSymLinksAt ($targetDir, $sourceDir, $files) {
    function SymLinkFile ($fileName) {
        $targetPath = Join-Path $targetDir $fileName
        $sourcePath = Join-Path $sourceDir $fileName
        EnsurePathExists $sourcePath -AsFile

        if (Test-Path $targetPath -PathType Container) {
            throw "Linking is only allowed between files." `
                + " Cannot make link at '$targetPath'."
        }

        if (Test-Path $targetPath) {
            Write-Output "Existing file '$fileName' will be replaced."
            if (AreSameFiles $targetPath $sourcePath) {
                Remove-Item $targetPath -Force
            }
            else {
                RenameAsTimestampedBackup $targetPath
            }
        }

        New-Item $targetPath -ItemType SymbolicLink -Value $sourcePath `
        | Out-Null

        Write-Output "File Symbolic-Link has been created:"
        Write-Output "`t At '$(Resolve-Path $targetPath)'"
        Write-Output "`t => '$(Resolve-Path $sourcePath)'"
    }

    Write-Output "Making Symbolic-Links at '$targetDir' into '$sourceDir'..."
    EnsurePathExists $targetDir

    (@() + $files) | ForEach-Object {
        SymLinkFile $_
    }
}

function MakeHardLinkTo ($targetDir, $sourceDir, $fileName, $backup = $true) {
    $linkedPath = Join-Path $targetDir $fileName
    $sourcePath = Join-Path $sourceDir $fileName
    EnsurePathExists $sourcePath

    if (Test-Path $linkedPath) {
        if (-not $backup) {
            Remove-Item -Path $linkedPath -Force
            Write-Output "Existing file '$fileName' had been deleted, linked file will replace it."
        }
        elseif (AreSameFiles $linkedPath $sourcePath) {
            Remove-Item -Path $linkedPath -Force
            Write-Output "Same existing file '$fileName' will be replaced by hard link."
        }
        else {
            RenameAsTimestampedBackup $linkedPath
        }
    }

    cmd.exe /C mklink /H "$linkedPath" "$sourcePath"
}

function MakeHardLinkInto ($targetDir, $sourceDir, $files, [switch]$back) {
    $backupTarget = $true
    if ($back.IsPresent) {
        $tempSwap = $targetDir
        $targetDir = $sourceDir
        $sourceDir = $tempSwap
        $backupTarget = $false
    }

    Write-Output "Making Hard-Link into '$targetDir' from '$sourceDir'..."
    (@() + $files) | ForEach-Object {
        MakeHardLinkTo $targetDir $sourceDir $_ $backupTarget
    }
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
