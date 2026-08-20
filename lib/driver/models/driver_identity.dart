import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/realtime_service.dart';

/// This driver app instance represents whichever real driver registered on
/// this device. Registering saves the profile locally (SharedPreferences) so
/// it's remembered across app restarts, and also posts it to the relay so
/// the admin control room can see who has signed up.
class DriverIdentity {
  DriverIdentity._();

  static String name = '';
  static String phone = '';
  static String initials = '??';
  static String carModel = '';
  static String carColor = 'White';
  static String plate = '';
  static const double rating = 4.9;
  static bool registered = false;

  /// 'female' or 'male'. Male drivers are only ever shown requests where the
  /// rider opted in to "any driver" — see [RideRequest.preferredDriverGender].
  static String gender = 'female';

  /// Only meaningful (and only collected) for male drivers — enforced at
  /// registration to stay in the 45-50 band the service is comfortable with.
  static int age = 0;

  /// Unique ID used to tell drivers apart on the relay (name or phone alone
  /// aren't reliable — two test drivers can share a name). On native builds
  /// this is persisted so it survives the OS killing a backgrounded app —
  /// otherwise a driver whose offer is still pending when Android reclaims
  /// the process would come back with a different ID and the rider's
  /// eventual accept would never match them. On web it's generated fresh
  /// per tab instead: SharedPreferences there is backed by localStorage,
  /// which every tab of the same origin shares, so persisting it would make
  /// two tabs simulating two different drivers collide on one "unique" ID.
  static String deviceId = kIsWeb ? _newSessionId() : '';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!kIsWeb) deviceId = await _ensurePersistedDeviceId(prefs);
    final savedName = prefs.getString('driver_name');
    if (savedName == null || savedName.isEmpty) return;
    name = savedName;
    phone = prefs.getString('driver_phone') ?? '';
    carModel = prefs.getString('driver_car_model') ?? '';
    plate = prefs.getString('driver_plate') ?? '';
    gender = prefs.getString('driver_gender') ?? 'female';
    age = prefs.getInt('driver_age') ?? 0;
    initials = _initialsFrom(savedName);
    registered = true;
  }

  static Future<bool> register({
    required String fullName,
    required String phoneNumber,
    required String carModel,
    required String plate,
    required String gender,
    int age = 0,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedPhone = phoneNumber.trim();
    final trimmedCar = carModel.trim();
    final trimmedPlate = plate.trim();
    if (trimmedName.isEmpty || trimmedPhone.isEmpty) return false;
    if (gender == 'male' && (age < 45 || age > 50)) return false;

    if (!kIsWeb) {
      deviceId = await _ensurePersistedDeviceId(
        await SharedPreferences.getInstance(),
      );
    }

    // Best-effort — still let them in even if this fails; their profile is
    // saved locally either way.
    await RealtimeService.instance.register({
      'name': trimmedName,
      'phone': trimmedPhone,
      'role': 'driver',
      'carModel': trimmedCar,
      'plate': trimmedPlate,
      'gender': gender,
      'age': age,
    });

    name = trimmedName;
    phone = trimmedPhone;
    DriverIdentity.carModel = trimmedCar;
    DriverIdentity.plate = trimmedPlate;
    DriverIdentity.gender = gender;
    DriverIdentity.age = age;
    initials = _initialsFrom(trimmedName);
    registered = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_name', trimmedName);
    await prefs.setString('driver_phone', trimmedPhone);
    await prefs.setString('driver_car_model', trimmedCar);
    await prefs.setString('driver_plate', trimmedPlate);
    await prefs.setString('driver_gender', gender);
    await prefs.setInt('driver_age', age);
    return true;
  }
}

String _newSessionId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
    '${Random().nextInt(1 << 32).toRadixString(36)}';

Future<String> _ensurePersistedDeviceId(SharedPreferences prefs) async {
  final existing = prefs.getString('driver_device_id');
  if (existing != null && existing.isNotEmpty) return existing;
  final id = _newSessionId();
  await prefs.setString('driver_device_id', id);
  return id;
}

String _initialsFrom(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '??';
  if (parts.length == 1) {
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
