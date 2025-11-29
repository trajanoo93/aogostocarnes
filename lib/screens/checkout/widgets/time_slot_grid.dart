// lib/screens/checkout/widgets/time_slot_grid.dart
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart';

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
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Nenhum horário disponível',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF71717A),
            ),
          ),
        ),
      );
    }

    // 2 slots por linha (full width)
    return Column(
      children: List.generate((slots.length / 2).ceil(), (rowIndex) {
        final startIndex = rowIndex * 2;
        final endIndex = (startIndex + 2).clamp(0, slots.length);
        final rowSlots = slots.sublist(startIndex, endIndex);
        
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < (slots.length / 2).ceil() - 1 ? 8 : 0),
          child: Row(
            children: rowSlots.asMap().entries.map((entry) {
              final slot = entry.value;
              final isLast = entry.key == rowSlots.length - 1 && rowSlots.length == 1;
              final active = selectedSlot == slot.id;
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: !isLast && entry.key == 0 ? 8 : 0,
                  ),
                  child: InkWell(
                    onTap: slot.available ? () => onSlotSelected(slot.id) : null,
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          slot.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : const Color(0xFF18181B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}