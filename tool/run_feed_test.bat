@echo off
chcp 65001 >nul
cd /d "%~dp0.."
call flutter test test/feed_screen_test.dart > docs\reports\last_feed_test.txt 2>&1
echo RESULT %ERRORLEVEL% >> docs\reports\last_feed_test.txt
exit
