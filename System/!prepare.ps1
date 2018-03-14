. ".\common.ps1"

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
        Write-Output "`n>> >> [$counter/$total] executing: '$setupExpression'"
        cmd.exe /C $setupExpression
        $counter += 1
    }
}

function ScheduleProcessExplorer {
    $scheduleName = "Process Explorer - Autostart"
    $scheduleExe = "C:\ProgramData\chocolatey\lib\procexp\tools\procexp.exe"

    if (-not(Test-Path $scheduleExe)) {
        Write-Output "`n>> Could not find Process Explorer, scheduled autostart skipped."
        Write-Output "Tested path: '$scheduleExe'"
        return
    }

    Write-Output "`n>> Looking for schedule-task: '$scheduleName'..."
    cmd.exe /C "schtasks /Query /TN `"$scheduleName`""
    if ($LASTEXITCODE -ne 0) {
        cmd.exe /C "schtasks /Create /SC ONLOGON /TN `"$scheduleName`" /TR `"$scheduleExe /t`""
    }

    Write-Output "`n>> Process Explorer scheduled to autostart on logon."
}

function PinToQuickAccess ($directoryPath) {
    $o = new-object -com shell.application
    $o.Namespace($directoryPath).Self.InvokeVerb("pintohome")
}

function SetupWindowsExplorer {
    PinToQuickAccess($Env:USERPROFILE)
    PinToQuickAccess(Join-Path $Env:USERPROFILE "Repos")
    Write-Output "`n>> The 'Repos' directory has been pinned to the Quick Access."

    $regExplorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
    Set-ItemProperty $regExplorer ShowFrequent 0
    Set-ItemProperty $regExplorer ShowRecent 0

    $regExplorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty $regExplorerAdvanced HideFileExt 0
    Set-ItemProperty $regExplorerAdvanced ShowSuperHidden 1
    Set-ItemProperty $regExplorerAdvanced LaunchTo 1

    Write-Output "`n>> Windows Explorer has been configured."
}

#######################################################################################

SetTextFilesExtensions
ScheduleProcessExplorer
SetupWindowsExplorer

Write-Output "`n>> System preparation: Done."
