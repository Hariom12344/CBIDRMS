@echo off
:: Inject missing system paths and Node.js directories
set PATH=C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\nodejs;%PATH%

echo [IDPMS Backend Runner] Starting Express backend database and server...
npm run dev
