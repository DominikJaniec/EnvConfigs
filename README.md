# EnvConfigs

My personal environment's configuration

## Chocolatey & system software

1. Install via script from: [Chocolatey.org](https://chocolatey.org/install)
    ```PowerShell
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    ```
2. Execute prepare script: [`.\Choco\!prepare.ps1`](Choco/!prepare.ps1)
   * Optional script's parameter `-level (core|work|full)`

## Git configuration

1. Git should had been installed via [_Chocolatey_](#chocolatey--system-software).
2. Execute prepare script: [`.\Git\!prepare.ps1`](VSCode/!prepare.ps1)

## Visual Studio Code

1. Download and install from [Microsoft](https://code.visualstudio.com/docs/?dv=win)
2. Execute prepare script: [`.\VSCode\!prepare.ps1`](VSCode/!prepare.ps1)

----

_Assumptions and remarks:_

* Expecting [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6) in version bigger then 3 (see: `$PSVersionTable.PSVersion`).
* All prepare scripts (`!prepare.ps1`) have to be run from Repository's root directory.
