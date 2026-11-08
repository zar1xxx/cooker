@echo off
chcp 65001 >nul
cd /d "%~dp0.."
(lms load --help
echo =====
lms server --help
echo =====
lms --version
echo done) > docs\reports\lms_load_help.txt 2>&1
