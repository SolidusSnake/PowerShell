@echo off
@title 
@NET FILE 1>nul 2>nul
@if %ERRORLEVEL% neq 0 (
    @if not defined UAC (
        @set UAC=1;
    ) else (
        @echo. 
        @echo UAC elevating failed !
        @echo.
        @pause
        @exit
    )
    @echo CreateObject^("Shell.Application"^).ShellExecute "%~f0", "%*", "%~dp0", "runas", 1 > %temp%\UACtemp.vbs
    @cscript %temp%\UACtemp.vbs
    @del /f /q %temp%\UACtemp.vbs
    @exit
)
@cd /d %~dp0
@echo on
::command under this line
@echo off

cd %~dp0
Powershell -ExecutionPolicy ByPass -command "& '%~dp0sa.ps1'" 

exit



