import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/realtime_service.dart';

/// This rider app instance represents whichever real person registered on
/// this device. Registering saves the profile locally (SharedPreferences) so
/// it's remembered across app restarts, and also posts it to the relay so
/// the admin control room can see who has signed up.
class RiderIdentity {
  RiderIdentity._();

  static String name = '';
  static String phone = '';
  static String initials = '??';
  static bool registered = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('rider_name');
    if (savedName == null || savedName.isEmpty) return;
    name = savedName;
    phone = prefs.getString('rider_phone') ?? '';
    initials = _initialsFrom(savedName);
    registered = true;
  }

  static Future<bool> register(String fullName, String phoneNumber) async {
    final trimmedName = fullName.trim();
    final trimmedPhone = phoneNumber.trim();
    if (trimmedName.isEmpty || trimmedPhone.isEmpty) return false;

    try {
      await http
          .post(
            Uri.parse('${RealtimeService.relayHttpBase}/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': trimmedName,
              'phone': trimmedPhone,
              'role': 'rider',
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Best-effort — still let them in even if the relay is briefly
      // unreachable; their profile is saved locally either way.
    }

    name = trimmedName;
    phone = trimmedPhone;
    initials = _initialsFrom(trimmedName);
    registered = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rider_name', trimmedName);
    await prefs.setString('rider_phone', trimmedPhone);
    return true;
  }
}

String _initialsFrom(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '??';
  if (parts.length == 1) {
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
