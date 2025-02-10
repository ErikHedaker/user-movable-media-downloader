@echo off
cd /d %~dp0..
echo Script File[%~f0]
powershell -ExecutionPolicy Bypass -File .\test\sandbox\outside\spawn.ps1 -ProjectRoot %cd%