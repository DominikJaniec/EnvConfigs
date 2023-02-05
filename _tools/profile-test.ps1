param ($RunFile = $null, [switch]$RunOwn)


function Get-EncodedCommand ($ScriptBlock) {
    $bytes = [System.Text.Encoding]::Unicode.GetBytes("$ScriptBlock")
    [Convert]::ToBase64String($bytes)
}


function Start-PwshNoProfile ($ScriptBlock, [switch]$EncodedCommand) {
    if (-not $EncodedCommand.IsPresent) {
        pwsh -NoProfile -Command $ScriptBlock
    }
    else {
        pwsh -NoProfile -EncodedCommand $ScriptBlock
    }
}

function Start-PwshWithFile ($ProfileFilePath) {
    Start-PwshNoProfile ". `"$ProfileFilePath`""
}

function Start-PwshDefaults () {
    pwsh -Command 0
}


#####################################################################
$headerUnderline = [string]::new('=', 42)

if ($null -ne $RunFile) {
    Write-Host "Starting pwsh with file:`n$RunFile"
    Write-Host $headerUnderline

    Start-PwshWithFile -ProfileFilePath $RunFile
}
elseif ($RunOwn.IsPresent) {
    Write-Host "Starting own profiled pwsh"
    Write-Host $headerUnderline

    Start-PwshDefaults
}
