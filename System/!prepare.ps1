param(
    [switch]$AssocTxtfile,
    [switch]$CleanUpCtxMenu,
    [switch]$PrepareExplorer
)

. ".\common.ps1"


$ProfilePath_Repos = Join-Path $Env:USERPROFILE "Repos"
$ExpectedPath_ProcessExplorer = Join-Path $Env:ChocolateyInstall "lib\procexp\tools\procexp.exe"

function ShouldExecuteEverything {
    $any = $AssocTxtfile.IsPresent `
        -or $CleanUpCtxMenu.IsPresent `
        -or $PrepareExplorer.IsPresent

    return -not $any
}

function SetTextFilesExtensions () {
    Write-Output "`n>> Setting up Text-Based files extensions."
    $extensions = LoadLinesFrom $PSScriptRoot "txtfile_extensions.txt"

    $total = @($extensions).Count
    $counter = 1
    foreach ($ext in $extensions) {
        $setupExpression = "assoc $ext=txtfile"
        Write-Output ">> >> [$counter/$total] executing: '$setupExpression'"
        cmd.exe /C $setupExpression
        $counter += 1
    }

    Write-Output ">> All $total files extensions have been set as text files."
}

function InitRegistryDriveHKCR () {
    $driveProvider = Get-PSDrive -PSProvider Registry `
    | Where-Object -Property Name -eq "HKCR"

    if (-not $driveProvider) {
        New-PSDrive -Scope Script -PSProvider Registry `
            -Root "HKEY_CLASSES_ROOT" -Name "HKCR" `
        | Out-Null
    }
}

function GenerateContextMenuRegistryKeys ($registryKeys) {
    $direct = $registryKeys `
    | ForEach-Object { "HKCR:\Directory\shell\$_" }

    $background = $registryKeys `
    | ForEach-Object { "HKCR:\Directory\Background\shell\$_" }

    return @($direct) + $background
}

function CleanupContextMenuItems () {
    Write-Output "`n>> Cleaning up Explorer's context menu of Folders from unwanted items."

    $cmdNames = LoadLinesFrom $PSScriptRoot "unwanted_cmds.txt"
    GenerateContextMenuRegistryKeys $cmdNames `
    | ForEach-Object {
        $regKey = $_
        $status = "already gone"

        if (Test-Path $regKey) {
            $status = "removed"
            Remove-Item $regKey -Recurse
        }

        Write-Output ">> >> Folder's context menu at: '$regKey' - $status."
    }

    Write-Output ">> Windows Explorer's context menu for folders cleaned up."
}

function ScheduleProcessExplorer () {
    Write-Output "`n>> Scheduling autostart of Process Explorer on user logon."
    if (CouldNotFindForConfig "Process Explorer" $ExpectedPath_ProcessExplorer) {
        return
    }

    $scheduleName = "Process Explorer - Autostart"
    Write-Output ">> Looking for schedule-task: '$scheduleName'..."
    cmd.exe /C "schtasks /Query /TN `"$scheduleName`""

    if ($LASTEXITCODE -ne 0) {
        Write-Output ">> Scheduling new task: '$scheduleName'"
        cmd.exe /C "schtasks /Create /SC ONLOGON /TN `"$scheduleName`" /TR `"$ExpectedPath_ProcessExplorer /t`""
    }

    Write-Output ">> Process Explorer scheduled to autostart on logon."
}

function PinToQuickAccess ($directoryPath) {
    if (-not (Test-Path $directoryPath)) {
        return
    }

    $x = New-Object -ComObject "Shell.Application"
    $x.NameSpace($directoryPath).Self.InvokeVerb("pintohome")
    Write-Output ">> >> Pinned to the Quick Access: $directoryPath"
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

    Write-Output ">> Pinning handy directory to the Quick Access..."
    PinToQuickAccess($Env:USERPROFILE)
    PinToQuickAccess($ProfilePath_Repos)

    Write-Output ">> Windows Explorer has been configured."
}

function EmbellishRepos () {
    Write-Output "`n>> Embellishing '~/Repos' by setting up directory's icon..."
    if (CouldNotFindForConfig "Repos directory" $ProfilePath_Repos) {
        return
    }

    $source = Join-Path $PSScriptRoot "template_Repos"
    $iconFile = "GitDirectory.ico"
    $configFile = "desktop.ini"

    ReplaceWitBackupAt $ProfilePath_Repos $source $iconFile
    $iconFile = Join-Path $ProfilePath_Repos $iconFile
    SetAttributesOf $iconFile "Hidden"

    ReplaceWitBackupAt $ProfilePath_Repos $source $configFile
    $configFile = Join-Path $ProfilePath_Repos $configFile
    SetAttributesOf $configFile "Hidden"
    SetAttributesOf $configFile "System"

    # Only to force folder's icon load by Explorer:
    SetAttributesOf $ProfilePath_Repos "ReadOnly"

    Write-Output ">> 'Repos' folder's appearance changed."
}

#######################################################################################

$all = ShouldExecuteEverything

if ($all -or $AssocTxtfile.IsPresent) {
    SetTextFilesExtensions
}

if ($all -or $CleanUpCtxMenu.IsPresent) {
    InitRegistryDriveHKCR
    CleanupContextMenuItems
}

if ($all -or $PrepareExplorer.IsPresent) {
    ScheduleProcessExplorer
    SetupWindowsExplorer
    EmbellishRepos
}

Write-Output "`n>> System preparation: Done."
