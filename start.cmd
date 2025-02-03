@echo off
cd /d %~dp0
echo Script Path[%~f0]
powershell -ExecutionPolicy Bypass -File .\src\main.ps1