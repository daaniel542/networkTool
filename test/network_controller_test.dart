import 'package:dart_ping/dart_ping.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_utility_toolkit/features/network/dns_service.dart';
import 'package:net_utility_toolkit/features/network/network_controller.dart';
import 'package:net_utility_toolkit/features/network/ping_service.dart';

void main() {
  group('NetworkController', () {
    test('formats ping events into terminal output lines', () async {
      final controller = NetworkController(
        pingService: _FakePingService([
          const PingResponse(
            seq: 1,
            ttl: 57,
            time: Duration(milliseconds: 24),
            ip: '142.250.190.46',
          ),
          PingSummary(
            transmitted: 1,
            received: 1,
            stats: RoundTripStats.fromSamples([
              const Duration(milliseconds: 24),
            ]),
          ),
        ]),
        dnsService: _FakeDnsService(),
      )..setPingHost('google.com');

      await controller.startPing();

      expect(controller.isPinging, isFalse);
      expect(controller.activeOutputLines, contains('Pinging google.com...'));
      expect(
        controller.activeOutputLines,
        contains('Reply from 142.250.190.46: seq=1 ttl=57 time=24 ms'),
      );
      expect(controller.activeOutputLines, contains('Summary:'));
      expect(controller.activeOutputLines, contains('Average: 24 ms'));

      controller.dispose();
    });

    test('formats DNS results when DNS mode is active', () async {
      final controller =
          NetworkController(
              pingService: _FakePingService(const []),
              dnsService: _FakeDnsService(
                records: const [
                  DnsRecord(type: 'MX', value: '10 mail.example.com', ttl: 600),
                ],
              ),
            )
            ..setActiveMode(NetworkToolMode.dns)
            ..setDnsDomain('example.com')
            ..setDnsRecordType(DnsRecordType.mx);

      await controller.lookupDns();

      expect(controller.isDnsLoading, isFalse);
      expect(controller.activeOutputLines, contains('DNS results:'));
      expect(
        controller.activeOutputLines,
        contains('MX  10 mail.example.com  TTL 600'),
      );

      controller.dispose();
    });
  });
}

class _FakePingService extends PingService {
  _FakePingService(this.events);

  final List<PingEvent> events;

  @override
  Stream<PingEvent> ping({required String host, required int count}) async* {
    for (final event in events) {
      yield event;
    }
  }
}

class _FakeDnsService extends DnsService {
  _FakeDnsService({this.records = const []});

  final List<DnsRecord> records;

  @override
  Future<List<DnsRecord>> lookup({
    required String domain,
    required DnsRecordType type,
  }) async {
    return records;
  }

  @override
  void close() {}
}
