@echo off
cd /d %~dp0..\..
echo Script[%~f0]
for %%d in ("%cd%") do set project=%%~nxd
set destination=%USERPROFILE%\%project%
robocopy . %destination% /E
cd /d %destination%
echo CD[%cd%]
powershell -ExecutionPolicy Bypass -File .\test\sandbox\env_start\sandbox_remove_admin.ps1
call .\start.cmd