@echo off
chcp 65001 >nul
cd /d "%~dp0.."
(git branch --show-current & git status --short & git log --oneline -5) > docs\reports\last_git.txt 2>&1
exit
