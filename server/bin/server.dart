// Local realtime relay for the Saika demo prototype.
//
// Broadcasts ride requests, offers, acceptances, and SOS events between the
// rider, driver, and admin apps so a Tuesday-ready demo can show real
// cross-app updates without wiring up a cloud backend first.
//
// Run:   dart run server/bin/server.dart
// Then point each app's RealtimeService at ws://<this-machine-ip>:8090/ws

import 'dart:convert';
import 'dart:io';

final Set<WebSocket> _clients = {};
final Map<WebSocket, String> _roles = {};

final List<Map<String, dynamic>> _activeRequests = [];
final List<Map<String, dynamic>> _activeSos = [];
final Map<String, List<Map<String, dynamic>>> _offersByRequest = {};

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8090;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Saika realtime relay listening on port $port');
  for (final addr in await NetworkInterface.list()) {
    for (final a in addr.addresses) {
      if (a.type == InternetAddressType.IPv4) {
        stdout.writeln('  ws://${a.address}:8090/ws');
      }
    }
  }

  await for (final req in server) {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final socket = await WebSocketTransformer.upgrade(req);
      _handleClient(socket);
    } else {
      req.response.statusCode = HttpStatus.ok;
      req.response.write('Saika realtime relay is running. Connect via WebSocket at /ws.');
      await req.response.close();
    }
  }
}

void _handleClient(WebSocket socket) {
  _clients.add(socket);
  _log('Client connected. Total: ${_clients.length}');

  socket.add(jsonEncode({
    'type': 'state_snapshot',
    'payload': {
      'activeRequests': _activeRequests,
      'activeSos': _activeSos,
      'offers': _offersByRequest,
      'onlineCount': _clients.length,
    },
  }));
  _broadcastPresence();

  socket.listen(
    (raw) => _handleMessage(socket, raw as String),
    onDone: () {
      _clients.remove(socket);
      _roles.remove(socket);
      _log('Client disconnected. Total: ${_clients.length}');
      _broadcastPresence();
    },
    onError: (Object e) => _log('Socket error: $e'),
  );
}

void _handleMessage(WebSocket socket, String raw) {
  try {
    final msg = jsonDecode(raw) as Map<String, dynamic>;
    final type = msg['type'] as String? ?? '';
    final payload = (msg['payload'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    switch (type) {
      case 'hello':
        _roles[socket] = payload['role'] as String? ?? 'unknown';
        _log('Client identified as ${_roles[socket]}');
        _broadcastPresence();
        return;
      case 'ride_request':
        _activeRequests.add(payload);
        break;
      case 'ride_offer':
        break;
      case 'ride_accepted':
        _activeRequests.removeWhere((r) => r['id'] == payload['requestId']);
        _offersByRequest.remove(payload['requestId']);
        break;
      case 'ride_cancelled':
        _activeRequests.removeWhere((r) => r['id'] == payload['requestId']);
        _offersByRequest.remove(payload['requestId']);
        break;
      case 'ride_countered':
        final requestId = payload['requestId'] as String?;
        if (requestId != null) {
          final list = _offersByRequest.putIfAbsent(requestId, () => []);
          final i = list.indexWhere((o) => o['driverId'] == payload['driverId']);
          if (i == -1) {
            list.add(payload);
          } else {
            list[i] = payload;
          }
        }
        break;
      case 'ride_completed':
        break;
      case 'sos_triggered':
        _activeSos.add(payload);
        break;
      case 'sos_resolved':
        _activeSos.removeWhere((s) => s['id'] == payload['id']);
        break;
      default:
        _log('Unknown message type: $type');
    }

    _log('$type from ${_roles[socket] ?? 'unknown'}: ${jsonEncode(payload)}');
    _broadcast(type, payload);
  } catch (e) {
    _log('Failed to parse message: $e');
  }
}

void _broadcastPresence() {
  final counts = <String, int>{};
  for (final role in _roles.values) {
    counts[role] = (counts[role] ?? 0) + 1;
  }
  _broadcast('presence', {'onlineCount': _clients.length, 'byRole': counts});
}

void _broadcast(String type, Map<String, dynamic> payload) {
  final msg = jsonEncode({'type': type, 'payload': payload});
  for (final c in _clients) {
    c.add(msg);
  }
}

void _log(String message) {
  final ts = DateTime.now().toIso8601String().substring(11, 19);
  stdout.writeln('[$ts] $message');
}
