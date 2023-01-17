####################################################################
###      Domin's  PowerShell 7 profile's configuration file      ###
####################################################################


$__execution_stopwatch_ = `
  [System.Diagnostics.Stopwatch]::StartNew()

$__execution_timestamp_ = Get-Date -AsUTC

### Note: Uncomment one whichever you need ;)
# $DebugPreference = "Continue"
# $VerbosePreference = "Continue"

Write-Debug "Profile.ps1 starting at: $($__execution_timestamp_.ToLocalTime().ToString("dddd, 1yyyy-MM-dd HH:mm:ss.fff (zzz)"))"


####################################################################
#region Execution Context and Log Writers

$__execution_ctx = @{
  watch           = $__execution_stopwatch_
  timestamp       = $__execution_timestamp_
  writeOnEvent    = $true
  writeOnExit     = $false
  absorbChildren  = $true
  includeExamples = $false
}

function Write-DebugElapsed ($Message, $ms = $null) {
  $ms ??= $__execution_ctx.watch.ElapsedMilliseconds
  $ms = "$ms".PadLeft(14)

  Write-Debug "$ms| $Message"
}

function Write-VerboseDated ($MessageLines) {
  $lines = @() + $MessageLines

  $indent = "$(Get-Date -Format HH:mm:ss.fff)| "
  Write-Verbose $($indent + $lines[0])

  $indent = "            | `t"
  $lines | Select-Object -Skip 1 `
  | ForEach-Object { Write-Verbose $($indent + $_) }
}

Write-DebugElapsed "Debug verbosity set to: $DebugPreference"
Write-VerboseDated "Verbosity set to: $VerbosePreference"

#endregion


####################################################################
#region Helpers

function timestampMark () {
  Get-Date -Format yyyyMMdd-HH:mm:ss.fff -AsUTC
}

function pair ($fst, $snd) {
  [PSCustomObject]@{
    fst = $fst
    snd = $snd
  }
}

function triple ($fst, $snd, $trd) {
  $x = pair $fst $snd
  Add-Member -InputObject $x `
    -MemberType NoteProperty `
    -Name "trd" `
    -Value $trd
  return $x
}

function fst ($tuple) { $tuple.fst }
function snd ($tuple) { $tuple.snd }
function trd ($triple) { $triple.trd }

function startWatch () {
  [System.Diagnostics.Stopwatch]::StartNew()
}

function stringLine($char, $length = 69) {
  [string]::new($char, $length)
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

#endregion


####################################################################
#region Profiler capabilities

if ($DebugPreference -ne "Continue") {
  $__execution_ctx.writeOnEvent = $false
  $__execution_ctx.writeOnExit = $false
  $__execution_ctx.includeExamples = $false
}

$__execution_ctx.name = "//Profile.ps1"
$__execution_ctx.events = @()
$__execution_ctx.scopes = @()
$__execution_ctx.level = 0


function __logEvent ($eventMsg, $watch = $null) {
  function depthMarker ($depth) {
    Switch ($depth) {
      1 { ":" }
      2 { ">" }
      3 { ")" }
      4 { "}" }
      5 { "]" }
      Default { "|" }
    }
  }

  function scopePrefix ($scope, $depth) {
    $indent = stringLine " " $(2 * $depth)
    $scopeMark = depthMarker $depth

    $name = fst $scope
    $indent + $name + $scopeMark
  }

  $watch ??= $__execution_ctx.watch
  $eventMs = $watch.ElapsedMilliseconds

  $scope = $__execution_ctx.scopes[-1]
  if ($null -ne $scope) {
    $depth = $__execution_ctx.scopes.Count
    $prefix = scopePrefix $scope $depth
    $eventMsg = "$prefix $eventMsg"
  }

  $levelMark = depthMarker $__execution_ctx.level
  $nextEvent = pair "$levelMark  $eventMsg" $eventMs
  $__execution_ctx.events += $nextEvent

  if ($__execution_ctx.writeOnEvent) {
    Write-DebugElapsed $eventMsg $ms
  }
}

function __logScopePush ($scopeName) {
  __logEvent "Pushing execution scope '$scopeName'"
  $scope = pair "$scopeName" $(startWatch)
  $__execution_ctx.scopes += $scope
}

function __logScopePop () {
  $count = $__execution_ctx.scopes.Count
  $scope = $__execution_ctx.scopes[-1]
  if ($count -eq 0 -or $null -eq $scope) {
    throw "Popped not existing Log Scope"
  }

  $elapsed = (snd $scope).ElapsedMilliseconds
  __logEvent "Scope finished within $elapsed ms"

  Switch ($count) {
    1 { $__execution_ctx.scopes = @() }
    Default {
      $lastIndex = $count - 1
      $end = $lastIndex - 1
      $__execution_ctx.scopes = `
        $__execution_ctx.scopes[0..$end]
    }
  }
}

function __logScopeAs ($scopeName, $ScriptBlock) {
  __logScopePush $scopeName
  Invoke-Command $ScriptBlock
  __logScopePop
}

function __logShowAllEvents_WriteHost () {
  $elapsedMs = $__execution_ctx.watch.ElapsedMilliseconds
  $length = $__execution_ctx.events.Count

  function logShowEvent ($msg) {
    __logEvent ("__logShowAllEvents_WriteHost: $msg")
    return $__execution_ctx.events[-1]
  }

  logShowEvent "starting" | Out-Null

  function outEvents ($indent) {
    function strSize ($num) {
      [Math]::Ceiling([Math]::Log10($num + 0.1))
    }

    function toRight ($size, $num) {
      $num.ToString().PadLeft($size)
    }

    $events = $__execution_ctx.events

    $idxPadding = strSize ($length + 2)
    $msPadding = strSize (snd $events[-1])
    $msPadding += 1

    function outEventEntry ($i, $eventEntry) {
      $idx = toRight $idxPadding $i

      $ms = snd $eventEntry
      $ms = toRight $msPadding $ms

      $line = fst $eventEntry
      Write-Output "$indent$idx.  $ms ms $line"
    }

    function makeShowEntry ($message) {
      $eventMs = $__execution_ctx.watch.ElapsedMilliseconds
      return pair (prefixed $message) $eventMs
    }

    Write-Output "got $length events registered within $elapsedMs ms"

    $i = 0
    $iteratingEntry = "not-set :/"
    $events | ForEach-Object {
      if ($i -eq 0) {
        $iteratingEntry = logShowEvent "iterating"
      }

      $i += 1
      outEventEntry $i $_
    }

    outEventEntry ($i + 1) $iteratingEntry
    outEventEntry ($i + 2) (logShowEvent "output done")
  }

  Write-Host "### $(stringLine "#" -length 42)"
  Write-Host "### Execution log of '$($__execution_ctx.name)':"
  Write-Host "  * timestamp -> $($__execution_ctx.timestamp.ToString("o"))"
  Write-Host "  * watch -> $($__execution_ctx.watch.ElapsedMilliseconds) ms"
  Write-Host "  * events -> $($(outEvents "      ") -join "`n")"

  logShowEvent "all events shown" | Out-Null
}

function __logContext ($contextName, $ScriptBlock) {
  $ctxName = "[ctx] $contextName"
  __logScopePush $ctxName

  $parentCtx = $__execution_ctx.Clone()
  try {
    $__execution_ctx.name = $contextName
    $__execution_ctx.events = @()
    $__execution_ctx.scopes = @()
    $__execution_ctx.level += 1

    $__execution_ctx.timestamp = Get-Date -AsUTC
    $__execution_ctx.watch = $(startWatch)
    __logEvent "___ $(stringLine "_")"
    __logEvent "--- Starting '$ctxName'..."
    Invoke-Command $ScriptBlock

    $elapsed = $__execution_ctx.watch.ElapsedMilliseconds
    __logEvent "--- '$ctxName' done within $elapsed ms"
    __logEvent "--- $(stringLine "=")"

    if ($__execution_ctx.absorbChildren) {
      $children = $__execution_ctx.events
      __logEvent "absorbing $($children.Count) child events"
      $parentCtx.events += $children
    }

    if ($__execution_ctx.writeOnExit) {
      __logShowAllEvents_WriteHost
    }
  }
  finally {
    $global:__execution_ctx = $parentCtx
    __logScopePop
  }
}

function __logContext_writeOnEvent ($value) {
  $__execution_ctx.writeOnEvent = $value
}
function __logContext_writeOnExit ($value) {
  $__execution_ctx.writeOnExit = $value
}
function __logContext_writeSetDefaults () {
  __logContext_writeOnEvent $false
  __logContext_writeOnExit $true
}

__logEvent "Log framework defined."


if ($__execution_ctx.includeExamples) {
  __logEvent "self-test: consecutive log"
  __logEvent "self-test: consecutive log"
  __logEvent "self-test: consecutive log"
  __logEvent "self-test: consecutive log"
  __logEvent "self-test: consecutive log"
  __logEvent "self-test: consecutive log"
  __logEvent "self-test: consecutive log"
  __logEvent "self-test: consecutive log"
  __logEvent "self-test: consecutive log"
  __logEvent "self-test: consecutive log"
  __logEvent "self-test: eleventh msg"
  __logScopePush "outer_scope 1"
  __logEvent "in 1: message 1st"
  __logEvent "in 1: message 2nd"
  __logEvent "in 1: message 3rd"
  __logScopePush "inner_scope A"
  __logEvent "A: consecutive log i"
  __logEvent "A: consecutive log ii"
  __logScopePop
  __logEvent "???: outer_scope"
  __logScopePop
  __logEvent "???: after"
  __logEvent "top: under script blocks"
  __logScopeAs "fst-blocks" {
    __logEvent "fst: a message"
    __logEvent "fst: other message"
    __logScopeAs "inner-block" {
      __logEvent "snd: msg"
      __logScopeAs "time" { Get-Date | Out-Null }
      __logEvent "???: after time"
    }
    __logEvent "???: after inner"
  }
  __logEvent "???: block-scopes"
  __logEvent "looks nice in out scopes"
  __logContext "embedable contexts" {
    __logContext_writeOnEvent $true
    __logContext_writeOnExit $false
    __logEvent "first embedded message"
    __logScopePush "embedded scope"
    __logEvent "deeper (2nd) event message"
    __logScopeAs "other embedded scope" {
      __logEvent "third level with deep context"
      __logScopePush "over deeper context"
      __logContext "deeper context" {
        __logContext_writeSetDefaults
        __logEvent "deeper embedded event"
        __logScopeAs "scoped task" {
          $items = Get-ChildItem -Path "."
          __logEvent "Found $($items.Count) within:"
          __logEvent $PWD
        }
        __logEvent "embedded and deep context ends"
      }
      __logEvent "outside of deeper context"
      __logScopePop
      __logEvent "ended over scope"
    }
    __logEvent "ending embedded scope"
    __logScopePop
    __logEvent "restoring `"global`" context"
  }
  __logEvent "showing all entries"
  __logShowAllEvents_WriteHost
  __logEvent "contexts demo finished"
}

Write-VerboseDated "Common helpers for Profile.ps1 registered."

#endregion


####################################################################
#region Environment

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

function Resolve-PathOrPwd ($Path) {
  return ($null -eq $path) `
    ? (Get-Location) `
    : (Resolve-Path $path)
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

Write-VerboseDated "Environment related commands defined."

#endregion


####################################################################
#region Navigation and Exploration

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
    # Note: The 'Format-Wide' expects to get objects with
    #       at least one "property", to display them
    #       "correctly" within more than one column.
    $display = format $_
    pair $display $null
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

Write-VerboseDated "Navigation commands toolkit prepared."

#endregion


####################################################################
#region > UX `PSReadLine` Configuration
__logScopePush "PSReadLine"

# bash style completion without using Emacs mode:
Set-PSReadLineKeyHandler -Key Tab -Function Complete

# search history that matches the characters between the start and the input and the cursor
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# the source and style (PSReadLine 2.2.0) of predictive suggestions:
Set-PSReadLineOption -PredictionSource History
# Set-PSReadLineOption -PredictionViewStyle InlineView

# select text in the output and command line to be captured into clipboard:
Set-PSReadLineKeyHandler -Chord 'Ctrl+d,Ctrl+c' -Function CaptureScreen


# replace all aliases on the command line with the resolved commands:
# based on: https://github.com/PowerShell/PSReadLine/blob/b65141ef9e6112358ad24a5121d813c1e76da510/PSReadLine/SamplePSReadLineProfile.ps1#L440-L478
Set-PSReadLineKeyHandler -Key "Alt+#" `
  -LongDescription "Replace all aliases with the full command elements" `
  -BriefDescription ExpandAliases `
  -ScriptBlock {
  param($key, $arg)

  $ast = $null
  $tokens = $null
  $errors = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

  $tokenCommandName = [System.Management.Automation.Language.TokenFlags]::CommandName

  $startAdjustment = 0
  foreach ($token in $tokens) {
    if ($token.TokenFlags -band $tokenCommandName) {
      $extent = $token.Extent
      $alias = $ExecutionContext.InvokeCommand.GetCommand(
        $extent.Text,
        'Alias')

      if ($alias -ne $null) {
        $resolvedCommand = $alias.ResolvedCommandName
        if ($resolvedCommand -ne $null) {
          $length = $extent.EndOffset - $extent.StartOffset
          [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
            $extent.StartOffset + $startAdjustment,
            $length,
            $resolvedCommand)

          # local copy of the tokens won't have been updated,
          # so we need to adjust by the difference in length:
          $startAdjustment += ($resolvedCommand.Length - $length)
        }
      }
    }
  }
}


# cycle through arguments on current line and select theirs' value,
# use with digit argument, i.e. Alt+1, Alt+a selects the first:
# based on: https://github.com/PowerShell/PSReadLine/blob/b65141ef9e6112358ad24a5121d813c1e76da510/PSReadLine/SamplePSReadLineProfile.ps1#L604-L658
Set-PSReadLineKeyHandler -Key Alt+a `
  -LongDescription "Select next command argument in the command line, use of digit argument selects by position" `
  -BriefDescription SelectCommandArguments `
  -ScriptBlock {
  param($key, $arg)

  # makes it easier to quickly change the argument if
  # re-running a previously run command from the history,
  # or when using a PSReadLine predictor to adjust quickly.

  $ast = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$null, [ref]$null, [ref]$cursor)

  $asts = $ast.FindAll( {
      $args[0] -is [System.Management.Automation.Language.ExpressionAst] `
        -and $args[0].Parent -is [System.Management.Automation.Language.CommandAst] `
        -and $args[0].Extent.StartOffset -ne $args[0].Parent.Extent.StartOffset
    }, $true)

  if ($asts.Count -eq 0) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
    return
  }

  $nextAst = $null

  if ($null -ne $arg) {
    $nextAst = $asts[$arg - 1]
  }
  else {
    foreach ($ast in $asts) {
      if ($ast.Extent.StartOffset -ge $cursor) {
        $nextAst = $ast
        break
      }
    }

    if ($null -eq $nextAst) {
      $nextAst = $asts[0]
    }
  }

  $startOffsetAdjustment = 0
  $endOffsetAdjustment = 0

  if ($nextAst -is [System.Management.Automation.Language.StringConstantExpressionAst] `
      -and $nextAst.StringConstantType -ne [System.Management.Automation.Language.StringConstantType]::BareWord) {
    $startOffsetAdjustment = 1
    $endOffsetAdjustment = 2
  }

  $extent = $nextAst.Extent
  [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($extent.StartOffset + $startOffsetAdjustment)
  [Microsoft.PowerShell.PSConsoleReadLine]::SetMark($null, $null)
  [Microsoft.PowerShell.PSConsoleReadLine]::SelectForwardChar($null, ($extent.EndOffset - $extent.StartOffset) - $endOffsetAdjustment)
}


# store current command line in history without executing it:
# based on: https://github.com/PowerShell/PSReadLine/blob/b65141ef9e6112358ad24a5121d813c1e76da510/PSReadLine/SamplePSReadLineProfile.ps1#L311-L326
Set-PSReadLineKeyHandler -Key Alt+x `
  -LongDescription "Save current line in history, but do not execute it" `
  -BriefDescription SaveInHistory `
  -ScriptBlock {
  param($key, $arg)

  # sometimes you enter a complicated and long command,
  # but realize you forgot to do something else first...

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
  [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)

  # clears the line (like with <Esc>), so the undo stack is reset.
  # the redo <Ctrl+y> will still reconstruct the command line.
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
}


# use F1 for help window on the command line:
# check out: https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/dynamic-help?view=powershell-7.2
# based on: https://github.com/PowerShell/PSReadLine/blob/b65141ef9e6112358ad24a5121d813c1e76da510/PSReadLine/SamplePSReadLineProfile.ps1#L480-L517
Set-PSReadLineKeyHandler -Key F1 `
  -LongDescription "Open the help window for the current command" `
  -BriefDescription CommandHelp `
  -ScriptBlock {
  param($key, $arg)

  $ast = $null
  $tokens = $null
  $errors = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

  $commandAst = $ast.FindAll( {
      $node = $args[0]
      $node -is [System.Management.Automation.Language.CommandAst] `
        -and $node.Extent.StartOffset -le $cursor `
        -and $node.Extent.EndOffset -ge $cursor
    }, $true) `
  | Select-Object -Last 1

  if ($commandAst -ne $null) {
    $commandName = $commandAst.GetCommandName()
    if ($commandName -ne $null) {
      $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
      if ($command -is [System.Management.Automation.AliasInfo]) {
        $commandName = $command.ResolvedCommandName
      }

      if ($commandName -ne $null) {
        Get-Help $commandName -ShowWindow
      }
    }
  }
}


# show filtered command history in Out-GridView window with multiselect (Ctrl+click):
# based on: https://github.com/PowerShell/PSReadLine/blob/b65141ef9e6112358ad24a5121d813c1e76da510/PSReadLine/SamplePSReadLineProfile.ps1#L23-L78
Set-PSReadLineKeyHandler -Key F7 `
  -LongDescription 'Show command history filtered by current command line' `
  -BriefDescription History `
  -ScriptBlock {
  $pattern = $null
  $rawPattern = $null
  $windowTitle = "History"

  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$rawPattern, [ref]$null)
  if ($rawPattern) {
    $pattern = [regex]::Escape($rawPattern)
    $windowTitle = $windowTitle + " by ``$rawPattern``"
  }

  $history = [System.Collections.ArrayList]@(
    $last = ''
    $lines = ''
    foreach ($line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath)) {
      if ($line.EndsWith('`')) {
        $line = $line.Substring(0, $line.Length - 1)
        $lines = $lines ? "$lines`n$line" : $line
        continue
      }

      if ($lines) {
        $line = "$lines`n$line"
        $lines = ''
      }

      if (($line -cne $last) `
          -and (!$pattern `
            -or ($line -match $pattern))) {
        $last = $line
        $line
      }
    }
  )
  $history.Reverse()

  $command = $history | Out-GridView -Title $windowTitle -PassThru
  if ($command) {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join " ```n && "))
  }
}


# find more:
# - https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
# - https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline_functions
# - https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption

Write-VerboseDated "Available 'PSReadLine' configured."
__logScopePop

#endregion


####################################################################
#region > Shell's prompt Theme: `Oh-My-Posh`

__logScopePush "Oh-My-Posh"
Write-VerboseDated "Preparing 'Oh-My-Posh' with prompt theme..."

function Save-OhMyPoshFavorites($favorites) {
  if ($null -eq $favorites) {
    throw "Cannot set NULL as Oh-My-Posh favorites."
  }

  $key = "POSH_THEMES___FAVORITES"
  $serialized = $favorites -join ":"
  $options = [EnvironmentVariableTarget]::User
  [Environment]::SetEnvironmentVariable($key, $serialized, $options)

  Write-Verbose "Environment variable '$key' set as:`n`t$serialized"
}

function Get-OhMyPoshFavorites () {
  $key = "POSH_THEMES___FAVORITES"
  $options = [EnvironmentVariableTarget]::User
  $value = [Environment]::GetEnvironmentVariable($key, $options)
  Write-Verbose "Found favorite Oh-My-Posh configs:`n`t$value"

  return $null -ne $value `
    ? $value -split ":" `
    : @()
}

function Remove-OhMyPoshFavorite($name = $null, [switch]$All) {
  if ($All.IsPresent) {
    Write-Verbose "Removing all Oh-My-Posh favorites"
    Save-OhMyPoshFavorites @()
    return
  }

  $configName = $name ?? $env:POSH_THEMES__CURRENT
  Write-Verbose "Removing '$configName' from Oh-My-Posh favorites"

  $favorites = @(Get-OhMyPoshFavorites) `
  | Where-Object { $_ -ne $configName }

  Save-OhMyPoshFavorites $favorites
}

function Set-OhMyPoshFavorite ($name = $null) {
  $configName = $name ?? $env:POSH_THEMES__CURRENT
  Write-Verbose "Setting '$configName' as Oh-My-Posh favorite"

  $favorites = @(Get-OhMyPoshFavorites)
  $favorites = $favorites + $configName `
  | Select-Object -Unique

  Save-OhMyPoshFavorites $favorites
}

function Set-OhMyPoshTheme ($name = $null, [switch]$FromFavorites, [switch]$UseRandom) {
  if (-not $UseRandom.IsPresent -and $null -eq $name) {
    throw "No Oh-My-Posh theme was provided. Use '-UseRandom' to skip `$name argument."
  }

  Write-Verbose "Looking for Oh-My-Posh Themes within:"
  Write-Verbose "`t$env:POSH_THEMES_PATH"
  $configExt = "omp.json"

  function getRandomOhMyPoshConfig () {
    $files = Get-ChildItem $env:POSH_THEMES_PATH -Filter "*.$configExt"
    Write-Verbose "`t* Found $($files.Length) files"

    if ($FromFavorites.IsPresent) {
      $favorites = @(Get-OhMyPoshFavorites)
      if ($favorites.Count -eq 0) {
        throw "No Oh-My-Posh favorites was found. Use 'Set-OhMyPoshFavorite' to mark some themes as such."
      }

      $files = $files | Where-Object {
        $favorites -contains $_.Name
      }
    }

    return $files | ForEach-Object Name | Get-Random
  }

  $configName = "$name"
  if (-not $configName.EndsWith(".$configExt")) {
    $configName += ".$configExt"
  }

  if ($UseRandom.IsPresent) {
    $configName = getRandomOhMyPoshConfig
  }

  Write-Host "Oh-My-Posh initializing with: '$configName'"
  $configPath = Join-Path $env:POSH_THEMES_PATH $configName

  if (-not (Test-Path $configPath)) {
    throw "There is no config such: '$configPath'"
  }

  oh-my-posh init pwsh --config "$configPath" `
  | Invoke-Expression

  $env:POSH_THEMES__CURRENT = $configName
}

__logEvent "Extension methods defined."


if (Find-ParentProcess "WindowsTerminal") {
  Set-OhMyPoshTheme -UseRandom
  Write-VerboseDated "Prompt vai Oh-My-Posh module loaded."
}
else {
  Write-VerboseDated "Oh-My-Posh prompt skipped", `
    " - not within Windows Terminal,", `
    " - only ASCII support expected."
}


__logScopePop

#endregion


####################################################################
#region > The `start-ish` Utility

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

Write-VerboseDated "The 'start-ish' functions created."

#endregion


####################################################################
#region > Tools: `git`

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

Write-VerboseDated "The 'git' related aliases defined."

#endregion


####################################################################
#region > Tools: `dotnet`

Write-VerboseDated "Defining 'dotnet' related commands..."

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
  Write-VerboseDated "FSI given arguments:", $args
  dotnet fsi $args
}

Write-VerboseDated "The 'dotnet' CLI arranged."

#endregion


####################################################################
#region > Tools: `fake`

# TODO:
# * don't close window after fake-it

Write-VerboseDated "Defining 'fake' related commands..."

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

Write-VerboseDated "The 'fake' build-tool qualified."

#endregion


Write-Host "Domin's personal Profile.ps1 executed within $($__execution_stopwatch_.ElapsedMilliseconds) ms."
