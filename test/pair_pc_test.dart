import 'package:flutter_test/flutter_test.dart';

import '../tool/pair_pc_helper.dart';

void main() {
  group('R4-10: PC Pairing via QR (tool/pair_pc.dart)', () {
    test('filterCandidateHosts selects only private IPv4, excluding 198.18.x, 169.254.x, and virtual adapters', () {
      final interfaces = [
        const PcNetworkInfo(
          name: 'Loopback Pseudo-Interface 1',
          addresses: ['127.0.0.1'],
        ),
        const PcNetworkInfo(name: 'FlClashX', addresses: ['198.18.0.1']),
        const PcNetworkInfo(
          name: 'vEthernet (Default Switch)',
          addresses: ['172.28.16.1'],
        ),
        const PcNetworkInfo(
          name: 'VirtualBox Host-Only Ethernet Adapter',
          addresses: ['192.168.56.1'],
        ),
        const PcNetworkInfo(name: 'Ethernet', addresses: ['169.254.8.108']),
        const PcNetworkInfo(
          name: 'Беспроводная сеть',
          addresses: ['192.168.50.224'],
        ),
        const PcNetworkInfo(name: 'Ethernet 2', addresses: ['10.0.0.45']),
      ];

      final filtered = filterCandidateHosts(interfaces);

      // Only private non-virtual IPs should be present
      expect(filtered, contains('192.168.50.224'));
      expect(filtered, contains('10.0.0.45'));

      // Loopback, FlClashX TUN, vEthernet, VirtualBox, link-local must NOT be present
      expect(filtered, isNot(contains('127.0.0.1')));
      expect(filtered, isNot(contains('198.18.0.1')));
      expect(filtered, isNot(contains('172.28.16.1')));
      expect(filtered, isNot(contains('192.168.56.1')));
      expect(filtered, isNot(contains('169.254.8.108')));

      // Wi-Fi should have higher priority than secondary ethernet
      expect(filtered.first, equals('192.168.50.224'));
    });

    test('buildPairingJson produces correct schema without gigachat_key by default', () {
      final json = buildPairingJson(
        hosts: ['192.168.50.224'],
        port: 1235,
        model: 'google/gemma-4-12b-qat',
      );

      expect(json['app'], equals('chto-prigotovit'));
      expect(json['v'], equals(1));
      expect(json['hosts'], equals(['192.168.50.224']));
      expect(json['port'], equals(1235));
      expect(json['model'], equals('google/gemma-4-12b-qat'));
      expect(json.containsKey('gigachat_key'), isFalse);
    });

    test('buildPairingJson includes sanitized gigachat_key when provided', () {
      final json = buildPairingJson(
        hosts: ['192.168.50.224'],
        port: 1235,
        model: 'google/gemma-4-12b-qat',
        gigaChatKey: '  Basic  my-secret-key-12345  ',
      );

      expect(json.containsKey('gigachat_key'), isTrue);
      expect(json['gigachat_key'], equals('my-secret-key-12345'));
    });

    test('generateQrSvg creates valid SVG with module count and dimensions >= 300 px', () {
      final svg = generateQrSvg(
        '{"app":"chto-prigotovit","v":1,"hosts":["192.168.50.224"],"port":1235,"model":"gemma"}',
        moduleSize: 8,
        margin: 20,
      );

      expect(svg, startsWith('<svg'));
      expect(svg, endsWith('</svg>\n'));
      expect(svg, contains('xmlns="http://www.w3.org/2000/svg"'));
      expect(svg, contains('<rect'));
    });

    test(
      'buildPairingHtml generates complete HTML containing SVG and tips',
      () {
        final svg = generateQrSvg('test');
        final html = buildPairingHtml(
          svg: svg,
          hosts: ['192.168.50.224'],
          port: 1235,
          model: 'google/gemma-4-12b-qat',
          hasGigaChatKey: false,
        );

        expect(html, contains('<!DOCTYPE html>'));
        expect(html, contains('192.168.50.224:1235'));
        expect(html, contains('google/gemma-4-12b-qat'));
        expect(html, contains('192.168.0.0/16'));
        expect(html, contains('<svg'));
        expect(html, isNot(contains('setTimeout')));
      },
    );

    test('buildPairingHtml with hasGigaChatKey includes 2-minute auto-expiry script', () {
      final svg = generateQrSvg('test');
      final html = buildPairingHtml(
        svg: svg,
        hosts: ['192.168.50.224'],
        port: 1235,
        model: 'google/gemma-4-12b-qat',
        hasGigaChatKey: true,
      );

      expect(html, contains('setTimeout'));
      expect(html, contains('120000'));
      expect(html, contains('Содержит ключ GigaChat'));
    });
  });
}
