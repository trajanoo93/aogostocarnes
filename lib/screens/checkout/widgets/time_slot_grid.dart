// lib/screens/checkout/widgets/time_slot_grid.dart
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart'; // Para TimeSlot

class TimeSlotGrid extends StatelessWidget {
  final List<TimeSlot> slots;
  final String? selectedSlot;
  final ValueChanged<String> onSlotSelected;

  const TimeSlotGrid({
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Não há horários disponíveis',
            style: TextStyle(fontSize: 16, color: Color(0xFF71717A)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: slots.map((slot) {
        final active = selectedSlot == slot.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: slot.available ? () => onSlotSelected(slot.id) : null,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: active ? AppColors.primary : const Color(0xFFE5E7EB), width: 1.5),
              ),
              child: Center(
                child: Text(
                  slot.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : const Color(0xFF18181B),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}