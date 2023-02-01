##### To try it yourself:
#> pwsh -NoProfile -NoExit -WorkingDirectory "$HOME\Repos\EnvConfigs" -Command { . ".\_tools\profile-test-git-completion.ps1" }

##### To benchmark it:
#> pwsh -NoProfile -File .\profile-test-git-completion.ps1


$__PROMPT__ = "no-prompt> "
$__SKIP_PROMPT__ = $false
$__FORCE_NO_GIT_CWD__ = $false
$__NO_GIT__Directory__ = "D:\Repos\_ng_test"

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

. $(Join-Path $PSScriptRoot "profiler.autogen.ps1") `
    -__PROFILER_SetDebugVerbose `
    -__PROFILER_WriteOn_LogEvent `
    # -__PROFILER_WithExamples `
    # setable via environment variables


Write-Verbose "Possibly using no-git current directory..."
if ($__FORCE_NO_GIT_CWD__) {
    Set-Location $__NO_GIT__Directory__
    Write-Verbose "CWD: $__NO_GIT__Directory__"
}

Write-Verbose "Testing profiler script..."
__logScopeAs "self-test" {
    __logEvent "within"
    Write-Verbose "Testing..."
    __logEvent "after verbose"
}
Write-Verbose "Testing done"



__logScopePush "git-completion"

$source_directory = "C:\Users\domin\Downloads\posh-git_origin\src"
__logEvent "looking for Posh-Git files within:", $source_directory

function loadPath ($file) {
    __logEvent "loading '$file'"
    Join-Path $source_directory $file
}

$__filesCache = @{}
# function importCodeFrom ($file, $span, $offset = $null) {
function importCodeFrom ($file, $span) {
    $patternFirst = @($span)[0]
    $patternLast = @($span)[1]

    function getLinesFrom ($source) {
        $n = 0
        $lookForEnd = $false
        foreach ($line in $source) {
            $n++

            if ($lookForEnd) {
                Write-Output $line
                if ($line -match $patternLast) {
                    break
                }
            }
            elseif ($line -match $patternFirst) {
                $n = 1
                Write-Output $line
                $lookForEnd = $true
            }
        }

        __logEvent "extracted $n lines"
    }

    __logEvent "importing lines from: '$file" `
        , " * first: `"$patternFirst`"" `
        , " *  last: `"$patternLast`""

    $source = $__filesCache[$file]
    if ($null -eq $source) {
        $source = Get-Content $(loadPath $file)
        __logEvent "loaded $($source.Length) lines"

        $__filesCache[$file] = $source
    }

    return @(getLinesFrom $source) -join "`n"
}

function importFunSrc ($file, $method) {
    $pattern = "^function $method\s*{?", "^}\s*"
    importCodeFrom $file $pattern
}


__logScopePush "req-dependencies"

__logEvent "defining expected environment"
$ForcePoshGitPrompt = $false
$UseLegacyTabExpansion = $false
$EnableProxyFunctionExpansion = $false

__logScopePop


__logScopePush "all files"

. $(loadPath "CheckRequirements.ps1") > $null
__logEvent "CheckRequirements to NULL"

. $(loadPath "ConsoleMode.ps1")
. $(loadPath "Utils.ps1")
. $(loadPath "AnsiUtils.ps1")
. $(loadPath "WindowTitle.ps1")
. $(loadPath "PoshGitTypes.ps1")
. $(loadPath "GitUtils.ps1")
. $(loadPath "GitPrompt.ps1")

__logScopePop


__logScopePush "GitParamTabExpansion"
. $(loadPath "GitParamTabExpansion.ps1")
__logScopePop

__logScopePush "GitTabExpansion"
. $(loadPath "GitTabExpansion.ps1")
__logScopePop


__logScopePush "posh-git.psm1"

. $(loadPath "TortoiseGit.ps1")
__logEvent "TortoiseGit loaded"

$IsAdmin = Test-Administrator
__logEvent "admin tested: $IsAdmin"

$psm1First = "^# Get the default prompt definition."
$psm1Last = "^# Install handler for removal/unload of the module"
importCodeFrom "posh-git.psm1" @($psm1First, $psm1Last) `
| Invoke-Expression
__logEvent "invoked posh-git.psm1"

__logScopePop


__logScopePush "profiling prompt"

$givenPrompt = $function:prompt
function renderGivenPrompt () {
    __logEvent "attempting the prompt render..."
    $watch = $(startWatch)
    $render = $givenPrompt.Invoke()
    $elapsed = $watch.ElapsedMilliseconds
    __logEvent "prompt rendered within $elapsed ms, as:`n$render"
}

if ($__SKIP_PROMPT__ -eq $false) {
    renderGivenPrompt
}

function prompt () {
    if ($__SKIP_PROMPT__ -eq $true) {
        return $__PROMPT__
    }

    $watch = $(startWatch)
    $render = "{not-prompt}"
    try { $render = $givenPrompt.Invoke() }
    catch { $render = "prompt-error: $_`n" }
    $elapsed = $watch.ElapsedMilliseconds
    __logEvent "prompt rendered within $elapsed ms"

    return $render
}

__logScopePop


__logScopePop

Write-Verbose "Showing stats"

__logEvent "profile script done"

Write-Verbose "profile done"
