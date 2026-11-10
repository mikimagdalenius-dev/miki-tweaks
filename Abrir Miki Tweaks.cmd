@echo off
rem Lanzador portatil de Miki Tweaks: funciona desde un pen USB o desde cualquier carpeta.
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0MikiTweaks.ps1"
