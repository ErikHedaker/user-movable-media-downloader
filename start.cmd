@echo off
echo Scriptfile[%~f0]
cd /d %~dp0
powershell -ExecutionPolicy Bypass -File .\src\main.ps1 -ProjectRoot %cd%