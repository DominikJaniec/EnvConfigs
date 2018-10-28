# EnvConfigs

My personal environment's configuration

----

## Initial basic setup

1. Set preferred [_PowerShell_](https://docs.microsoft.com/en-us/powershell/) execution policy for whole machine, using _PowerShell_ session (`PSSession`) with elevated permissions to the _Administrator Role_:
    ```PowerShell
    Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Confirm
    ```
2. Install [_Chocolatey_](https://chocolatey.org/about): a package manager for Windows, using elevated `PSSession`:
    ```PowerShell
    ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) `
        | Invoke-Expression
    ```

## Software via Chocolatey

1. Execute prepare script: [`> .\Choco\!prepare.ps1`](Choco/!prepare.ps1)
   * Optional script's parameter: `-PkgLevel (core|work|full)`
   * Default value is assumed to be: `-PkgLevel full`
2. That script requires _Chocolatey_ and have to be executed from `PSSession` elevated to _Admin_.
3. What does that script do?
   * Will turn on `choco`'s feature: [_Use Remembered Arguments For Upgrades_](https://chocolatey.org/docs/chocolatey-configuration#general-2).
   * Will install every [defined applications](Choco/packages.txt) according to selected packages level.
   * Some packages or their dependencies may require reboot after installation.

## Bash shell & Git configuration

1. Execute prepare script: [`> .\ShellGit\!prepare.ps1`](ShellGit/!prepare.ps1)
   * Optional script's switch: `-LinkBack`
   * When set, only hard-links configuration files back into this repository.
2. That script requires _Git_ with _Bash_, which should been already installed via [_Chocolatey_ step](#software-via-chocolatey).
3. What does that script do?
   * Will hard-link configuration files ([`.gitconfig`](ShellGit/.gitconfig), [`.bashrc`](ShellGit/.bashrc)) into _Home_ (`~/`) directory of current user.
   * Will hard-link [_ConEmu_](https://chocolatey.org/packages/ConEmu)'s configuration file ([`ConEmu.xml`](ShellGit/ConEmu.xml)) into user's _AppData_ directory, when available.

## Windows configuration

1. Execute prepare script: [`> .\System\!prepare.ps1`](System/!prepare.ps1)
   * Script has a few switches. When any of then is present, only related changes will be executed. Script by default executes all of them.
   * Available switches: `-OnlyTxtExt`, `-OnlyProcExp`, `-OnlyExplorer`, `-OnlyFixCtxMenu`.
2. That script have to be executed from `PSSession` elevated to _Admin_ from target user.
3. What does that script do?
   * Will setup every [defined files' extensions](System/extensions.txt) to be treated as Text-Based files by _Windows Explorer_. Switch: `-OnlyTxtExt`
   * Will schedule [_Process Explorer_](https://chocolatey.org/packages/procexp) by _Mark Russinovich_ to start on _Logon_ of any user. Switch: `-OnlyProcExp`
   * Will fix _Explorer's_ configuration and setup [_Quick Access_](https://support.microsoft.com/en-us/help/4027032/windows-pin-remove-and-customize-in-quick-access) with a few handy folders. It will also embellish current user's directory `~/Repos` with appropriate [icon](System/template_Repos/GitDirectory.png) for _Git_. Switch: `-OnlyExplorer`
   * Will cleanup context menu for folders with unnecessary entries. It will also setup new entry: _Open Bash here_ at folders, only when [_ConEmu_](https://chocolatey.org/packages/ConEmu) and _Bash_ from _Git_ are available. Switch: `-OnlyFixCtxMenu`

## Visual Studio Code

1. Execute prepare script: [`> .\VSCode\!prepare.ps1`](VSCode/!prepare.ps1)
   * Optional switch: `-LinkBack`: hard-links configuration files back into this repository.
   * Optional multi-value parameter: `-Extensions`: defines which _extensions groups_ will be installed. Available values: `(all|must|tools|coding|haskell|extra)` where `all` matches to every extension. Multiple values are separated by comma.
2. That script requires installed _VS Code_, which could be download from [Microsoft](https://code.visualstudio.com/docs/?dv=win).
3. What does that script do?
   * Will install every [defined extensions](VSCode/extensions.txt) for _VS Code_ according to selected _extensions group_.
   * Will hard-link configuration files ([`settings.json`](VSCode/settings.json), [`keybindings.json`](VSCode/keybindings.json)).

## Visual Studio 2017

1. Extensions and configuration presented in [file: `VSCommunity.md`](VSCommunity.md).
2. Download and install it from [Microsoft (_Community_ version)](https://www.visualstudio.com/pl/vs/community/).

## Additional software

1. Because _Chocolatey_ is not solution for everyone, here are other applications worth to install.
   * [**HWiNFO**](https://www.hwinfo.com/) - Comprehensive Hardware Analysis, Monitoring and Reporting for Windows and DOS.
   * [**Code Compare**](https://www.devart.com/codecompare/) - A free tool designed to compare and merge differing files and folders.
   * [**Fiddler**](https://www.telerik.com/fiddler) - The free web debugging proxy for any browser, system or platform.
   * [**dotPeek**](https://www.jetbrains.com/decompiler/) - Free .NET Decompiler and Assembly Browser (part of ReSharper).
   * [**CapsLock Indicator**](https://github.com/jonaskohl/CapsLockIndicator) - A small utility that indicates the state of the Num lock, Caps lock and Scroll lock key.
   * [**Free Alarm Clock**](http://freealarmclocksoftware.com/) - This freeware program allows you to set as many alarms as you want.

----

_Assumptions and remarks:_

* Headers presented above are set in proposed order of execution of configuration steps.
* Most of steps expects that, this Repository had been cloned under path: `~/Repos/EnvConfigs`.
* Every _prepare script_ (`!prepare.ps1`) should be run from this Repository's root directory via _PowerShell_.
* Almost all _prepare scripts_ expect to be run within _PowerShell_ session with elevated permissions to the _Administrator Role_.
* Some scripts provides switch: `-LinkBack`, because _Git_ likes to break `Hard-Links` on checkouts.
* Expecting [_PowerShell_](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6) to be in version bigger then 3, check: `$PSVersionTable.PSVersion` variable.
* To obtain elevated PowerShell console, just execute: [`$#> PowerShell.exe -File ".\!elevate.ps1"`](!elevate.ps1)
