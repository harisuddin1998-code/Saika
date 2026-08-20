import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'admin_shell.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Saika', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28)),
                Text('CONTROL ROOM', style: TextStyle(fontFamily: 'monospace', fontSize: 12, letterSpacing: 3, color: p.accent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 28),
                TextField(decoration: const InputDecoration(labelText: 'Operator ID', border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminShell())),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
