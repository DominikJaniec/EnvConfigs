# EnvConfigs

My personal environment's configuration

----

## Chocolatey & System software

1. Install via script from: [Chocolatey.org](https://chocolatey.org/install)
    ```PowerShell
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    ```
    * You might also like to turn on feature [_Use Remembered Arguments For Upgrades_](https://chocolatey.org/docs/chocolatey-configuration#general-2) by executing: `$#> choco feature enable --name=useRememberedArgumentsForUpgrades`
2. Execute prepare script: [`> .\Choco\!prepare.ps1`](Choco/!prepare.ps1)
   * Will install [defined applications](Choco/packages.txt) according to selected packages level.
   * Some packages or them dependencies may require reboot after installation.
   * Optional script's parameter `-PkgLevel (core|work|full)`.
   * Default value is assumed to be: `-PkgLevel full`.
3. Scripts have to be executed from PowerShell with elevated permissions to the Administrator Role.

## System configuration

1. Execute prepare script: [`> .\System\!prepare.ps1`](System/!prepare.ps1)
   * Will setup all defined [files' extensions](System/extensions.txt) to be treated as Text-Based files.
   * Will schedule [_Process Explorer_](https://chocolatey.org/packages/procexp) to start on _Logon_ of any user.
   * Will setup context menu entry: _Open Bash here_ at Folders - only when [_ConEmu_](https://chocolatey.org/packages/ConEmu) is available.
   * Will fix Windows Explorer configuration and setup Quick Access standard folders.
2. Script have to be executed from PowerShell with elevated permissions to the Administrator Role.

## Bash Shell & Git configuration

1. Git should had been installed via [_Chocolatey_](#chocolatey--system-software)
2. Bash shell is being expected to be installed with Git
3. Execute prepare script: [`> .\ShellGit\!prepare.ps1`](ShellGit/!prepare.ps1)
   * Will hard-link configuration files ([`.gitconfig`](ShellGit/.gitconfig), [`.bashrc`](ShellGit/.bashrc)) into _Home_ (`~/`) directory.
   * Will hard-link [_ConEmu_](https://chocolatey.org/packages/ConEmu)'s configuration file ([`ConEmu.xml`](ShellGit/ConEmu.xml)) into user's _AppData_ directory.
   * There is an optional script's switch: `-LinkBack`. With it, script will just hard-link configuration files back into this repository - because Git likes to break Hard-Links.

## Visual Studio Code

1. Download and install from [Microsoft](https://code.visualstudio.com/docs/?dv=win)
2. Execute prepare script: [`> .\VSCode\!prepare.ps1`](VSCode/!prepare.ps1)
   * Will install selected [extensions](VSCode/extensions.txt) and hard-link configuration files ([`settings.json`](VSCode/settings.json), [`keybindings.json`](VSCode/keybindings.json)) into VS Code.
   * There is an optional script's switch: `-LinkBack`. With it, script will just hard-link VS Code's configuration files back into this repository - because Git likes to break Hard-Links.

## Visual Studio 2017

1. Download and install from [Microsoft](https://www.visualstudio.com/pl/vs/community/)
   * Extensions and configuration: [description](VSCommunity.md).

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

* Headers presented above are set in proposed execution order of steps.
* Every prepare script (`!prepare.ps1`) should be run from this Repository's root directory via PowerShell.
* Steps (excluding [_Chocolatey_](#chocolatey--system-software)) expects that this Repository had been cloned under path: `~/Repos/`.
* To obtain elevated PowerShell console, just execute: [`$#> PowerShell.exe -File ".\!elevate.ps1"`](!elevate.ps1)
* Expecting [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6) to be in version bigger then 3, see: `$PSVersionTable.PSVersion`
