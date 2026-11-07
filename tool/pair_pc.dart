import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'pair_pc_helper.dart';

Future<void> main(List<String> args) async {
  stdout.writeln('========================================');
  stdout.writeln('  Подключение ПК к приложению по QR    ');
  stdout.writeln('========================================\n');

  bool withGigaChat = false;
  String? gigaChatKey;
  int? portOverride;

  for (int i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--gigachat') {
      withGigaChat = true;
      if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        gigaChatKey = args[i + 1];
        i++;
      }
    } else if (arg.startsWith('--gigachat=')) {
      withGigaChat = true;
      gigaChatKey = arg.substring('--gigachat='.length);
    } else if (arg == '--port' && i + 1 < args.length) {
      portOverride = int.tryParse(args[i + 1]);
      i++;
    } else if (arg.startsWith('--port=')) {
      portOverride = int.tryParse(arg.substring('--port='.length));
    }
  }

  if (withGigaChat && (gigaChatKey == null || gigaChatKey.trim().isEmpty)) {
    stdout.write('Введите ключ авторизации GigaChat (Base64): ');
    // Read line from stdin (hidden echo in bat if available, or simple read)
    gigaChatKey = stdin.readLineSync()?.trim();
  }

  // 1. Проверяем LM Studio
  final dio = Dio();
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
    candidateHosts.add('127.0.0.1');
  }

  stdout.writeln('Сетевые адреса ПК: ${candidateHosts.join(', ')}');

  // 3. Проверяем доступность LM Studio по каждому сетевому адресу
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

  if (answeringHosts.isEmpty && !candidateHosts.contains('127.0.0.1')) {
    stdout.writeln(
      '\n========================================================================',
    );
    stdout.writeln('[ПРЕДУПРЕЖДЕНИЕ] Сервер слушает только этот компьютер!');
    stdout.writeln(
      'Локально (127.0.0.1:$activePort) сервер отвечает, но по сетевому адресу',
    );
    stdout.writeln('(${candidateHosts.first}) подключения отклоняются.');
    stdout.writeln('Запустите сервер для всей сети:');
    stdout.writeln('  tool\\start_lmstudio_server.bat');
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
    stdout.writeln('Файл страницы будет автоматически удалён через 2 минуты.');
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
}
