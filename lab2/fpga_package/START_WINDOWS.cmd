@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
title SCS - Windows 11 - Vivado
echo SCS / original ZYBO / Vivado 2024.1
echo First extract the WHOLE ZIP to C:\lab2\fpga_package.
echo.
if not exist "%~dp0scripts\windows_project.tcl" goto :missing_files

set "SCS_VIVADO="
if defined VIVADO_BAT if exist "%VIVADO_BAT%" set "SCS_VIVADO=%VIVADO_BAT%"
if not defined SCS_VIVADO if exist "C:\Xilinx\Vivado\2024.1\bin\vivado.bat" set "SCS_VIVADO=C:\Xilinx\Vivado\2024.1\bin\vivado.bat"
if not defined SCS_VIVADO if exist "C:\AMD\Vivado\2024.1\bin\vivado.bat" set "SCS_VIVADO=C:\AMD\Vivado\2024.1\bin\vivado.bat"
if not defined SCS_VIVADO for /f "delims=" %%V in ('where vivado.bat 2^>nul') do if not defined SCS_VIVADO set "SCS_VIVADO=%%V"
if defined SCS_VIVADO goto :menu
echo Vivado was not found automatically.
echo Find the Vivado desktop shortcut, right-click, Properties, Target.
echo Paste the FULL path ending in bin\vivado.bat below.
echo Example: D:\Xilinx\Vivado\2024.1\bin\vivado.bat
set /p "SCS_VIVADO=Vivado path: "
set "SCS_VIVADO=%SCS_VIVADO:"=%"
if not defined SCS_VIVADO goto :missing_vivado
if not exist "%SCS_VIVADO%" goto :missing_vivado

:menu
echo.
echo 1 - START HERE: lab2, 6+5 and RAM store
echo 2 - Python MUL: 6*7
echo 3 - Python SUB: 7-6
echo 4 - lab2 ADD result in R1
echo 5 - lab2 MUL: 6*7, opcode 50
echo 6 - base MOV/JMP program
choice /c 123456 /n /m "Press 1, 2, 3, 4, 5 or 6: "
if errorlevel 6 goto :base
if errorlevel 5 goto :lab2_mul
if errorlevel 4 goto :add_r1
if errorlevel 3 goto :sub
if errorlevel 2 goto :mul
goto :load_store

:load_store
set "SCS_PROGRAM=load_store"
set "SCS_ISA=1"
goto :launch
:mul
set "SCS_PROGRAM=mul"
set "SCS_ISA=0"
goto :launch
:sub
set "SCS_PROGRAM=sub"
set "SCS_ISA=0"
goto :launch
:add_r1
set "SCS_PROGRAM=lab2_add_r1"
set "SCS_ISA=1"
goto :launch
:lab2_mul
set "SCS_PROGRAM=lab2_mul"
set "SCS_ISA=1"
goto :launch
:base
set "SCS_PROGRAM=base"
set "SCS_ISA=0"

:launch
echo.
echo Using: "%SCS_VIVADO%"
echo Program: %SCS_PROGRAM%, ISA_LAB2=%SCS_ISA%
echo Wait for Vivado to finish creating/opening the project.
echo Then follow START_TUTAJ_WINDOWS.md. Keep this console open.
call "%SCS_VIVADO%" -mode gui -source "%~dp0scripts\windows_project.tcl" -tclargs %SCS_PROGRAM% %SCS_ISA%
if errorlevel 1 goto :vivado_failed
exit /b 0

:missing_files
echo ERROR: Missing scripts\windows_project.tcl. Extract the whole ZIP first.
pause
exit /b 1
:missing_vivado
echo ERROR: Cannot find vivado.bat. Check the installation path.
pause
exit /b 1
:vivado_failed
echo ERROR: Vivado returned an error. Check vivado.log and Tcl Console.
pause
exit /b 1
