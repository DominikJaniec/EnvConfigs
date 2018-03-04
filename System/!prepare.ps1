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

    Write-Output "`n>> >> Process Explorer scheduled to autostart on logon."
}

#######################################################################################

SetTextFilesExtensions
ScheduleProcessExplorer

Write-Output "`n>> System preparation: Done."
