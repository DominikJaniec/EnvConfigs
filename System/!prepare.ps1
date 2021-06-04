param(
    [switch]$AssocTxtfile,
    [switch]$CtxMenuCleanUp,
    [switch]$WinExplorerPrepare,
    [switch]$ProcessExpSchedule,
    [switch]$DittoConfigSetup,
    [switch]$FluxConfigSetup,
    [switch]$HWiNFO64ConfigSetup,
    [switch]$UpdateScriptInstall
)

. ".\common.ps1"

function ShouldExecuteEverything {
    $any = $false `
        -or $AssocTxtfile.IsPresent `
        -or $CtxMenuCleanUp.IsPresent `
        -or $WinExplorerPrepare.IsPresent `
        -or $ProcessExpSchedule.IsPresent `
        -or $DittoConfigSetup.IsPresent `
        -or $FluxConfigSetup.IsPresent `
        -or $HWiNFO64ConfigSetup.IsPresent `
        -or $UpdateScriptInstall.IsPresent

    return -not $any
}

function SetTextFilesExtensions () {
    LogLines -Bar "Setting up Text-Based files extensions."
    $extensions = LoadLinesFrom $PSScriptRoot "txtfile_extensions.txt"

    $total = @($extensions).Count
    $counter = 1
    foreach ($ext in $extensions) {
        $setupExpression = "assoc $ext=txtfile"
        LogLines2 "[$counter/$total] executing: '$setupExpression'"
        # Note: Sadly `assoc` is only available within CMD.exe
        cmd.exe /C $setupExpression > $null
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot set 'text-file' association with '$ext' extension."
        }

        $counter += 1
    }

    LogLines "All $total files extensions have been set as text files."
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
    LogLines -Bar "Cleaning up Explorer's context menu of Folders from unwanted items."
    InitRegistryDriveHKCR

    $cmdNames = LoadLinesFrom $PSScriptRoot "unwanted_cmds.txt"
    GenerateContextMenuRegistryKeys $cmdNames `
    | ForEach-Object {
        $regKey = $_
        $status = "already gone"

        if (Test-Path $regKey) {
            $status = "removed"
            Remove-Item $regKey -Recurse
        }

        LogLines2 "Folder's context menu at: '$regKey' - $status."
    }

    LogLines "Windows Explorer's context menu for folders cleaned up."
}

function ScheduleProcessExplorer () {
    $processExplorerExpectedPath = Join-Path $Env:ChocolateyInstall "lib\procexp\tools\procexp.exe"
    LogLines -Bar "Scheduling autostart of Process Explorer on user logon."
    if (CouldNotFindForConfig "Process Explorer" $processExplorerExpectedPath) {
        return
    }

    $scheduleName = "Process Explorer - Autostart"
    LogLines2 "Looking for schedule-task: '$scheduleName'..."
    try {
        schtasks /Query /TN "$scheduleName" 2> $null
    }
    catch {
        # Required, as ignoring errors with `2> $null` (Error Stream redirection)
        # triggers `$ErrorActionPreference = "Stop"` which kills script execution.
    }

    if ($LASTEXITCODE -ne 0) {
        LogLines2 "Scheduling new Autostart task: '$scheduleName'"
        schtasks /Create /SC ONLOGON /RL HIGHEST /TN "$scheduleName" /TR "$processExplorerExpectedPath /t"

        if ($LASTEXITCODE -eq 0) {
            schtasks /Query /TN "$scheduleName"
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Could not schedule Autostart for the Process Explorer."
        }
    }

    LogLines "Process Explorer scheduled to autostart on logon."
}

function LocateUpperDirPath ($name) {
    $current = $PSScriptRoot

    while ($true) {
        $currentName = Split-Path $current -Leaf
        if ($currentName -eq $name) {
            return $current
        }

        $children = Get-ChildItem $current -Name
        if ($children -contains $name) {
            return Join-Path $current $name
        }

        $current = Split-Path $current -Parent
        if (-not $current) {
            throw "Cannot locate '$name' directory nowhere near." `
                + " Expected to find it as parents or among their sibling." `
                + " Initial searched path: $PSScriptRoot"
        }
    }
}

function KeepOnlyQuickAccess ($keepPathLeafs) {
    $app = New-Object -ComObject "Shell.Application"
    $app.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() `
    | Where-Object { $keepPathLeafs -notcontains (Split-Path $_.Path -Leaf) } `
    | ForEach-Object {
        LogLines2 "Unpinning from Quick Access: $($_.Name) '$($_.Path)'."
        $_.InvokeVerb("unpinfromhome")
    }
}

function PinToQuickAccess ($directoryPath) {
    $app = New-Object -ComObject "Shell.Application"
    $app.NameSpace($directoryPath).Self.InvokeVerb("pintohome")
    LogLines2 "Pinned to the Quick Access: '$directoryPath'."
}

function SetupWindowsExplorer () {
    LogLines -Bar "Fixing Windows Explorer display behavior configuration..."

    $regExplorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
    Set-ItemProperty $regExplorer ShowFrequent 0
    Set-ItemProperty $regExplorer ShowRecent 0

    $regExplorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty $regExplorerAdvanced Hidden 1
    Set-ItemProperty $regExplorerAdvanced HideFileExt 0
    # Note: New Explorer window will start at "This PC":
    Set-ItemProperty $regExplorerAdvanced LaunchTo 1
    # Note: I'm not sure, if we need to see System-Hidden files:
    # Set-ItemProperty $regExplorerAdvanced ShowSuperHidden 1

    LogLines "Setting only handy directory pinned to the Quick Access..."

    KeepOnlyQuickAccess @("Desktop", "Downloads", "Work")
    PinToQuickAccess (LocateUpperDirPath "Personal")
    PinToQuickAccess (LocateUpperDirPath "Repos")
    PinToQuickAccess $Env:USERPROFILE

    LogLines "Windows Explorer has been configured."
}

function SetupDitto {
    $dittoPath = Join-Path $Env:ProgramFiles "Ditto\Ditto.exe"
    ConfigUnderRestartedProcess "Ditto" "the clipboard manager" $dittoPath {
        ImportIntoRegister "Ditto's config" $PSScriptRoot `
            "Ditto-configuration.reg"
    }
}

function SetupFlux {
    $fluxPath = Join-Path $Env:LOCALAPPDATA "FluxSoftware\Flux\flux.exe"
    ConfigUnderRestartedProcess "f.lux" "let's reduce eyestrain" $fluxPath {
        ImportIntoRegister "f.lux's setup" $PSScriptRoot `
            "f.lux-configuration.reg"
    }
}

function SetupHwinfo {
    $hwinfoDirectory = Join-Path $Env:ProgramFiles "HWiNFO64"
    $hwinfoPath = Join-Path $hwinfoDirectory "HWiNFO64.EXE"
    ConfigUnderRestartedProcess "HWiNFO64" "sense HW sensors" $hwinfoPath {
        ImportIntoRegister "HWiNFO64" $PSScriptRoot `
            "HWiNFO64-sensors.reg"

        MakeSymLinksAt $hwinfoDirectory `
            $PSScriptRoot "HWiNFO64.INI"
    }
}

function InstallSystemUpdater {
    $updateScript = "update-system.bat"
    LogLines -Bar "Installing '$updateScript' script within PATH known directory..."
    MakeSymLinksAt $GloballyKnownPATH $PSScriptRoot $updateScript

    LogLines "Script '$updateScript' should be available for Admin."
}

#######################################################################################

Log -Bar "Beginning to configure System:"
$all = ShouldExecuteEverything

if ($all -or $AssocTxtfile.IsPresent) {
    SetTextFilesExtensions
}

if ($all -or $CtxMenuCleanUp.IsPresent) {
    CleanupContextMenuItems
}

if ($all -or $ProcessExpSchedule.IsPresent) {
    ScheduleProcessExplorer
}

if ($all -or $WinExplorerPrepare.IsPresent) {
    SetupWindowsExplorer
}

if ($all -or $DittoConfigSetup.IsPresent) {
    SetupDitto
}

if ($all -or $FluxConfigSetup.IsPresent) {
    SetupFlux
}

if ($all -or $HWiNFO64ConfigSetup.IsPresent) {
    SetupHwinfo
}

if ($all -or $UpdateScriptInstall.IsPresent) {
    InstallSystemUpdater
}

LogLines -Bar "System preparation: Done."
