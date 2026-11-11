@echo off
:: Fix PATH for powershell execution
set PATH=C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\Git\cmd;C:\Program Files\nodejs;%PATH%
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe %*
