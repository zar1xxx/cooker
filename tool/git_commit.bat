@echo off
chcp 65001 >nul
rem Commits everything with the message from .tmp_msg.txt. Result: docs\reports\last_git.txt
cd /d "%~dp0.."
(
git add -A
git commit -F .tmp_msg.txt
git status --short
git log --oneline -3
) > docs\reports\last_git.txt 2>&1
exit
