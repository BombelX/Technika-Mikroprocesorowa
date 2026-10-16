@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
title SCS - PuTTY serial terminal
set "SCS_PUTTY="
if exist "%~dp0putty.exe" set "SCS_PUTTY=%~dp0putty.exe"
if not defined SCS_PUTTY if exist "%ProgramFiles%\PuTTY\putty.exe" set "SCS_PUTTY=%ProgramFiles%\PuTTY\putty.exe"
if not defined SCS_PUTTY if exist "%ProgramFiles(x86)%\PuTTY\putty.exe" set "SCS_PUTTY=%ProgramFiles(x86)%\PuTTY\putty.exe"
if not defined SCS_PUTTY for /f "delims=" %%P in ('where putty.exe 2^>nul') do if not defined SCS_PUTTY set "SCS_PUTTY=%%P"
if not defined SCS_PUTTY goto :missing_putty
echo Select the COM port of the Pmod USBUART on JE.
echo The ZYBO PROG/UART port is NOT the debugger port in this project.
echo Windows currently reports these serial ports:
powershell.exe -NoProfile -Command "[System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object"
echo Use Device Manager if you are unsure which port belongs to the Pmod.
set "SCS_COM="
set /p "SCS_COM=Enter COM port, e.g. COM11: "
set SCS_COM 2>nul | findstr /r /i /x "SCS_COM=COM[0-9][0-9]*" >nul
if errorlevel 1 goto :bad_port
echo Opening %SCS_COM% at 115200, 8N1, flow control None.
echo On ZYBO set SW3..SW0=0100, press BTN0, then BTN2 for output.
start "" "%SCS_PUTTY%" -serial %SCS_COM% -sercfg 115200,8,n,1,N
exit /b 0
:missing_putty
echo PuTTY was not found. Install it or place putty.exe next to this file.
echo Alternatively open PuTTY manually and follow README.md.
pause
exit /b 1
:bad_port
echo ERROR: Enter a port name such as COM11.
pause
exit /b 1
