# EnvConfigs

My personal environment's configuration

----

## Chocolatey & system software

1. Install via script from: [Chocolatey.org](https://chocolatey.org/install)
    ```PowerShell
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    ```
2. Execute prepare script: [`> .\Choco\!prepare.ps1`](Choco/!prepare.ps1)
   * Will install [defined applications](Choco/packages.txt) according to selected packages level.
   * Optional script's parameter `-PkgLevel (core|work|full)`.
   * Default value is assumed to be: `-PkgLevel full`.
3. Scripts have to be executed from PowerShell with elevated permissions to the Administrator Role.

## System configuration

1. Execute prepare script: [`> .\System\!prepare.ps1`](System/!prepare.ps1)
   * Will setup all defined [files' extensions](System/extensions.txt) to be treated as Text-Based files.
   * Will schedule [_Process Explorer_](https://chocolatey.org/packages/procexp) to autostart on Logon of any user.
2. Script have to be executed from PowerShell with elevated permissions to the Administrator Role.

## Git configuration

1. Git should had been installed via [_Chocolatey_](#chocolatey--system-software)
2. Execute prepare script: [`> .\Git\!prepare.ps1`](Git/!prepare.ps1)
   * Will hard-link configuration file ([`.gitconfig`](Git/.gitconfig)) into _Home_ (`~/`) directory.
   * There is an optional script's switch: `-LinkBack`. With it, script will just hard-link Git's configuration file back into this repository - because Git likes to break Hard-Links.

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
   * [**CapsLock Indicator**](https://github.com/jonaskohl/CapsLockIndicator) - A small utility that indicates the state of the Num lock, Caps lock and Scroll lock key.
   * [**Free Alarm Clock**](http://freealarmclocksoftware.com/) - This freeware program allows you to set as many alarms as you want.
   * [**Paint.NET**](https://www.getpaint.net/) - Image and photo editing software for PCs that run Windows.

----

_Assumptions and remarks:_

* Headers presented above are set in proposed execution order of steps.
* Every prepare script (`!prepare.ps1`) should be run from this Repository's root directory via PowerShell.
* Steps (excluding [_Chocolatey_](#chocolatey--system-software)) expects that this Repository had been cloned under path: `~/Repos/`.
* To obtain elevated PowerShell console, just execute: [`$#> PowerShell.exe -File ".\!elevate.ps1"`](!elevate.ps1)
* Expecting [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6) to be in version bigger then 3, see: `$PSVersionTable.PSVersion`
