# EnvConfigs

> My Personal Environment's Configuration and Setup
>
> -- Domin

## Initial preparation

1. Obtain [current repository](https://github.com/DominikJaniec/EnvConfigs) by cloning it, or what is more likely at fresh environment, by [downloading ZIP archive](https://github.com/DominikJaniec/EnvConfigs/archive/refs/heads/main.zip) and extracting it. Then place that `EnvConfig` within desired `Repos` _Home Directory_ - e.g. `~/Repos` or `D:\Repos`.

2. Using [`!elevate-session.ps1`](!elevate-session.ps1) script, start [_PowerShell_](https://docs.microsoft.com/en-us/powershell/) session (`PSSession`) elevated to the _Administrator Role_.

3. Set necessary [execution policy](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1) for the whole machine:

   ```PowerShell
   Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Confirm
   ```

4. Install [_Chocolatey_](https://chocolatey.org/about): a package manager for Windows, using elevated `PSSession`:

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

## System Windows configuration

1. Execute prepare script: [`> .\System\!prepare.ps1`](System/!prepare.ps1)
   * Script has a few switches. When any of then is present, only related changes will be executed. Script by default executes all of them.
   * Available switches: `-AssocTxtfile`, `-CtxMenuCleanUp`, `-ProcessExpSchedule`, `-WinExplorerPrepare`, `-DittoConfigSetup`, `-FluxConfigSetup`, `-HWiNFO64ConfigSetup`, `-UpdateScriptInstall`.

2. That script have to be executed from `PSSession` elevated to _Admin_ from target user.

3. What does that script do?
   * `-AssocTxtfile`: Will setup every [defined files' extensions](System/txtfile_extensions.txt) to be treated as Text-Based files by _Windows Explorer_.
   * `-CtxMenuCleanUp`: Will clean up context menu of folders from unnecessary [defined entries](System/unwanted_cmds.txt).
   * `-WinExplorerPrepare`: Will fix _Explorer's_ display configuration and organize [_Quick Access_](https://support.microsoft.com/en-us/help/4027032/windows-pin-remove-and-customize-in-quick-access) with a few handy folders. This script expect that there is a parent directory called `Repos` and one of theirs sibling is called `Personal` - both of them will be pinned.
   * `-ProcessExpSchedule`: Will schedule [_Process Explorer_](https://docs.microsoft.com/en-us/sysinternals/downloads/process-explorer) by _Mark Russinovich_ to start on _Logon_.
   * `-DittoConfigSetup`: Will load into Register non-default-personal [Ditto's](https://ditto-cp.sourceforge.io/) configuration.
   * `-FluxConfigSetup`: Will import Register-based [f.lux's](https://justgetflux.com/) configuration adjusted for Domin's lifestyle.
   * `-HWiNFO64ConfigSetup`: Will configure [HWiNFO64](https://www.hwinfo.com/) to sense CPU and GPU temperatures of CGL.
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

## Assumptions and remarks

* Chapters presented above are set in the proposed order of execution of steps for configuration setup.
* Initial placement of `EnvConfigs` repository is very important and should be under desired `Repos`:
  * Many _prepare script_ (i.e. `!prepare.ps1`) will make symbolic-links into files located here.
  * The _prepare script_ of `System` will pin as _favorites_ and _decorate_ a parent directory as `Repos`.
  * Every _prepare script_ should be run from this repository's root directory via _PowerShell_.
* It is required to have [_PowerShell_](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7.1) in version greater then `3.0`. Fortunately, Windows 10 currently comes with version `5.1` - to check it, one can type: `$PSVersionTable.PSVersion` within running `PSSession`.
* Almost all scripts expect to be run within _PowerShell_ session with elevated permissions to the _Administrator Role_. To obtain elevated PowerShell console, just execute:

   ```sh
   PowerShell.exe -NoProfile -File ".\!elevate-session.ps1"
   ```

## Track the `EnvConfigs` repository

1. While preparing fresh environment, current repository was probably just downloaded as ZIP without any _Git Tracking_ ability - as there were no `git` available at beginning of setup.
   * It is **not recommended** to _clone_ it again in desired place, as it should be already in expected `Repos` _Home Directory_.
   * It is **strongly encouraged** to restore _Git_ support within current directory - to easily track future configuration changes.

2. To reestablish _Git_ support within current repository, one should use favorite terminal under their own user account and call in order:

   ```sh
   git init --initial-branch=main
   git remote add origin https://github.com/DominikJaniec/EnvConfigs.git
   git fetch
   git reset origin/main --mixed
   git branch --set-upstream-to=origin/main
   git status
   ```
