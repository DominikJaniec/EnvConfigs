Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues["*:ErrorAction"] = "Stop"


function LogLines ($lines, $lvl = 1, [switch]$Bar) {
    if ($lvl -lt 1) {
        throw "Log indentation level must be greater than 0."
    }

    if ($Bar.IsPresent) {
        $barLine = New-Object `
            -TypeName "System.String" `
            -ArgumentList @('#', 69)

        Write-Output "`n$barLine"
    }

    (@() + $lines) | ForEach-Object {
        $line = $_
        1..$lvl | ForEach-Object {
            $line = ">> " + $line
        }

        Write-Output $line
    }
}

function LogLines2 ($lines, [switch]$Bar) {
    LogLines $lines -lvl 2 -Bar:$Bar.IsPresent
}

function LogLines3 ($lines, [switch]$Bar) {
    LogLines $lines -lvl 3 -Bar:$Bar.IsPresent
}

function CouldNotFindForConfig ($what, $path) {
    $notFound = -not (Test-Path $path)
    if ($notFound) {
        Write-Output ">> Could not find '$what' at: '$path'" `
            + ", configuration will be skipped."
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
    | ForEach-Object { "$_".Trim() } `
    | Where-Object { $_ -ne "" } `
    | Where-Object { -not $_.StartsWith("#") }
}

function LoadMetaLinesFrom ($sourceDir, $sourceFile) {
    return LoadLinesFrom $sourceDir $sourceFile `
    | ForEach-Object {
        $line = "$_"
        $idx = $line.IndexOf("|")
        if ($idx -le 0) {
            throw "Cannot parse encountered line as 'Meta-Line'" `
                + ", unexpected '|' character position. Line:`n$line"
        }

        $meta = $line.Substring(0, $idx)
        $value = $line.Substring($idx + 1)
        $props = [ordered]@{
            Metadata = $meta;
            Value    = $value
        }

        return New-Object PSObject -Property $props
    }
}

function LoadMetaLinesGroupedFrom ($sourceDir, $sourceFile) {
    LoadMetaLinesFrom $sourceDir $sourceFile `
    | Group-Object -Property Metadata `
    | ForEach-Object {
        $values = $_.Group `
        | ForEach-Object Value

        $props = [ordered]@{
            Metadata = $_.Name;
            Values   = $values
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
        #       we can assume that it is a broken/dead Symbolic-Link.
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

    Write-Output "Making Symbolic-Links at '$targetDir'"
    Write-Output "`t into directory '$sourceDir'..."

    EnsurePathExists $targetDir
    (@() + $files) | ForEach-Object {
        SymLinkFile $_
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

function ImportIntoRegister ($what, $regDir, $regFile) {
    LogLines -lvl 2 "Importing $what into Windows Register:"
    $regPath = Join-Path $regDir $regFile
    REG IMPORT $regPath

    if ($LASTEXITCODE -ne 0) {
        throw "Could not reg-import $what."
    }
}

function ConfigUnderRestartedProcess ($what, $description, $processPath, $configurationBlock) {
    LogLines -Bar "Configuring $what`: $description..."
    if (CouldNotFindForConfig $what $processPath) {
        return
    }

    EnsurePathExists $processPath -AsFile
    LogLines -lvl 2 "Killing process: $processPath"

    Get-Process `
    | Where-Object { $_.Path -eq $processPath } `
    | ForEach-Object { Stop-Process -Id $_.Id }

    Invoke-Command -ScriptBlock $configurationBlock

    LogLines -lvl 2 "Starting $what process..."
    Start-Process -FilePath $processPath

    LogLines "$what configured successfully."
}
