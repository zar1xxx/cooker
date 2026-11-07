@echo off
chcp 65001 >nul
rem Запуск сервера LM Studio без кнопки в режиме разработчика.
rem Сервер слушает всю локальную сеть, чтобы его нашёл телефон.

set PORT=1235
set LMS=lms
where lms >nul 2>nul || set LMS="%USERPROFILE%\.lmstudio\bin\lms.exe"

echo === Модели, загруженные в память ===
%LMS% ps
echo.
echo Если список пуст: загрузите модель в окне LM Studio
echo или командой  %LMS% load ^<имя модели^>  (список: %LMS% ls)
echo.

echo === Запуск сервера на порту %PORT% для локальной сети ===
%LMS% server start --port %PORT% --bind 0.0.0.0
if errorlevel 1 (
  echo.
  echo Не получилось с --bind. Пробую без него. Тогда включите
  echo в настройках сервера LM Studio "Serve on Local Network".
  %LMS% server start --port %PORT%
)
echo.
%LMS% server status
echo.

echo === Проверка ===
curl -s http://127.0.0.1:%PORT%/v1/models
echo.
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do echo Адрес ПК в сети:%%a
echo.
echo Если телефон не находит ПК, один раз запустите от имени администратора:
echo   netsh advfirewall firewall add rule name="LM Studio %PORT%" dir=in action=allow protocol=TCP localport=%PORT% profile=private
pause
