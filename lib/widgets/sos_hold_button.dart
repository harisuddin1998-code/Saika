import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Press-and-hold SOS trigger. Requires ~1.4s of continuous hold so an
/// accidental tap in a pocket or bag never fires a false alarm.
class SosHoldButton extends StatefulWidget {
  final VoidCallback onTriggered;
  const SosHoldButton({super.key, required this.onTriggered});

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTriggered();
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 108,
                      height: 108,
                      child: CircularProgressIndicator(
                        value: _controller.value,
                        strokeWidth: 4,
                        backgroundColor: p.sos.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation(p.ink),
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(color: p.sos, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        'HOLD\nFOR SOS',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.sosInk, fontWeight: FontWeight.bold, fontSize: 12.5, height: 1.3),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text('Press and hold 2 seconds', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
