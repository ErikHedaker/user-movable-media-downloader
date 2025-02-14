@echo off
echo Scriptfile[%~f0]
cd /d %~dp0..
powershell -ExecutionPolicy Bypass -File .\test\sandbox\src\sandbox_spawn.ps1 -ProjectRoot %cd%