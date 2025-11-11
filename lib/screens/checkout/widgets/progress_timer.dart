// lib/screens/checkout/widgets/progress_timer.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ao_gosto_app/utils/app_colors.dart'; 

class ProgressTimer extends StatefulWidget {
  final DateTime expiresAt;
  const ProgressTimer({required this.expiresAt, super.key});

  @override
  State<ProgressTimer> createState() => _ProgressTimerState();
}

class _ProgressTimerState extends State<ProgressTimer> {
  late Timer _timer;
  double progress = 1.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = widget.expiresAt.difference(DateTime.now()).inSeconds;
      if (diff <= 0) {
        setState(() => progress = 0);
        _timer.cancel();
      } else {
        setState(() => progress = diff / 900);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('O QR Code expira em 15 minutos', style: TextStyle(fontSize: 14, color: Color(0xFF71717A))),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(3)),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                width: MediaQuery.of(context).size.width * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, Colors.red]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}