@echo off
cd /d %~dp0..\..
echo Script File[%~f0]
for %%d in ("%cd%") do set project=%%~nxd
set destination=%USERPROFILE%\%project%
robocopy . %destination% /E
cd /d %destination%
echo Change Directory[%cd%]
powershell -ExecutionPolicy Bypass -File .\test\sandbox\inside\setup_environment.ps1
call .\start.cmd