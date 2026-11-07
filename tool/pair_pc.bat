@echo off
chcp 65001 >nul
rem Запуск подключения ПК к телефону по QR-коду
dart run tool/pair_pc.dart %*
