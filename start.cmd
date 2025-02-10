@echo off
cd /d %~dp0
echo Script File[%~f0]
powershell -ExecutionPolicy Bypass -File .\src\main.ps1 -ProjectRoot %cd%