import 'package:dart_ping/dart_ping.dart';

class PingService {
  Ping? _activePing;

  Future<void> ping({
    required String host,
    required int count,
    required void Function(String line) onResult,
  }) async {
    _activePing = Ping(host, count: count);

    await for (final event in _activePing!.stream) {
      switch (event) {
        case PingResponse():
          final ip = event.ip ?? host;
          final ms = event.time?.inMilliseconds ?? '?';
          final ttl = event.ttl ?? '?';
          onResult('Reply from $ip: ttl=$ttl time=${ms}ms');

        case PingError():
          onResult('Error: ${_describeError(event.error)}');

        case PingSummary():
          final loss =
              ((event.transmitted - event.received) / event.transmitted * 100)
                  .toStringAsFixed(0);
          onResult(
            '--- $host ping statistics ---\n'
            '${event.transmitted} packets transmitted, '
            '${event.received} received, '
            '$loss% packet loss',
          );
      }
    }
  }

  void cancel() {
    _activePing?.stop();
    _activePing = null;
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
}
