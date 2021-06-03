param(
    [switch]$AssocTxtfile,
    [switch]$CtxMenuCleanUp,
    [switch]$ProcessExpSchedule,
    [switch]$PrepareExplorer,
    [switch]$DittoConfigSetup,
    [switch]$FluxConfigSetup,
    [switch]$HWiNFO64ConfigSetup,
    [switch]$UpdateScriptInstall
)

. ".\common.ps1"


$ProfilePath_Repos = Join-Path $Env:USERPROFILE "Repos"
$ExpectedPath_KnownPATH = Join-Path $Env:ChocolateyInstall "bin"

function ShouldExecuteEverything {
    $any = $AssocTxtfile.IsPresent `
        -or $CtxMenuCleanUp.IsPresent `
        -or $ProcessExpSchedule.IsPresent `
        -or $PrepareExplorer.IsPresent `
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

function ProcessExpSchedule () {
    $processExplorerExpectedPath = Join-Path $Env:ChocolateyInstall "lib\procexp\tools\procexp.exe"
    LogLines -Bar "Scheduling autostart of Process Explorer on user logon."
    if (CouldNotFindForConfig "Process Explorer" $processExplorerExpectedPath) {
        return
    }

    $scheduleName = "Process Explorer - Autostart"
    LogLines2 "Looking for schedule-task: '$scheduleName'..."
    schtasks /Query /TN "$scheduleName" 2> $null

    if ($LASTEXITCODE -ne 0) {
        LogLines2 "Scheduling new Autostart task: '$scheduleName'"
        schtasks /Create /SC ONLOGON /TN "$scheduleName" /TR "$processExplorerExpectedPath /t"

        if ($LASTEXITCODE -ne 0) {
            throw "Could not schedule Autostart for the Process Explorer."
        }
    }

    LogLines "Process Explorer scheduled to autostart on logon."
}

function PinToQuickAccess ($directoryPath) {
    if (-not (Test-Path $directoryPath)) {
        return
    }

    $x = New-Object -ComObject "Shell.Application"
    $x.NameSpace($directoryPath).Self.InvokeVerb("pintohome")
    LogLines2 "Pinned to the Quick Access: '$directoryPath'."
}

function SetupWindowsExplorer () {
    LogLines -Bar "Fixing Windows Explorer configuration..."
    $regExplorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
    Set-ItemProperty $regExplorer ShowFrequent 0
    Set-ItemProperty $regExplorer ShowRecent 0

    $regExplorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty $regExplorerAdvanced HideFileExt 0
    Set-ItemProperty $regExplorerAdvanced ShowSuperHidden 1
    Set-ItemProperty $regExplorerAdvanced LaunchTo 1

    LogLines "Pinning handy directory to the Quick Access..."
    PinToQuickAccess($Env:USERPROFILE)
    PinToQuickAccess($ProfilePath_Repos)

    LogLines "Windows Explorer has been configured."
}

function EmbellishRepos () {
    LogLines -Bar "Embellishing '~/Repos' by setting up directory's icon..."
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

    LogLines "'Repos' folder's appearance changed."
}

function UpdateScriptInstall {
    $updateScript = "update-system.bat"
    LogLines -Bar "Installing '$updateScript' script within PATH known directory..."
    MakeSymLinksAt $ExpectedPath_KnownPATH $PSScriptRoot $updateScript

    LogLines "Script '$updateScript' should be available for Admin."
}

#######################################################################################

$all = ShouldExecuteEverything

if ($all -or $AssocTxtfile.IsPresent) {
    SetTextFilesExtensions
}

if ($all -or $CtxMenuCleanUp.IsPresent) {
    CleanupContextMenuItems
}

if ($all -or $ProcessExpSchedule.IsPresent) {
    ProcessExpSchedule
}

if ($all -or $PrepareExplorer.IsPresent) {
    SetupWindowsExplorer
    EmbellishRepos
}

if ($all -or $DittoConfigSetup.IsPresent) {
    $dittoPath = Join-Path $Env:ProgramFiles "Ditto\Ditto.exe"
    ConfigUnderRestartedProcess "Ditto" "the clipboard manager" $dittoPath {
        ImportIntoRegister "Ditto's config" $PSScriptRoot `
            "Ditto-configuration.reg"
    }
}

if ($all -or $FluxConfigSetup.IsPresent) {
    $fluxPath = Join-Path $Env:LOCALAPPDATA "FluxSoftware\Flux\flux.exe"
    ConfigUnderRestartedProcess "f.lux" "let's reduce eyestrain" $fluxPath {
        ImportIntoRegister "f.lux's setup" $PSScriptRoot `
            "f.lux-configuration.reg"
    }
}

if ($all -or $HWiNFO64ConfigSetup.IsPresent) {
    $hwinfoDirectory = Join-Path $Env:ProgramFiles "HWiNFO64"
    $hwinfoPath = Join-Path $hwinfoDirectory "HWiNFO64.EXE"
    ConfigUnderRestartedProcess "HWiNFO64" "sense HW sensors" $hwinfoPath {
        ImportIntoRegister "HWiNFO64" $PSScriptRoot `
            "HWiNFO64-sensors.reg"

        MakeSymLinksAt $hwinfoDirectory `
            $PSScriptRoot "HWiNFO64.INI"
    }
}

if ($all -or $UpdateScriptInstall.IsPresent) {
    UpdateScriptInstall
}

LogLines -Bar "System preparation: Done."
