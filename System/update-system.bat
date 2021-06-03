@ECHO OFF
ECHO #####################################################################
ECHO ### Executing whole local System update...


SET /A LAST_PROBLEM_EXIT=0

REM By: `echo CTRL+G > x.txt`
SET BELL_CHAR=

IF %ERRORLEVEL% NEQ 0 (
    SET /A LAST_PROBLEM_EXIT=%ERRORLEVEL%
    GOTO problems
)


ECHO.
ECHO #####################################################################
ECHO ### ^>^> Executing update via Windows:
ECHO TODO! NOT IMPLEMENTED YET


ECHO.
ECHO #####################################################################
ECHO ### ^>^> Executing App-Store upgrade:
ECHO ### ^>^> pwsh "CimInstance | CimMethod"

@REM Based on https://docs.microsoft.com/en-us/windows/win32/dmwmibridgeprov/mdm-enterprisemodernappmanagement-appmanagement01-updatescanmethod
pwsh -NoProfile -Command "$ret = Get-CimInstance -Namespace 'Root\cimv2\mdm\dmmap' -ClassName 'MDM_EnterpriseModernAppManagement_AppManagement01' | Invoke-CimMethod -MethodName UpdateScanMethod; exit $null -eq $ret ? -13 : $ret.ReturnValue"

IF %ERRORLEVEL% NEQ 0 (
    SET /A LAST_PROBLEM_EXIT=%ERRORLEVEL%
    ECHO Finished with: '%LAST_PROBLEM_EXIT%'
)


ECHO.
ECHO #####################################################################
ECHO ### ^>^> Executing upgrade via Chocolatey:
ECHO ### ^>^> choco upgrade all --yes

@REM Based on Choco/!prepare.ps1
choco upgrade all --yes

IF %ERRORLEVEL% NEQ 0 (
    SET /A LAST_PROBLEM_EXIT=%ERRORLEVEL%
    ECHO Finished with: '%LAST_PROBLEM_EXIT%'
)


ECHO.
ECHO #####################################################################
ECHO ### ^>^> Executing pwsh Modules update:
ECHO ### ^>^> pwsh "Update-Module -Scope AllUsers -Verbose"

@REM Based on Shells/!prepare.ps1
pwsh -NoProfile -Command "Update-Module -Scope AllUsers -Verbose -ErrorAction Stop"

IF %ERRORLEVEL% NEQ 0 (
    SET /A LAST_PROBLEM_EXIT=%ERRORLEVEL%
    ECHO Finished with: '%LAST_PROBLEM_EXIT%'
)


IF %LAST_PROBLEM_EXIT% NEQ 0 (
    GOTO problems
)


ECHO.
ECHO #####################################################################
ECHO ### System-wide update finished successfully!
ECHO %BELL_CHAR%
PAUSE
EXIT /B 0


:problems

ECHO.
ECHO #####################################################################
ECHO ### !!! Encountered some issues while updating local System !!!
ECHO ### Please review log above and act accordingly or try again...
ECHO %BELL_CHAR%
PAUSE

EXIT /B %ERRORLEVEL%
