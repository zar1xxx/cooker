import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'pair_pc_helper.dart';

Future<void> main(List<String> args) async {
  stdout.writeln('========================================');
  stdout.writeln('  Подключение ПК к приложению по QR    ');
  stdout.writeln('========================================\n');

  final parsedArgs = parsePairPcArgs(args);
  final withGigaChat = parsedArgs.withGigaChat;
  final portOverride = parsedArgs.port;
  String? gigaChatKey;

  if (withGigaChat) {
    stdout.write('Введите ключ авторизации GigaChat (Base64, ввод скрыт): ');
    final canDisableEcho = stdin.hasTerminal;
    final prevEcho = canDisableEcho ? stdin.echoMode : true;
    try {
      if (canDisableEcho) {
        stdin.echoMode = false;
      }
      gigaChatKey = stdin.readLineSync()?.trim();
    } finally {
      if (canDisableEcho) {
        stdin.echoMode = prevEcho;
      }
      stdout.writeln();
    }
  }

  final dio = Dio();
  try {
    // 1. Проверяем LM Studio
    final candidatePorts = portOverride != null ? [portOverride] : [1235, 1234];

    int? activePort;
    String? activeModel;

    for (final port in candidatePorts) {
      stdout.writeln(
        'Проверка LM Studio на http://127.0.0.1:$port/v1/models ...',
      );
      try {
        final res = await dio.get<Map<String, dynamic>>(
          'http://127.0.0.1:$port/v1/models',
          options: Options(
            connectTimeout: const Duration(seconds: 2),
            receiveTimeout: const Duration(seconds: 2),
          ),
        );
        final data = res.data?['data'];
        if (data is List && data.isNotEmpty) {
          for (final item in data) {
            if (item is Map) {
              final id = item['id']?.toString() ?? '';
              if (id.isNotEmpty && !id.toLowerCase().contains('embed')) {
                activeModel = id;
                activePort = port;
                break;
              }
            }
          }
          if (activeModel != null) break;
        }
      } catch (_) {}
    }

    if (activePort == null || activeModel == null) {
      stdout.writeln(
        '\n[ОШИБКА] LM Studio не запущен ни на одном порту (${candidatePorts.join(', ')}).',
      );
      stdout.writeln('Запустите сервер LM Studio командой:');
      stdout.writeln('  tool\\start_lmstudio_server.bat');
      stdout.writeln('и повторите попытку.');
      exit(1);
    }

    stdout.writeln(
      'LM Studio отвечает на порту $activePort. Модель: $activeModel\n',
    );

    // 2. Получаем адреса ПК
    final interfaces = await NetworkInterface.list();
    final networkInfos = interfaces
        .map(
          (ni) => PcNetworkInfo(
            name: ni.name,
            addresses: ni.addresses.map((a) => a.address).toList(),
          ),
        )
        .toList();

    final candidateHosts = filterCandidateHosts(networkInfos);
    if (candidateHosts.isEmpty) {
      stdout.writeln(
        '\n[ОШИБКА] Не найдено ни одного IP-адреса в локальной сети (192.168.x, 10.x, 172.16-31.x).',
      );
      stdout.writeln(
        'Убедитесь, что компьютер подключён к домашней сети Wi-Fi или Ethernet.',
      );
      exit(1);
    }

    stdout.writeln('Сетевые адреса ПК: ${candidateHosts.join(', ')}');

    // 3. Проверяем доступность LM Studio по каждому сетевому адресу до показа QR
    final answeringHosts = <String>[];
    for (final host in candidateHosts) {
      try {
        final res = await dio.get<Map<String, dynamic>>(
          'http://$host:$activePort/v1/models',
          options: Options(
            connectTimeout: const Duration(seconds: 1),
            receiveTimeout: const Duration(seconds: 1),
          ),
        );
        if (res.data?['data'] is List) {
          answeringHosts.add(host);
        }
      } catch (_) {}
    }

    if (answeringHosts.isEmpty) {
      stdout.writeln(
        '\n========================================================================',
      );
      stdout.writeln(
        '[!] Сервер слушает ТОЛЬКО этот компьютер (127.0.0.1) — телефон его не увидит.',
      );
      stdout.writeln(
        '    В LM Studio: настройки сервера — включите "Serve on Local Network",',
      );
      stdout.writeln(
        '    затем запустите tool\\start_lmstudio_server.bat ещё раз.',
      );
      stdout.writeln('');
      stdout.writeln(
        '    Если телефон всё равно не находит ПК, один раз выполните от администратора:',
      );
      stdout.writeln(
        '      netsh advfirewall firewall add rule name="LM Studio $activePort" dir=in action=allow protocol=TCP localport=$activePort profile=private',
      );
      stdout.writeln(
        '========================================================================\n',
      );
    } else {
      stdout.writeln('Сервер доступен по сети: ${answeringHosts.join(', ')}\n');
    }

    final hostsForQr = answeringHosts.isNotEmpty
        ? answeringHosts
        : candidateHosts;

    // 4. Генерируем QR-код
    final payload = buildPairingJson(
      hosts: hostsForQr,
      port: activePort,
      model: activeModel,
      gigaChatKey: gigaChatKey,
    );
    final jsonString = jsonEncode(payload);

    final svg = generateQrSvg(jsonString);
    final html = buildPairingHtml(
      svg: svg,
      hosts: hostsForQr,
      port: activePort,
      model: activeModel,
      hasGigaChatKey:
          withGigaChat && (gigaChatKey != null && gigaChatKey.isNotEmpty),
    );

    // 5. Сохраняем во временный HTML
    final tempDir = Directory.systemTemp.path;
    final tempFile = File(
      '$tempDir\\chto_prigotovit_pair_${DateTime.now().millisecondsSinceEpoch}.html',
    );
    await tempFile.writeAsString(html);

    stdout.writeln('QR-код сформирован и открывается в браузере:');
    stdout.writeln('  ${tempFile.path}\n');

    // 6. Открываем в браузере
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', tempFile.path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [tempFile.path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [tempFile.path]);
    }

    if (withGigaChat && gigaChatKey != null && gigaChatKey.isNotEmpty) {
      stdout.writeln('ВНИМАНИЕ: QR-код содержит ключ GigaChat.');
      stdout.writeln(
        'Файл страницы будет автоматически удалён через 2 минуты.',
      );
      stdout.writeln('Закройте страницу в браузере после сканирования.');
      Timer(const Duration(minutes: 2), () {
        try {
          if (tempFile.existsSync()) {
            tempFile.deleteSync();
          }
        } catch (_) {}
      });
    } else {
      stdout.writeln(
        'Наведите камеру в приложении «Что приготовить?» на экране телефона.',
      );
    }
  } finally {
    dio.close();
  }
}
