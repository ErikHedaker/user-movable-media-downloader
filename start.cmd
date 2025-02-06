@echo off
cd /d %~dp0
echo Script[%~f0]
powershell -ExecutionPolicy Bypass -File .\src\Main.ps1 -ProjectRoot %cd%