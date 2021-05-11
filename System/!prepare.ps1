param(
    [switch]$AssocTxtfile,
    [switch]$CtxMenuCleanUp,
    [switch]$ProcessExpSchedule,
    [switch]$PrepareExplorer,
    [switch]$DittoConfigSetup,
    [switch]$FluxConfigSetup,
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
        -or $UpdateScriptInstall.IsPresent

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

function ProcessExpSchedule () {
    $processExplorerExpectedPath = Join-Path $Env:ChocolateyInstall "lib\procexp\tools\procexp.exe"
    Write-Output "`n>> Scheduling autostart of Process Explorer on user logon."
    if (CouldNotFindForConfig "Process Explorer" $processExplorerExpectedPath) {
        return
    }

    $scheduleName = "Process Explorer - Autostart"
    Write-Output ">> Looking for schedule-task: '$scheduleName'..."
    cmd.exe /C "schtasks /Query /TN `"$scheduleName`""

    if ($LASTEXITCODE -ne 0) {
        Write-Output ">> Scheduling new task: '$scheduleName'"
        cmd.exe /C "schtasks /Create /SC ONLOGON /TN `"$scheduleName`" /TR `"$processExplorerExpectedPath /t`""
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

function DittoConfigSetup {
    $dittoExpectedPath = Join-Path $Env:ProgramFiles "Ditto\Ditto.exe"
    LogLines -Bar "Configuring Ditto - the clipboard manager..."
    if (CouldNotFindForConfig "Ditto" $dittoExpectedPath) {
        return
    }

    LogLines -lvl 2 "Importing configuration into Register:"
    $configPath = Join-Path $PSScriptRoot "Ditto-configuration.reg"
    REG IMPORT $configPath

    if ($LASTEXITCODE -ne 0) {
        throw "Could not import Ditto's configuration into Register."
    }

    LogLines -lvl 2 "Restarting Ditto..."
    RestartProcess $dittoExpectedPath

    LogLines "Ditto configured successfully."
}

function FluxConfigSetup {
    $fluxExpectedPath = Join-Path $Env:LOCALAPPDATA "FluxSoftware\Flux\flux.exe"
    LogLines -Bar "Configuring f.lux - reduce your eyestrain..."
    if (CouldNotFindForConfig "f.lux" $fluxExpectedPath) {
        return
    }

    LogLines -lvl 2 "Importing configuration into Register:"
    $configPath = Join-Path $PSScriptRoot "f.lux-configuration.reg"
    REG IMPORT $configPath

    if ($LASTEXITCODE -ne 0) {
        throw "Could not import f.lux's configuration into Register."
    }

    LogLines -lvl 2 "Restarting f.lux..."
    RestartProcess $fluxExpectedPath

    LogLines "f.lux configured successfully."
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
    InitRegistryDriveHKCR
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
    DittoConfigSetup
}

if ($all -or $FluxConfigSetup.IsPresent) {
    FluxConfigSetup
}

if ($all -or $UpdateScriptInstall.IsPresent) {
    UpdateScriptInstall
}

Write-Output "`n>> System preparation: Done."
