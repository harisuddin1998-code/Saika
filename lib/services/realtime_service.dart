import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeEvent {
  final String type;
  final Map<String, dynamic> payload;
  const RealtimeEvent(this.type, this.payload);
}

enum ConnectionStatus { connecting, connected, disconnected }

/// Client for the local realtime relay in server/bin/server.dart. Lets the
/// rider, driver, and admin apps see each other's actions live during the
/// demo without a cloud backend — start the server once, all three apps
/// connect to it over a plain WebSocket.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  /// Whatever host the page itself was loaded from — so a phone that opens
  /// http://192.168.x.x:5001 talks to the relay at that same LAN IP
  /// automatically, with no manual config. Override only if that guess is
  /// ever wrong (e.g. running outside a browser).
  static String host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
  static const int port = 8090;

  /// Hostname of the relay once it's deployed publicly (e.g. Render), used
  /// when the app itself is served from a public domain like GitHub Pages
  /// rather than localhost or a LAN IP — those two can't reach each other
  /// with a plain `ws://host:8090` guess. Filled in after the relay is
  /// deployed; empty means "not deployed yet, LAN/localhost only".
  static const String prodRelayHost =
      'prime-coyote-5642.harisuddin1998-code.deno.net';

  static bool get _isLocalOrLan =>
      host == 'localhost' ||
      host == '127.0.0.1' ||
      RegExp(r'^(10\.|172\.(1[6-9]|2\d|3[0-1])\.|192\.168\.)').hasMatch(host);

  /// Native builds (the installed APK) have no meaningful page origin —
  /// `Uri.base` only reflects a real address on web — so they always talk
  /// to the deployed relay directly instead of guessing from `host`.
  static Uri get _relayUri {
    if (kIsWeb) {
      if (!_isLocalOrLan && prodRelayHost.isNotEmpty) {
        return Uri.parse('wss://$prodRelayHost/ws');
      }
      return Uri.parse('ws://$host:$port/ws');
    }
    return Uri.parse('wss://$prodRelayHost/ws');
  }

  /// HTTP(S) base for plain REST calls (e.g. registration) to the same relay.
  static String get relayHttpBase {
    if (kIsWeb && _isLocalOrLan) return 'http://$host:$port';
    return 'https://$prodRelayHost';
  }

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _retryTimer;
  String _role = 'unknown';
  bool _manuallyClosed = false;

  final _controller = StreamController<RealtimeEvent>.broadcast();
  final ValueNotifier<ConnectionStatus> status = ValueNotifier(ConnectionStatus.disconnected);

  Stream<RealtimeEvent> get events => _controller.stream;

  void connect(String role) {
    _role = role;
    _manuallyClosed = false;
    _open();
  }

  void _open() {
    _retryTimer?.cancel();
    status.value = ConnectionStatus.connecting;
    try {
      final channel = WebSocketChannel.connect(_relayUri);
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onDone: _onDropped,
        onError: (Object _) => _onDropped(),
        cancelOnError: true,
      );
    } catch (_) {
      _onDropped();
    }
  }

  void _onMessage(dynamic raw) {
    status.value = ConnectionStatus.connected;
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = msg['type'] as String? ?? '';
      final payload = (msg['payload'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      if (type == 'state_snapshot') {
        send('hello', {'role': _role});
      }
      _controller.add(RealtimeEvent(type, payload));
    } catch (_) {
      // Ignore malformed frames rather than crashing the demo.
    }
  }

  void _onDropped() {
    _channel = null;
    _sub?.cancel();
    status.value = ConnectionStatus.disconnected;
    if (!_manuallyClosed) {
      _retryTimer = Timer(const Duration(seconds: 1, milliseconds: 500), _open);
    }
  }

  /// Call when the app returns to the foreground — the socket may have been
  /// silently dropped by the OS while backgrounded, so force a fresh attempt
  /// instead of waiting for the next scheduled retry.
  void reconnectNow() {
    if (status.value == ConnectionStatus.connected) return;
    _open();
  }

  void send(String type, Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null || status.value != ConnectionStatus.connected) return;
    channel.sink.add(jsonEncode({'type': type, 'payload': payload}));
  }

  /// Like [send], but for actions where silently dropping the message would
  /// be a real problem (sending an offer, accepting a ride) rather than
  /// something that self-heals on the next state sync. A plain [send] during
  /// a brief connection drop just vanishes with no feedback — the caller
  /// thinks it went through because nothing told them otherwise. This waits
  /// briefly for the connection to come back (it retries automatically every
  /// ~1.5s) and reports whether the message actually made it out, so the UI
  /// can show an error instead of proceeding as if it succeeded.
  Future<bool> sendReliably(
    String type,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (status.value != ConnectionStatus.connected) {
      if (DateTime.now().isAfter(deadline)) return false;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    send(type, payload);
    return true;
  }

  void disconnect() {
    _manuallyClosed = true;
    _retryTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    status.value = ConnectionStatus.disconnected;
  }
}

String newEventId() => DateTime.now().millisecondsSinceEpoch.toString();
