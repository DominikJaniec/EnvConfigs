####################################################################
###      Domin's  PowerShell 7 profile's configuration file      ###
####################################################################


####################################################################
### Environment: initial setup & configuration

function cd.. { Set-Location .. }
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }
function ...... { Set-Location ../../../../.. }
function ....... { Set-Location ../../../../../.. }
function ........ { Set-Location ../../../../../../.. }

function o ($path) {
  Set-Location -Path $path
}

function la {
  Get-ChildItem -Force
}

function pair ($fst, $snd) {
  return New-Object `
    "Tuple[object,object]"($fst, $snd)
}


function dump ($obj, $name = "Given object") {
  if ($null -eq $obj) {
    Write-Host "===// Dump '$name' as just the NULL ===\\"
  }
  else {
    Write-Host "===// Dump '$name' of type: $($obj.GetType())"
    Write-Host ($obj | Format-Table | Out-String) -NoNewline
    Write-Host "===\\"
  }
}

function l ($path, [switch]$a) {
  function format ($item) {
    $name = "$($item.Name)"
    $mode = "$($item.Mode)"
    function unambiguously ($x) {
      return $x.Contains(" ") `
        ? "`"$x`"" `
        : " $x"
    }
    function catalogue ($x) {
      return $mode.Contains("d") `
        ? "$x/" `
        : $x
    }
    function typeface {
      # possible suffixes:
      # return "👍🤌🔏⏏️⤵️🔄↗️"

      if ($mode.Contains("l")) {
        return "🔗"
      }
      return $mode.Contains("d") `
        ? "📂" `
        : "📄"
    }

    $name = unambiguously $name
    $name = catalogue $name
    $icon = typeface
    return "$icon $name"
  }

  $path = ($null -eq $path) `
    ? (Get-Location) `
    : (Resolve-Path $path)

  Write-Verbose "Listing content of `"$path`":"

  $source = $a.IsPresent `
    ? (Get-ChildItem -Path $path -Force) `
    : (Get-ChildItem -Path $path -Exclude ".*")

  $source `
  | Sort-Object -Property Name `
  | ForEach-Object {
    $display = format $_
    $mode = $_.Mode
    return pair $display $mode
  } `
  | Format-Wide
}


### `start-ish` utility

function start-wt ($subCommand) {
  Write-Verbose "Launching Windows Terminal in current directory..."
  Write-Verbose "`t* Sub-Command: '$subCommand'"
  Start-Process -FilePath wt `
    -ArgumentList "-d .", $subCommand
}

function start-pwsh ($command) {
  function encode ($cmd) {
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
    $encodedCommand = [Convert]::ToBase64String($bytes)
    return "-EncodedCommand $encodedCommand"
  }

  $cmd = $null -ne $command `
    ? (encode $command) `
    : ""

  start-wt "pwsh -NoExit $cmd"
}


### aliases for any cmdlet

Set-Alias -Name exp `
  -Value explorer

Set-ALias -Name alias-for `
  -Value Get-CmdletAlias

function Get-CmdletAlias ($cmdletName) {
  Get-Alias `
  | Where-Object -FilterScript { $_.Definition -like "$cmdletName" } `
  | Format-Table -Property Definition, Name -AutoSize
}


####################################################################
### Tools: `git`

Set-Alias -Name g `
  -Value git

function gst { git st }
function glo { git lo }
function gbr { git br }
function gsw { git sw }
function gdf { git df }
function gco { git co }
function grs { git rs }
function gad { git ad }
function gcm { git cm }
function grc { git rc }
function gcp { git cp }
function gft { git ft }
function gmg { git mg }
function gpl { git pl }
function gps { git ps }
function gdt { git dt }
function gmt { git mt }

Import-Module posh-git

#$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
#$GitPromptSettings.DefaultPromptBeforeSuffix.Text = "`n"


####################################################################
### Tools: `dotnet`

Set-Alias -Name dn `
  -Value dotnet

function start-fsi () {
  Write-Verbose "Starting F# Interactive (REPL) via .NET Core..."
  Start-Process -FilePath dotnet -ArgumentList fsi
}

### parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
  param ($commandName, $wordToComplete, $cursorPosition)
  dotnet complete --position $cursorPosition "$wordToComplete" `
  | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
  }
}

####################################################################
### Tools: `fake`
# TODO:
# * don't close window after fake-it

function __fake-it-can_here ($ScriptBlock) {
  $fakeFile = "build.fsx"
  $fakeHelp = "fake --help"

  if (Test-Path $fakeFile) {
    Invoke-Command -ScriptBlock $ScriptBlock
  }
  else {
    Write-Error ("Cannot use 'fake-it' command here!" `
        + " Missing file: '$fakeFile'," `
        + " check '$fakeHelp' for details.")
  }
}

function __fake-it-target ($target) {
  return -not [String]::IsNullOrWhiteSpace($target) `
    ? "--target $target".Trim() `
    : ""
}

function fake-what {
  __fake-it-can_here {
    Write-Verbose "Starting 'fake build --list'..."
    fake build --list
  }
}

function fake-it ($target) {
  $targetArg = __fake-it-target $target
  $fakeArgs = "build $targetArg".Trim()

  __fake-it-can_here {
    Write-Verbose "Starting 'fake $fakeArgs'..."
    Start-Process -FilePath fake `
      -ArgumentList $fakeArgs
  }
}

function fake-it-here ($target) {
  $targetArg = __fake-it-target $target
  $fakeCmd = "fake build $targetArg".Trim()

  __fake-it-can_here {
    Write-Verbose "Executing '$fakeCmd'..."
    Invoke-Expression -Command $fakeCmd
  }
}


####################################################################
### Environment: final configuration

### add a customized PowerShell prompt
# function Prompt {
#   $env:COMPUTERNAME + "\" + (Get-Location) + "> "
# }

$VerbosePreference = "Continue"
