####################################################################
###      Domin's  PowerShell 7 profile's configuration file      ###
####################################################################


####################################################################
### Helpers

### Note: Uncomment one whichever you need ;)
# $DebugPreference = "Continue"
# $VerbosePreference = "Continue"

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

function Write-DebugTimestamped ($MessageLines) {
  $timestamp = Get-Date -Format yyyyMMdd-HH:mm:ss.fff
  $lines = @() + $MessageLines
  Write-Debug "$timestamp| $($lines[0])"
  $lines | Select-Object -Skip 1 `
  | ForEach-Object { Write-Debug "`t$_" }
}

Write-DebugTimestamped "Helpers for Profile.ps1 registered."


####################################################################
### Environment

Write-DebugTimestamped "Defining Environment related commands..."

Set-Alias -Name exp `
  -Value explorer

function Get-CmdletAlias ($cmdletName) {
  Get-Alias `
  | Where-Object -FilterScript { $_.Definition -like "$cmdletName" } `
  | Format-Table -Property Definition, Name -AutoSize
}

Set-ALias -Name alias-for `
  -Value Get-CmdletAlias

Write-DebugTimestamped "Common aliases defined."


### navigation and exploration

function cd.. { Set-Location .. }
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }
function ...... { Set-Location ../../../../.. }
function ....... { Set-Location ../../../../../.. }
function ........ { Set-Location ../../../../../../.. }

function la {
  Get-ChildItem -Force
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

function o ($path) {
  Set-Location -Path $path
}

function e ($path) {
  o $path `
    && l
}

Write-DebugTimestamped "Navigation toolkit prepared."


### the `start-ish` utility

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

Write-DebugTimestamped "The 'start-ish' functions created."


####################################################################
### Tools: `git`

Write-DebugTimestamped "Defining 'git' related commands..."

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

### Setup 'posh-git' module

Write-DebugTimestamped "Importing and configuring the 'posh-git' module..."

Import-Module posh-git

function global:__GitPosh_PromptErrorInfo() {
  if ($global:GitPromptValues.DollarQuestion) {
    # green ok block:
    return "`e[32m#`e[0m"
  }

  $err = "!"
  if ($global:GitPromptValues.LastExitCode -ne 0) {
    $err += " e:" + $global:GitPromptValues.LastExitCode
  }

  # red error code block:
  return "`e[31m$err`e[0m"
}

# It is a template and we don't want string-substitution.
# Thus, there should be that single-quoted string:
$GitPromptSettings.DefaultPromptBeforeSuffix.Text `
  = '`n$([DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss"))' `
  + ' $(__GitPosh_PromptErrorInfo)'

Write-DebugTimestamped "Aliases and Prompt for 'git' created."


####################################################################
### Tools: `oh-my-posh`

Write-DebugTimestamped "Preparing 'oh-my-posh' with prompt theme..."

if ($null -ne $env:WT_PROFILE_ID) {
  Import-Module oh-my-posh
  Set-PoshPrompt -Theme "powerlevel10k_rainbow"

  Write-DebugTimestamped "Prompt with 'oh-my-posh' module loaded."
}
else {
  Write-DebugTimestamped "The 'oh-my-posh' prompt setup skipped", `
    " - not within Windows Terminal, only ASCII support expected."
}


####################################################################
### Tools: `dotnet`

Write-DebugTimestamped "Defining 'dotnet' related commands..."

Set-Alias -Name dn `
  -Value dotnet

function fsi {
  Write-Verbose "Starting F# Interactive (REPL) via .NET..."
  dotnet fsi $args
}

### parameter completion shim for the dotnet CLI
# https://docs.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete#powershell
Register-ArgumentCompleter -Native -CommandName dotnet, dn -ScriptBlock {
  param ($commandName, $wordToComplete, $cursorPosition)
  dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
  }
}

Write-DebugTimestamped "The 'dotnet' CLI arranged."


####################################################################
### Tools: `fake`
# TODO:
# * don't close window after fake-it

Write-DebugTimestamped "Defining 'fake' related commands..."

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

Write-DebugTimestamped "The 'fake' build-tool qualified."


####################################################################
