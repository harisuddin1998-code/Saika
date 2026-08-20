import 'package:supabase_flutter/supabase_flutter.dart';

/// Saika's own Supabase project — separate from WO-SAFAR, which keeps using
/// its Deno relay untouched. The key below is the public "publishable" key,
/// safe to ship in client code (unlike the secret service-role key, which
/// must never appear here).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://avovhlccycicyxsojbck.supabase.co';
  static const String publishableKey =
      'sb_publishable_rR0wZyVuvHfdKrf7WIPerA_NWPPyudp';

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await Supabase.initialize(url: url, publishableKey: publishableKey);
    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
