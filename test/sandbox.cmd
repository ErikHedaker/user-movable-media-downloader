@echo off
cd /d %~dp0..
echo Script[%~f0]
powershell -ExecutionPolicy Bypass -File .\test\sandbox\env_create\sandbox_main.ps1