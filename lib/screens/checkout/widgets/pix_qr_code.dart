// lib/screens/checkout/widgets/pix_qr_code.dart
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/widgets/progress_timer.dart';

class PixQRCode extends StatelessWidget {
  final String code;
  final DateTime expiresAt;
  final VoidCallback onCopy;

  const PixQRCode({required this.code, required this.expiresAt, required this.onCopy, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('Pague com PIX', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.qr_code_2, size: 120, color: Colors.black54)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.primary),
                  onPressed: onCopy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ProgressTimer(expiresAt: expiresAt),
        ],
      ),
    );
  }
}