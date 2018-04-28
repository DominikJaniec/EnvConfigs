. ".\common.ps1"

$ReposDirectory = Join-Path $Env:USERPROFILE "Repos"
$ProcessExplorer = Join-Path $Env:ChocolateyInstall "lib\procexp\tools\procexp.exe"

function TextFilesExtensionsFrom($sourceFile) {
    return LoadLinesFrom $PSScriptRoot $sourceFile `
        | ForEach-Object { "$_".Trim() }
}

function SetTextFilesExtensions () {
    $extensions = TextFilesExtensionsFrom "extensions.txt"
    $total = @($extensions).Count
    Write-Output "`n>> Requested $total extensions of files which will be treated as text-based files."

    $counter = 1
    foreach ($ext in $extensions) {
        $setupExpression = "assoc $ext=txtfile"
        Write-Output ">> >> [$counter/$total] executing: '$setupExpression'"
        cmd.exe /C $setupExpression
        $counter += 1
    }

    Write-Output ">> All $total files extensions have been set as text files."
}

function ScheduleProcessExplorer () {
    Write-Output "`n>> Scheduling autostart of Process Explorer on user logon."
    if (CouldNotFindForConfig "Process Explorer" $ProcessExplorer) {
        return
    }

    $scheduleName = "Process Explorer - Autostart"
    Write-Output ">> Looking for schedule-task: '$scheduleName'..."
    cmd.exe /C "schtasks /Query /TN `"$scheduleName`""

    if ($LASTEXITCODE -ne 0) {
        Write-Output ">> Scheduling new task: '$scheduleName'"
        cmd.exe /C "schtasks /Create /SC ONLOGON /TN `"$scheduleName`" /TR `"$ProcessExplorer /t`""
    }

    Write-Output ">> Process Explorer scheduled to autostart on logon."
}

function PinToQuickAccess ($directoryPath) {
    $o = new-object -com shell.application
    $o.Namespace($directoryPath).Self.InvokeVerb("pintohome")
}

function SetupWindowsExplorer () {
    Write-Output "`n>> Fixing Windows Explorer configuration..."
    $regExplorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
    Set-ItemProperty $regExplorer ShowFrequent 0
    Set-ItemProperty $regExplorer ShowRecent 0

    $regExplorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty $regExplorerAdvanced HideFileExt 0
    Set-ItemProperty $regExplorerAdvanced ShowSuperHidden 1
    Set-ItemProperty $regExplorerAdvanced LaunchTo 1

    Write-Output ">> Pinning common directory to the Quick Access..."
    PinToQuickAccess($Env:USERPROFILE)
    PinToQuickAccess($ReposDirectory)

    Write-Output ">> Windows Explorer has been configured."
}

function SetupContextMenuWithBash () {
    Write-Output "`n>> Configuring Windows context menu with Bash via ConEmu."
    if (CouldNotFindForConfig "ConEmu" $ExpectedPath_ConEmu -or `
            CouldNotFindForConfig "GitBash" $ExpectedPath_GitBash) {
        return
    }

    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null
    $regDirectories = @("HKCR:\Directory\shell", "HKCR:\Directory\Background\shell")

    foreach ($regKeyBase in $regDirectories) {
        $regKey = "$regKeyBase\ViaConEmu_GitBash"
        if (Test-Path $regKey) {
            continue
        }

        New-Item $regKey -Value "Open &Bash here" | Out-Null
        Set-ItemProperty $regKey Icon $ExpectedPath_GitBash

        $command = "`"$ExpectedPath_ConEmu`" -NoSingle -Dir `"%1`" -run {Bash::Git bash}"
        New-Item "$regKey\command" -Value $command | Out-Null

        Write-Output ">> >> Windows context menu for Bash created at: '$regKey'."
    }

    & $ExpectedPath_ConEmu -UpdateJumpList -run exit
    # & $ExpectedPath_ConEmu -UpdateJumpList -Exit
    # TODO : https://github.com/Maximus5/ConEmu/issues/1478
    Write-Output ">> Windows Bash via ConEmu integration done."
}

function SetupReposFolderIcon {
    Write-Output "`n>> Setting up 'Repos' directory's icon..."
    if (CouldNotFindForConfig "Repos directory" $ReposDirectory) {
        return
    }

    $source = Join-Path $PSScriptRoot "template_Repos"
    $iconFile = "GitDirectory.ico"
    $configFile = "desktop.ini"

    ReplaceWitBackupAt $ReposDirectory $source $iconFile
    ReplaceWitBackupAt $ReposDirectory $source $configFile
    HideIt (Join-Path $ReposDirectory $iconFile)
    HideIt (Join-Path $ReposDirectory $configFile)

    Write-Output ">> 'Repos' folder's appearance changed."
}

#######################################################################################

SetTextFilesExtensions
ScheduleProcessExplorer
SetupWindowsExplorer
SetupContextMenuWithBash
SetupReposFolderIcon

Write-Output "`n>> System preparation: Done."
