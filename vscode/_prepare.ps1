$vsCodePath = Join-Path $env:USERPROFILE "AppData\Roaming\Code\User"
$oneDriveBasePath = Join-Path $env:USERPROFILE "OneDrive"
$oneDrivePath = Join-Path $oneDriveBasePath "Configurations\VS Code"
$currentPath = (Get-Item -Path ".\" -Verbose).FullName

Function InstallExtensionsFrom($sourceFile) {
    $extensions = Join-Path $currentPath $sourceFile
    $extensions = Get-Content $extensions `
        | ForEach-Object { $_.trim() } `
        | Where-Object { $_ -ne "" } `
        | Where-Object { -not($_.StartsWith("#")) }

    $installArgs = $extensions | ForEach-Object { "--install-extension $_" }
    $command = "code $($installArgs -join " ")"

    Invoke-Expression $command
}

Function MakeLinkFor($fileName, $wherePath) {
    $sourcePath = Join-Path $currentPath $fileName
    $linkPath = Join-Path $wherePath $fileName

    If (Test-Path $linkPath) {
        $timestamp = Get-Date -Format yyyyMMdd-HHmmss
        $newPath = "$linkPath.$timestamp.bak"
        Rename-Item -Path $linkPath -NewName $newPath
        Write-Output "Existing file was renamed to: $newPath"
    }

    cmd.exe /C mklink /H "$linkPath" "$sourcePath"
}

Write-Output "Prepareation for VS Code in a version:"
code --version

Write-Output "`n  1. Installing extensions:"
InstallExtensionsFrom "extensions.txt"

Write-Output "`n  2. Linking configuration files to the VS Code:"
MakeLinkFor "keybindings.json" $vsCodePath
MakeLinkFor "settings.json" $vsCodePath

Write-Output "`n  3. Linking configuration files to the OneDrive:"
IF (Test-Path $oneDriveBasePath) {
    MakeLinkFor "keybindings.json" $oneDrivePath
    MakeLinkFor "settings.json" $oneDrivePath
}
Else {
    Write-Output "`t OneDrive synchronization skipped due unknown OneDrive location..."
}

Write-Output "`n  4. Done."
