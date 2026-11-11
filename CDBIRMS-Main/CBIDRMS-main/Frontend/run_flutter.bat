@echo off
:: Inject missing Windows System32, PowerShell, and Git directories to the PATH
set PATH=C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\Git\cmd;%PATH%

if "%1" == "clean" (
    echo [IDPMS Runner] Running flutter clean...
    flutter clean
) else (
    echo [IDPMS Runner] Running flutter run -d chrome %*...
    flutter run -d chrome %*
)
