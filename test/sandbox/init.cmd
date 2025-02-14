@echo off
echo Scriptfile[%~f0]
cd /d %~dp0..\..
powershell -ExecutionPolicy Bypass -File .\test\sandbox\src\environment_setup.ps1 -ProjectRoot %cd%