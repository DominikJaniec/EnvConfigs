param([string]$InstallVM = "all")

. ".\common.ps1"

$virtualMachines = @{
    "mint"   = @{
        "vmname" = "Linux Mint";
        "config" = "linux-mint.xml"
    };
    "debian" = @{
        "vmname" = "Debian Mini";
        "config" = "debian-mini.xml"
    }
}

function EnsureVBoxAvailable {
    try {
        Write-Output "Creating Virtual Machines by VirtualBox in version:"
        VBoxManage --version
    }
    catch {
        Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Write-Output "Please install VirtualBox before executing this script."
        throw "Environment is not ready, use: https://www.virtualbox.org/"
    }
}

function RequestedVirtualMachines ($keys) {
    if ($keys -eq "all") {
        return $virtualMachines.Values
    }

    $separator = ";"
    return "$keys".Split($separator) `
        | ForEach-Object { $_.Trim() } `
        | Where-Object { $_ -ne "all" } `
        | Where-Object { -not([string]::IsNullOrEmpty($_)) } `
        | Sort-Object `
        | Get-Unique -AsString `
        | ForEach-Object {
        if (-not($virtualMachines.ContainsKey($_))) {
            $knowKeys = [string]::Join($separator, @($virtualMachines.Keys))
            throw "Unknow machine key: '$_', please use 'all' or: '$knowKeys'."
        }

        return $virtualMachines[$_]
    }
}

#######################################################################################

EnsureVBoxAvailable

$requested = RequestedVirtualMachines $InstallVM
DumpObject $requested "requested VMs"

Write-Output "`n>> VBox preparation: Done."
