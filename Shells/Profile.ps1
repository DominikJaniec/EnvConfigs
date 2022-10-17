####################################################################
###      Domin's  PowerShell 7 profile's configuration file      ###
####################################################################


####################################################################
### Verbosity level

### Note: Uncomment one whichever you need ;)
# $DebugPreference = "Continue"
# $VerbosePreference = "Continue"

function Write-DebugTimestamped ($MessageLines) {
  $timestamp = Get-Date -Format yyyyMMdd-HH:mm:ss.fff
  $lines = @() + $MessageLines
  Write-Debug "$timestamp| $($lines[0])"
  $lines | Select-Object -Skip 1 `
  | ForEach-Object { Write-Debug "`t$_" }
}

Write-Verbose "Verbosity set to: $VerbosePreference"
Write-DebugTimestamped "Debug verbosity set to: $DebugPreference"


####################################################################
### Helpers

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

function Find-ParentProcess ($ParentName, $BasePID = $PID) {
  function procBy ($id) {
    return Get-Process -Id $id
  }

  $process = procBy $BasePID
  while ($null -ne $process) {
    if (-not $process.Parent) {
      return $null
    }

    $process = procBy $process.Parent.Id
    if ($ParentName -eq $process.Name) {
      return $process
    }
  }

  return $null
}

function Resolve-PathOrPwd ($Path) {
  return ($null -eq $path) `
    ? (Get-Location) `
    : (Resolve-Path $path)
}

Write-DebugTimestamped "Common helpers for Profile.ps1 registered."


####################################################################
### Environment

Set-Alias -Name exp `
  -Value explorer.exe

Set-Alias -Name cmds `
  -Value Get-Command


function Get-Environment {
  Get-ChildItem Env:
}

function Get-EnvironmentPath {
  $Env:Path -split ";"
}

Set-Alias -Name list-env `
  -Value Get-Environment

Set-Alias -Name list-path `
  -Value Get-EnvironmentPath


function Show-AliasWhere ($WhereBlock) {
  Get-Alias `
  | Where-Object -FilterScript $WhereBlock
  | Format-Table -Property Definition, Name -AutoSize
}

function Get-AliasForCmdlet ([Parameter(Position = 0)] $CmdletNameLike) {
  Show-AliasWhere { $_.Definition -like "$CmdletNameLike" }
}

function Get-CmdletFromAlias ([Parameter(Position = 0)] $AliasLike) {
  Show-AliasWhere { $_.Name -like "$AliasLike" }
}

Set-Alias -Name alias-as `
  -Value Get-CmdletFromAlias

Set-Alias -Name alias-of `
  -Value Get-AliasForCmdlet


function ff ($uri) {
  $firefox = "C:\Program Files\Mozilla Firefox\firefox.exe"
  if (-not (Test-Path $firefox)) {
    throw "Cannot find FireFox at '$firefox'."
  }

  if (Test-Path $uri) {
    $file = Resolve-Path $uri
    $file = "$file".Replace("\", "/")
    $uri = "file:///$file"
  }

  & $firefox $uri
}

Write-DebugTimestamped "Environment related commands defined."


####################################################################
### Navigation and Exploration

function cd.. { Set-Location .. }
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }
function ...... { Set-Location ../../../../.. }
function ....... { Set-Location ../../../../../.. }
function ........ { Set-Location ../../../../../../.. }

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

  $path = Resolve-PathOrPwd $path
  Write-Verbose "Listing content of `"$path`":"

  $source = $a.IsPresent `
    ? (Get-ChildItem $path -Force) `
    : (Get-ChildItem $path -Exclude ".*")

  $source `
  | Sort-Object -Property Name `
  | ForEach-Object {
    $display = format $_
    $mode = $_.Mode
    return pair $display $mode
  } `
  | Format-Wide
}

function ll ($path) {
  Get-ChildItem $path -Force
}

function la ($path) {
  l -a $path
}

function o ($path) {
  Set-Location $path
}

function ol ($path) {
  o $path && l
}

function ola ($path) {
  o $path && l -a
}

function u () {
  Set-Location ..
}

function ul () {
  u && l
}

function ula () {
  u && l -a
}

Write-DebugTimestamped "Navigation commands toolkit prepared."


####################################################################
### The `start-ish` Utility

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

Set-Alias -Name g `
  -Value git

function gst { git st $args }
function glo { git lo $args }
function gbr { git br $args }
function gsw { git sw $args }
function gdf { git df $args }
function gco { git co $args }
function grs { git rs $args }
function gad { git ad $args }
function gcm { git cm $args }
function grc { git rc $args }
function gcp { git cp $args }
function gft { git ft $args }
function gmg { git mg $args }
function gpl { git pl $args }
function gps { git ps $args }
function gdt { git dt $args }
function gmt { git mt $args }

Write-DebugTimestamped "The 'git' related aliases defined."


####################################################################
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

Write-DebugTimestamped "Prompt for 'git' via 'posh-git' created."


####################################################################
### Tools: `oh-my-posh`

Write-DebugTimestamped "Preparing 'oh-my-posh' with prompt theme..."

if (Find-ParentProcess "WindowsTerminal") {
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

### parameter completion shim for the dotnet CLI
# https://docs.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete#powershell
Register-ArgumentCompleter -Native -CommandName dotnet, dn -ScriptBlock {
  param ($commandName, $wordToComplete, $cursorPosition)
  dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
  }
}

function fsi {
  Write-Verbose "Starting F# Interactive (REPL) via .NET..."
  Write-DebugTimestamped "FSI given arguments:", $args
  dotnet fsi $args
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
