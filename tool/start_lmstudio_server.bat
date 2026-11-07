@echo off
chcp 65001 >nul
rem Запуск сервера LM Studio для всей домашней сети (кнопка в режиме разработчика не работает).
set PORT=1235
set LMS=lms
where lms >nul 2>nul || set LMS="%USERPROFILE%\.lmstudio\bin\lms.exe"

echo === Модели в памяти ===
%LMS% ps
echo.

echo === Перезапуск сервера на порту %PORT% для локальной сети ===
%LMS% server stop
%LMS% server start --port %PORT% --bind 0.0.0.0
echo.

echo === Кого слушает сервер ===
netstat -ano | findstr ":%PORT%" | findstr LISTENING
netstat -ano | findstr ":%PORT%" | findstr LISTENING | findstr "127.0.0.1:%PORT%" >nul && (
  echo.
  echo [!] Сервер слушает ТОЛЬКО этот компьютер ^(127.0.0.1^) - телефон его не увидит.
  echo     В LM Studio: настройки сервера - включите "Serve on Local Network",
  echo     затем запустите этот файл ещё раз.
) || (
  echo OK: сервер открыт для локальной сети.
)
echo.

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4" ^| findstr /v "198.18. 169.254."') do echo Адрес ПК для телефона:%%a  порт %PORT%
echo.
echo Если телефон всё равно не находит ПК, один раз запустите от имени администратора:
echo   netsh advfirewall firewall add rule name="LM Studio %PORT%" dir=in action=allow protocol=TCP localport=%PORT% profile=private
pause
