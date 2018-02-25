# EnvConfigs

My personal environment's configuration

## Chocolatey & system software

1. Install via script from: [Chocolatey.org](https://chocolatey.org/install)
    ```PowerShell
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    ```
2. Execute prepare script: [`.\Choco\!prepare.ps1`](Choco/!prepare.ps1)
   * Optional script's parameter `-level (core|work|full)`
   * Default value is assumed to be: `-level full`

## Text files extensions setup

1. Execute prepare script: [`.\TxtFiles\!prepare.ps1`](TxtFiles/!prepare.ps1)

## Git configuration

1. Git should had been installed via [_Chocolatey_](#chocolatey--system-software).
2. Execute prepare script: [`.\Git\!prepare.ps1`](Git/!prepare.ps1)

## Visual Studio Code

1. Download and install from [Microsoft](https://code.visualstudio.com/docs/?dv=win)
2. Execute prepare script: [`.\VSCode\!prepare.ps1`](VSCode/!prepare.ps1)

----

_Assumptions and remarks:_

* Headers presented above are set in proposed execution order of steps.
* Steps expect that this Repository had been cloned under path: `~/Repos` (_Chocolatey_ excluded).
* Every prepare script (`!prepare.ps1`) should be run from this Repository's root directory via PowerShell in elevated privileges.
* Expecting [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6) to be in version bigger then 3 (see: `$PSVersionTable.PSVersion`).
