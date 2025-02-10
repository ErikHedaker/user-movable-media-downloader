@echo off
cd /d %~dp0
echo Script[%~f0]
powershell -ExecutionPolicy Bypass -File .\src\MainApp.ps1 -ProjectRoot %cd%