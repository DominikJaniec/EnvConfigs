# EnvConfigs

> My Personal Environment's Configuration and Setup
>
> -- Domin

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
   * Optional script's parameter: `-PkgLevel (core|tools|dev|full)`
   * Default value is assumed to be: `-PkgLevel full`
   * Each value encompass all previous levels.
2. That script requires _Chocolatey_ and have to be executed from `PSSession` elevated to _Admin_.
3. What does that script do?
   * Will turn on `choco`'s feature: [_Use Remembered Arguments For Upgrades_](https://docs.chocolatey.org/en-us/configuration#general-1).
   * Will install every [defined applications](Choco/packages.txt) according to selected packages level.
   * Some packages or their dependencies may require reboot after installation.

## Shells & Git configuration

1. Execute prepare script: [`> .\Shells\!prepare.ps1`](Shells/!prepare.ps1)
   * Script provides a single switch: `-PwshAllUsers`.
2. That script have to be executed from `PSSession` elevated to _Admin_ from target user.
   * This requirement could be lifted, when creating `SymbolicLink` will be available to normal users.
3. What does that script do?
   * Will make symbolic-links at _Home_ (`~/`) directory of current user with Bash and Git configuration files: [`.bash_profile`](Shells/.bash_profile) + [`.bashrc`](Shells/.bashrc), and [`.gitconfig`](Shells/.gitconfig).
   * Will install pwsh-modules: [`posh-git`](https://www.powershellgallery.com/packages/posh-git) and [`oh-my-posh`](https://www.powershellgallery.com/packages/oh-my-posh), which are utilized by `Profile.ps1` for more user friendly UX of terminal.
   * Symbolic-link will also be created for profile-file for PowerShell at [`~/Documents/PowerShell/Profile.ps1`](Shells/Profile.ps1) - no profile for old but yet default PowerShell 5.
   * When `-PwshAllUsers` is provided, the Pwsh is set up with Profile and Modules for [All Users](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles) under `C:/Program Files/PowerShell`.

## Windows configuration

1. Execute prepare script: [`> .\System\!prepare.ps1`](System/!prepare.ps1)
   * Script has a few switches. When any of then is present, only related changes will be executed. Script by default executes all of them.
   * Available switches: `-AssocTxtfile`, `-CtxMenuCleanUp`, `-ProcessExpSchedule`, `-PrepareExplorer`, `-DittoConfigSetup`, `-FluxConfigSetup`, `-HWiNFO64ConfigSetup`, `-UpdateScriptInstall`.
2. That script have to be executed from `PSSession` elevated to _Admin_ from target user.
3. What does that script do?
   * `-AssocTxtfile`: Will setup every [defined files' extensions](System/txtfile_extensions.txt) to be treated as Text-Based files by _Windows Explorer_.
   * `-CtxMenuCleanUp`: Will clean up context menu of folders from unnecessary [defined entries](System/unwanted_cmds.txt).
   * `-ProcessExpSchedule`: Will schedule [_Process Explorer_](https://chocolatey.org/packages/procexp) by _Mark Russinovich_ to start on _Logon_ of any user.
   * `-PrepareExplorer`: Will fix _Explorer's_ configuration and setup [_Quick Access_](https://support.microsoft.com/en-us/help/4027032/windows-pin-remove-and-customize-in-quick-access) with a few handy folders. It will also embellish current user's directory `~/Repos` with appropriate [icon](System/template_Repos/GitDirectory.png) for _Git_.
   * `-DittoConfigSetup`: Will load into Register non-default Ditto's configuration defined within [`ditto-configuration.reg`](System/ditto-configuration.reg) file.
   * `-FluxConfigSetup`: Will import Register-based f.lux's configuration adjusted for Domin's lifestyle.
   * `-HWiNFO64ConfigSetup`: Will configure HWiNFO64 to sense CPU and GPU temperatures of private laptop.
   * `-UpdateScriptInstall`: Will link [`update-system.bat`](System/update-system.bat) into `PATH` available directory, so _Admin_ can request and execute whole _System_ update.

## Visual Studio Code

1. Execute prepare script: [`> .\VSCode\!prepare.ps1`](VSCode/!prepare.ps1)
   * Optional multi-value parameter: `-Extensions`: defines which _extensions groups_ will be installed. Available values: `core`, `tools`, `dev`, `webdev`, `work`, `extra` - where `all` matches to every extension and multiple values are separated by comma.
   * There are two additional _switches_: `SkipExtra` and `SkipWork`, which excludes matched group even explicitly requested.
   * By default `-Extensions` assumes `all` group, for ease of use.
2. That script requires installed _VS Code_, which could be download from [Microsoft](https://code.visualstudio.com/docs/?dv=win).
3. What does that script do?
   * Will link configuration files ([`settings.json`](VSCode/settings.json), [`keybindings.json`](VSCode/keybindings.json)) at User Code's profile directory.
   * Will install every [defined extensions](VSCode/extensions.txt) for _VS Code_ according to selected _extensions-group_.

## Visual Studio 2017

1. Extensions and configuration presented in [file: `VSCommunity.md`](VSCommunity.md).
2. Download and install it from [Microsoft (_Community_ version)](https://www.visualstudio.com/pl/vs/community/).

## Keyboard

1. Use any _Ergodox_ compatible devices and load [`recent.hex`](Keyboard/recent.hex) layout.
2. More details one can find at: [`Keyboard/README.md`](Keyboard/README.md).

----

_Assumptions and remarks:_

* Headers presented above are set in proposed order of execution of configuration steps.
* Most of steps expects that, this Repository had been cloned under path: `~/Repos/EnvConfigs`.
* Every _prepare script_ (`!prepare.ps1`) should be run from this Repository's root directory via _PowerShell_.
* Almost all _prepare scripts_ expect to be run within _PowerShell_ session with elevated permissions to the _Administrator Role_. To obtain elevated PowerShell console, just execute: [`$#> PowerShell.exe -File ".\!elevate.ps1"`](!elevate.ps1)
* To execute those _prepare scripts_ [_PowerShell_](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7.1) is to be expected in version bigger then 3. Windows 10 currently comes with version 5, however to check one can use: `$PSVersionTable.PSVersion` variable.
