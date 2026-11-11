@echo off
chcp 65001 >nul
cd /d "%~dp0.."
call dart run tool/add_r10_recipes.dart > docs\reports\last_r10_add.txt 2>&1
exit
