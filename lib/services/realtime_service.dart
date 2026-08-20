import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class RealtimeEvent {
  final String type;
  final Map<String, dynamic> payload;
  const RealtimeEvent(this.type, this.payload);
}

enum ConnectionStatus { connecting, connected, disconnected }

/// Realtime backbone for the rider, driver, and admin apps — backed by
/// Saika's own Supabase project (Realtime broadcast for live messages, a
/// few Postgres tables for anything that needs to survive a reconnect).
/// Same public shape as the old Deno-relay WebSocket client it replaced, so
/// none of the screens that call `send`/`sendReliably`/`events` had to
/// change.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  static const String _channelName = 'saika-relay';
  static const String _broadcastEvent = 'msg';

  RealtimeChannel? _channel;
  Timer? _retryTimer;
  String _role = 'unknown';
  bool _manuallyClosed = false;

  final _controller = StreamController<RealtimeEvent>.broadcast();
  final ValueNotifier<ConnectionStatus> status = ValueNotifier(
    ConnectionStatus.disconnected,
  );

  Stream<RealtimeEvent> get events => _controller.stream;

  SupabaseClient get _client => SupabaseConfig.client;

  void connect(String role) {
    _role = role;
    _manuallyClosed = false;
    _open();
  }

  Future<void> _open() async {
    _retryTimer?.cancel();
    status.value = ConnectionStatus.connecting;
    try {
      await SupabaseConfig.ensureInitialized();
      final channel = _client.channel(_channelName);
      _channel = channel;
      channel
          .onBroadcast(
            event: _broadcastEvent,
            callback: (payload) {
              // Keyed 'kind', not 'type' — sendBroadcastMessage below
              // overwrites any 'type' key on the outgoing map with its own
              // protocol literal ('broadcast'), so a same-named key here
              // would always read back as that literal instead of our
              // actual event type.
              final type = payload['kind'] as String? ?? '';
              final data =
                  (payload['payload'] as Map?)?.cast<String, dynamic>() ??
                  <String, dynamic>{};
              _controller.add(RealtimeEvent(type, data));
            },
          )
          .onPresenceSync((_) => _emitPresence())
          .subscribe((subStatus, error) async {
            if (subStatus == RealtimeSubscribeStatus.subscribed) {
              status.value = ConnectionStatus.connected;
              try {
                await channel.track({'role': _role});
              } catch (_) {
                // Presence is a nice-to-have — don't let it block a
                // successful connection.
              }
              await _emitStateSnapshot();
            } else if (subStatus == RealtimeSubscribeStatus.channelError ||
                subStatus == RealtimeSubscribeStatus.timedOut ||
                subStatus == RealtimeSubscribeStatus.closed) {
              _onDropped();
            }
          });
    } catch (_) {
      _onDropped();
    }
  }

  Future<void> _emitStateSnapshot() async {
    try {
      final requestsRes = await _client
          .from('active_ride_requests')
          .select('payload')
          .order('created_at');
      final sosRes = await _client
          .from('active_sos')
          .select('payload')
          .order('created_at');
      final offersRes = await _client
          .from('ride_offers')
          .select('request_id, payload');
      // Isolated from the rest: an older Supabase project without this
      // table yet shouldn't lose the whole snapshot (which BiddingScreen
      // and DriverHomeScreen depend on) over one missing reliability add-on.
      var activeTripIds = <String>[];
      try {
        final tripsRes = await _client.from('active_trips').select('id');
        activeTripIds = (tripsRes as List)
            .map((r) => (r as Map)['id'] as String)
            .toList();
      } catch (_) {}

      final activeRequests = (requestsRes as List)
          .map((r) => (r as Map)['payload'])
          .toList();
      final activeSos = (sosRes as List)
          .map((r) => (r as Map)['payload'])
          .toList();

      final offersByRequest = <String, List<dynamic>>{};
      for (final row in (offersRes as List)) {
        final m = row as Map;
        final requestId = m['request_id'] as String;
        (offersByRequest[requestId] ??= []).add(m['payload']);
      }

      _controller.add(
        RealtimeEvent('state_snapshot', {
          'activeRequests': activeRequests,
          'activeSos': activeSos,
          'offers': offersByRequest,
          'activeTripIds': activeTripIds,
        }),
      );
    } catch (_) {
      // Best-effort — the app still works off live broadcasts even if the
      // initial snapshot fetch fails.
    }
  }

  void _emitPresence() {
    final channel = _channel;
    if (channel == null) return;
    final counts = <String, int>{};
    for (final entry in channel.presenceState()) {
      for (final p in entry.presences) {
        final role = p.payload['role'] as String? ?? 'unknown';
        counts[role] = (counts[role] ?? 0) + 1;
      }
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    _controller.add(
      RealtimeEvent('presence', {'onlineCount': total, 'byRole': counts}),
    );
  }

  void _onDropped() {
    _channel = null;
    status.value = ConnectionStatus.disconnected;
    if (!_manuallyClosed) {
      _retryTimer = Timer(
        const Duration(seconds: 1, milliseconds: 500),
        _open,
      );
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
    if (status.value != ConnectionStatus.connected) return;
    // Fire-and-forget — same contract as before, callers that care about
    // delivery use sendReliably instead.
    unawaited(_performSend(type, payload));
  }

  /// Like [send], but for actions where silently dropping the message would
  /// be a real problem (sending an offer, accepting a ride) rather than
  /// something that self-heals on the next state sync. This waits briefly
  /// for the connection to come back if it's currently down (it retries
  /// automatically), then actually waits for the broadcast + any table
  /// write to complete before reporting success, so the UI can show an
  /// error instead of proceeding as if it worked.
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
    return _performSend(type, payload);
  }

  Future<bool> _performSend(String type, Map<String, dynamic> payload) async {
    final channel = _channel;
    if (channel == null) return false;
    try {
      await channel.sendBroadcastMessage(
        event: _broadcastEvent,
        payload: {'kind': type, 'payload': payload},
      );
      switch (type) {
        case 'ride_request':
          await _client.from('active_ride_requests').upsert({
            'id': payload['id'],
            'payload': payload,
          });
          break;
        case 'ride_countered':
          await _client.from('ride_offers').upsert({
            'request_id': payload['requestId'],
            'driver_id': payload['driverId'],
            'payload': payload,
          });
          break;
        case 'ride_accepted':
          {
            final requestId = payload['requestId'] as Object;
            await _client
                .from('active_ride_requests')
                .delete()
                .eq('id', requestId);
            await _client
                .from('ride_offers')
                .delete()
                .eq('request_id', requestId);
            // Marks the trip as active from here so a client that briefly
            // drops connection mid-trip can tell — via the next
            // state_snapshot — whether it's still on, instead of relying
            // solely on a cancellation broadcast it might have missed.
            // Best-effort in its own try/catch: this is a reliability
            // enhancement, not a requirement for accepting the ride, so it
            // shouldn't be able to make sendReliably report failure back to
            // the rider on an otherwise-successful accept.
            try {
              await _client.from('active_trips').upsert({
                'id': requestId,
                'payload': {'requestId': requestId},
              });
            } catch (_) {}
          }
          break;
        case 'ride_cancelled':
          {
            final requestId = payload['requestId'] as Object;
            await _client
                .from('active_ride_requests')
                .delete()
                .eq('id', requestId);
            await _client
                .from('ride_offers')
                .delete()
                .eq('request_id', requestId);
            try {
              await _client.from('active_trips').delete().eq('id', requestId);
            } catch (_) {}
          }
          break;
        case 'sos_triggered':
          await _client.from('active_sos').upsert({
            'id': payload['id'],
            'payload': payload,
          });
          break;
        case 'sos_resolved':
          await _client.from('active_sos').delete().eq('id', payload['id']);
          break;
        default:
          break; // broadcast-only: driver_arrived, driver_location,
          // ride_offer_declined, ride_bid_updated.
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Registers a rider or driver profile so the admin control room can see
  /// who has signed up. Best-effort — a failure here shouldn't block anyone
  /// from using the app.
  Future<bool> register(Map<String, dynamic> fields) async {
    try {
      final payload = {
        ...fields,
        'registeredAt': DateTime.now().toIso8601String(),
      };
      await _client.from('registrations').insert({'payload': payload});
      final channel = _channel;
      if (channel != null) {
        await channel.sendBroadcastMessage(
          event: _broadcastEvent,
          payload: {'kind': 'user_registered', 'payload': payload},
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRegistrations() async {
    try {
      await SupabaseConfig.ensureInitialized();
      final res = await SupabaseConfig.client
          .from('registrations')
          .select('payload')
          .order('created_at', ascending: false);
      return (res as List)
          .map((r) => ((r as Map)['payload'] as Map).cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }

  void disconnect() {
    _manuallyClosed = true;
    _retryTimer?.cancel();
    final channel = _channel;
    _channel = null;
    if (channel != null) _client.removeChannel(channel);
    status.value = ConnectionStatus.disconnected;
  }
}

String newEventId() => DateTime.now().millisecondsSinceEpoch.toString();
