import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/foundation.dart';

import 'dns_service.dart';
import 'ping_service.dart';

enum NetworkToolMode { ping, dns }

/// Controller for the Network Tools screen.
///
/// Owns UI state, validates inputs, debounces async actions, and translates
/// typed service results into terminal-friendly lines.
class NetworkController extends ChangeNotifier {
  NetworkController({
    required PingService pingService,
    required DnsService dnsService,
  }) : _pingService = pingService,
       _dnsService = dnsService;

  final PingService _pingService;
  final DnsService _dnsService;

  bool _isDisposed = false;

  NetworkToolMode activeMode = NetworkToolMode.ping;

  /// Host or IP address entered by the user.
  String pingHost = '';

  /// Number of ICMP packets to send. Default 4, max 20.
  int pingCount = 4;

  /// Whether a ping stream is currently active.
  bool isPinging = false;

  /// Accumulated terminal output lines from the active ping session.
  final List<String> pingOutput = [];

  /// Optional error message to display in the ping panel.
  String? pingError;

  /// Domain entered by the user.
  String dnsDomain = '';

  /// Currently selected DNS record type.
  DnsRecordType dnsRecordType = DnsRecordType.a;

  /// Whether a DNS lookup is currently in flight.
  bool isDnsLoading = false;

  /// Results returned by the last successful DNS lookup.
  List<DnsRecord> dnsResults = [];

  /// Optional error message to display in the DNS panel.
  String? dnsError;

  bool get isBusy => isPinging || isDnsLoading;

  List<String> get activeOutputLines {
    return switch (activeMode) {
      NetworkToolMode.ping => _pingLines,
      NetworkToolMode.dns => _dnsLines,
    };
  }

  String get activeOutputText => activeOutputLines.join('\n');

  List<String> get _pingLines {
    final lines = <String>[...pingOutput.expand((line) => line.split('\n'))];
    if (pingError != null) {
      lines.add('Error: $pingError');
    }
    return lines;
  }

  List<String> get _dnsLines {
    if (dnsError != null) {
      return ['Error: $dnsError'];
    }
    if (dnsResults.isEmpty) {
      return const [];
    }
    return [
      'DNS results:',
      '',
      for (final record in dnsResults) record.formatted,
    ];
  }

  void setActiveMode(NetworkToolMode mode) {
    if (activeMode == mode) return;
    activeMode = mode;
    _notify();
  }

  void setPingHost(String value) {
    pingHost = value;
  }

  void setPingCount(int value) {
    pingCount = value.clamp(1, 20);
    _notify();
  }

  void setDnsDomain(String value) {
    dnsDomain = value;
  }

  void setDnsRecordType(DnsRecordType value) {
    if (dnsRecordType == value) return;
    dnsRecordType = value;
    _notify();
  }

  /// Start streaming ping packets to [pingHost].
  Future<void> startPing() async {
    final host = pingHost.trim();
    if (isPinging) return;

    pingOutput.clear();
    pingError = null;

    if (host.isEmpty) {
      pingError = 'Ping failed. Please check the host.';
      _notify();
      return;
    }

    isPinging = true;
    pingOutput
      ..add('Pinging $host...')
      ..add('');
    _notify();

    try {
      await for (final event in _pingService.ping(
        host: host,
        count: pingCount,
      )) {
        pingOutput.addAll(_formatPingEvent(event, host));
        _notify();
      }
    } catch (_) {
      pingError = 'Ping failed. Please check the host.';
    } finally {
      _pingService.stopPing();
      isPinging = false;
      _notify();
    }
  }

  /// Abort an active ping stream.
  void stopPing() {
    if (!isPinging) return;

    _pingService.stopPing();
    isPinging = false;
    pingOutput.add('--- Ping stopped by user ---');
    _notify();
  }

  /// Execute a DNS lookup for [dnsDomain] using [dnsRecordType].
  Future<void> lookupDns() async {
    final domain = dnsDomain.trim();
    if (isDnsLoading) return;

    dnsResults = [];
    dnsError = null;

    if (domain.isEmpty) {
      dnsError = 'DNS lookup failed. Please check the domain.';
      _notify();
      return;
    }

    isDnsLoading = true;
    _notify();

    try {
      dnsResults = await _dnsService.lookup(
        domain: domain,
        type: dnsRecordType,
      );
    } on DnsServiceException catch (e) {
      dnsError = e.message;
    } catch (_) {
      dnsError = 'DNS lookup failed. Please check the domain.';
    } finally {
      isDnsLoading = false;
      _notify();
    }
  }

  List<String> _formatPingEvent(PingEvent event, String host) {
    return switch (event) {
      PingResponse() => [
        'Reply from ${event.ip ?? host}: '
            '${event.seq == null ? '' : 'seq=${event.seq} '}'
            'ttl=${event.ttl ?? '?'} '
            'time=${_formatDurationMs(event.time)} ms',
      ],
      PingError() => [
        'Error${event.seq == null ? '' : ' seq=${event.seq}'}: '
            '${event.message ?? _describeError(event.error)}'
            '${event.ip == null ? '' : ' (${event.ip})'}',
      ],
      PingSummary() => _formatSummary(event),
    };
  }

  List<String> _formatSummary(PingSummary summary) {
    final lost = summary.transmitted - summary.received;
    final lines = [
      '',
      'Summary:',
      'Sent: ${summary.transmitted}',
      'Received: ${summary.received}',
      'Lost: $lost',
      'Packet loss: ${summary.packetLoss.toStringAsFixed(0)}%',
    ];

    final stats = summary.stats;
    if (stats?.avg != null) {
      lines.add('Average: ${_formatDurationMs(stats!.avg)} ms');
    }
    if (stats?.min != null && stats?.max != null) {
      lines.add(
        'Min/Max: ${_formatDurationMs(stats!.min)} / '
        '${_formatDurationMs(stats.max)} ms',
      );
    }
    return lines;
  }

  String _formatDurationMs(Duration? duration) {
    if (duration == null) return '?';
    final micros = duration.inMicroseconds;
    if (micros % Duration.microsecondsPerMillisecond == 0) {
      return (micros ~/ Duration.microsecondsPerMillisecond).toString();
    }
    return (micros / Duration.microsecondsPerMillisecond).toStringAsFixed(1);
  }

  String _describeError(ErrorType error) {
    return switch (error) {
      ErrorType.requestTimedOut => 'Request timed out.',
      ErrorType.unknownHost => 'Unknown host.',
      ErrorType.timeToLiveExceeded => 'Time to live exceeded.',
      ErrorType.noReply => 'No reply.',
      ErrorType.noRoute => 'No route to host.',
      ErrorType.unknown => 'Unknown error.',
    };
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pingService.stopPing();
    _dnsService.close();
    super.dispose();
  }
}
