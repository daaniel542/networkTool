import 'package:dart_ping/dart_ping.dart';

/// Thin wrapper around dart_ping.
///
/// The service owns the active native ping process and exposes the package's
/// typed [PingEvent] stream. UI-facing formatting belongs in the controller.
class PingService {
  Ping? _activePing;

  /// Start pinging [host] for [count] packets.
  ///
  /// Listening to the returned stream starts the underlying platform ping
  /// process. The stream emits [PingResponse], [PingError], and terminal
  /// [PingSummary] events.
  Stream<PingEvent> ping({required String host, required int count}) {
    stopPing();
    _activePing = Ping(host, count: count);
    return _activePing!.stream;
  }

  /// Abort the active ping stream, if any.
  void stopPing() {
    _activePing?.stop();
    _activePing = null;
  }

  /// Backward-compatible alias for callers that still use the older name.
  void cancel() => stopPing();
}
