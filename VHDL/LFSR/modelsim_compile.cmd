@echo off

set SIM=%USERPROFILE%\ModelSim
rem Batch file's directory where the source code is
set SRC=%~dp0
rem drop last character '\'
set SRC=%SRC:~0,-1%
set DEST=%SIM%\projects\LFSR

echo Compile Source:   %SRC%\*
echo Into Destination: %DEST%
echo.

if not exist %DEST% (
  md %DEST%
)
rem vlib needs to be execute from the local directory, limited command line switches.
cd /d %DEST%
if exist work (
  echo Deleting old work directory
  vdel -modelsimini .\modelsim.ini -all
)

vmap local D:/Users/Philip/ModelSim/libraries/local
vlib work
vcom -2008 -work work %SRC%/sync_counter.vhdl %SRC%/sync_counter_wrapper.vhdl %SRC%/lfsr_counter.vhdl %SRC%/lfsr_counter_wrapper.vhdl %SRC%/compare_counters.vhdl %SRC%/test_counters.vhdl %SRC%/test_counter_wrapper.vhdl

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause