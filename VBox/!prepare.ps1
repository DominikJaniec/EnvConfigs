param(
    [string]$InstallVM = "all",
    [switch]$WithGuestOS
)

. ".\common.ps1"

$VirtualBox = Join-Path $Env:PROGRAMFILES "Oracle\VirtualBox\VirtualBox.exe"

$VirtualMachines = @{
    # "sample" = @{
    #     Name    = "Sample Definition"
    #     Config  = "vbox-config.xml";
    #     Desktop = "shortcut-icon.ico";
    #     SetupOS = "setup-os-sample.ps1";
    # };
    "mint"   = @{
        Name    = "Linux Mint";
        Config  = "linux-mint.xml";
        Desktop = "linux-mint.ico";
        SetupOS = $null;
    };
    "debian" = @{
        Name    = "X Debian Mini";
        Config  = "debian-mini.xml";
        Desktop = $null;
        SetupOS = $null;
    };
}

$VMKeySeparator = ";"
$InstallAllKeys = @($VirtualMachines.Keys) -join $VMKeySeparator

function EnsureVirtualBoxAvailable {
    try {
        Write-Output ">> Creating Virtual Machines within VirtualBox in version:"
        VBoxManage --version

        EnsurePathExists $VirtualBox
    }
    catch {
        Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Write-Output "Please install VirtualBox before executing this script."
        throw "Environment is not ready, use: https://www.virtualbox.org/"
    }
}

function RequestedVirtualMachines ($keys) {
    if ($keys -eq "all") {
        $keys = $InstallAllKeys
    }

    return "$keys".Split($VMKeySeparator) `
        | ForEach-Object { $_.Trim() } `
        | Where-Object { $_ -ne "all" } `
        | Where-Object { -not([string]::IsNullOrEmpty($_)) } `
        | Select-Object -Unique `
        | ForEach-Object {
        if (-not($VirtualMachines.ContainsKey($_))) {
            throw "Unknow machine key: '$_', please use 'all' or: '$InstallAllKeys'."
        }

        $vm = $VirtualMachines[$_]
        if ($WithGuestOS.IsPresent -and -not($vm.SetupOS)) {
            throw "Machine: '$_' does not support auto-setup guest's OS."
        }

        return $vm
    }
}

function GetVirtualMachine ($vm) {
    $vmName = $vm.Name
    return & VBoxManage list vms `
        | Where-Object { $_ -match "`"$vmName`"" }
}

function VirtualMachineGuid ($vm) {
    $match = GetVirtualMachine $vm `
        | Select-String -Pattern "{(.*)}"

    return $match.Matches.Groups[1].Value
}

function  AlreadyInstalled ($vm) {
    if (GetVirtualMachine $vm.Name) {
        return $true
    }

    return $false
}

function DirectoryPathFor ($vm) {
    return Join-Path $ProfilePath_VMs $vm.Name
}

function PrepareTargetDirectory ($vm) {
    $vmDirectory = DirectoryPathFor $vm
    Write-Output ">> >> Preparing virtual machine's directory: '$vmDirectory'..."

    if (Test-Path $vmDirectory) {
        RenameAsTimestamptedBackup $vmDirectory
    }
    New-Item -Path $vmDirectory -ItemType Directory | Out-Null

    Copy-Item -Path (Join-Path $PSScriptRoot $vm.Config) -Destination $vmDirectory
    Write-Output ">> >> Copied $($vm.Config) into '$vmDirectory'."

    if ($vm.Desktop) {
        Copy-Item -Path (Join-Path $PSScriptRoot $vm.Desktop) -Destination $vmDirectory
        Write-Output ">> >> Copied $($vm.Desktop) into '$vmDirectory'."
    }
}

function  InstallVBoxMachine ($vm) {
    # TODO : Register VM in VirtualBox
    # TODO : Prepare HardDrive for it
    throw "Not implemented yet..."
}

function MakeDesktopShortcut ($vm) {
    Write-Output ">> >> Creating desktop shortcut icon for VM..."

    $vmName = $vm.Name
    $vmGuid = VirtualMachineGuid $vm

    $desktop = [Environment]::GetFolderPath("Desktop")
    $desktopLink = Join-Path $desktop "$vmName.lnk"
    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($desktopLink)

    $shortcut.TargetPath = $VirtualBox
    $shortcut.Arguments = "--comment `"Start $vmName`" --startvm `"$vmGuid`""
    $shortcut.WorkingDirectory = Split-Path -Path $VirtualBox -Parent
    $shortcut.IconLocation = Join-Path (DirectoryPathFor $vm) $vm.Desktop
    $shortcut.Description = "Starts the VirtualBox machine $vmName"
    $shortcut.Save()
}

function LunchSetupOfGuestOS ($vm) {
    Write-Output ">> >> Launching guest OS setup. It will take a while..."
    & (Join-Path $PSScriptRoot $vm.SetupOS) "$($vm.Name)" "$(DirectoryPathFor $vm)"
    if (-not($?)) {
        throw "Guest OS setup for '$($vm.Name)' exits with $LastExitCode."
    }

    Write-Output ">> >> '$($vm.Name)' guest OS installed with success."
}

function MakeVirtualMachine ($vm) {
    PrepareTargetDirectory $vm
    InstallVBoxMachine $vm

    if ($vm.Desktop) {
        MakeDesktopShortcut $vm
    }

    if ($WithGuestOS.IsPresent -and $vm.SetupOS) {
        LunchSetupOfGuestOS $vm
    }
}

#######################################################################################

EnsureVirtualBoxAvailable

foreach ($vm in RequestedVirtualMachines $InstallVM) {
    Write-Output "`n>> Creating virtual machine: $($vm.Name)..."
    if (AlreadyInstalled $vm) {
        Write-Output ">> >> Already installed in VirtualBox."
        continue
    }

    MakeVirtualMachine $vm
}

Write-Output "`n>> VirtualBox preparation: Done."
