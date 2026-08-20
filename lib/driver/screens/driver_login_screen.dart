import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/saika_pattern.dart';
import '../models/driver_identity.dart';
import 'driver_verify_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _carCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'female';
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _carCtrl.dispose();
    _plateCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _carCtrl.text.trim().isEmpty ||
        _plateCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    var age = 0;
    if (_gender == 'male') {
      age = int.tryParse(_ageCtrl.text.trim()) ?? -1;
      if (age < 45 || age > 50) {
        setState(
          () => _error = 'Male drivers must be between 45 and 50 years old',
        );
        return;
      }
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    final ok = await DriverIdentity.register(
      fullName: _nameCtrl.text,
      phoneNumber: _phoneCtrl.text,
      carModel: _carCtrl.text,
      plate: _plateCtrl.text,
      gender: _gender,
      age: age,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _submitting = false;
        _error = 'Could not register — please check your details';
      });
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DriverVerifyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SaikaBand(height: 28),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DRIVER REGISTRATION',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          letterSpacing: 1.4,
                          color: p.safe,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tell us who you are',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'I AM A',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _GenderCard(
                              label: 'Female driver',
                              icon: Icons.woman_outlined,
                              selected: _gender == 'female',
                              onTap: () => setState(() => _gender = 'female'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _GenderCard(
                              label: 'Male driver',
                              icon: Icons.man_outlined,
                              selected: _gender == 'male',
                              onTap: () => setState(() => _gender = 'male'),
                            ),
                          ),
                        ],
                      ),
                      if (_gender == 'male') ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _ageCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            hintText: 'Must be between 45 and 50',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'For riders\' comfort, male drivers on Saika are only accepted between the ages of 45 and 50, and only appear for rides where the passenger has chosen "any driver".',
                          style: TextStyle(fontSize: 11, color: p.muted),
                        ),
                      ],
                      const SizedBox(height: 18),
                      TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: '03xx-xxxxxxx',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _carCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Car model',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _plateCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Plate number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.privacy_tip_outlined,
                            size: 14,
                            color: p.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Your details are used only to verify your registration and are never shown to riders beyond your name, car and rating.',
                              style: TextStyle(fontSize: 11, color: p.muted),
                            ),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: TextStyle(color: p.sos, fontSize: 12.5),
                        ),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: p.safe,
                          foregroundColor: p.safeInk,
                        ),
                        onPressed: _submitting ? null : _register,
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Register & continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.14) : p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? p.accent : p.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? p.accent : p.muted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? p.accent : p.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
