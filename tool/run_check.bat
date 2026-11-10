@echo off
chcp 65001 >nul
rem Полная проверка проекта. Результат: docs\reports\last_check.txt
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check.ps1"
echo.
echo Готово. Итог в docs\reports\last_check.txt
pause
