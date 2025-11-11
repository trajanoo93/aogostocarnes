// lib/screens/checkout/steps/step_schedule.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart';
import 'package:ao_gosto_app/screens/checkout/widgets/calendar_widget.dart';
import 'package:ao_gosto_app/screens/checkout/widgets/time_slot_grid.dart';

class StepSchedule extends StatelessWidget {
  const StepSchedule({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agende sua Entrega',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
          ),
          const SizedBox(height: 16),

          // === CALENDÁRIO + SLOTS ===
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === CALENDÁRIO ===
              Expanded(
                flex: 3,
                child: CalendarWidget(
                  selectedDate: c.selectedDate,
                  onDateSelected: (date) {
                    c.selectedDate = date;
                    c.selectedTimeSlot = null;
                  },
                ),
              ),
              const SizedBox(width: 16),

              // === SLOTS ===
              Expanded(
                flex: 2,
                child: TimeSlotGrid(
                  slots: c.getTimeSlots(),
                  selectedSlot: c.selectedTimeSlot,
                  onSlotSelected: (slot) => c.selectedTimeSlot = slot,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // === DATA/HORÁRIO SELECIONADO ===
          if (c.selectedTimeSlot != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFFAF1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF16A34A), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Entrega agendada para ${c.selectedDate.day}/${c.selectedDate.month}/${c.selectedDate.year} - ${c.selectedTimeSlot}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// === ESTILO COMUM ===
BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 2))],
    );