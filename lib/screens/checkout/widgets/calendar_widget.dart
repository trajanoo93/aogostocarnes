// lib/screens/checkout/widgets/calendar_widget.dart
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart'; // Para isDateUnavailable

class CalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  const CalendarWidget({
    required this.selectedDate,
    required this.onDateSelected,
    super.key,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime displayMonth;

  @override
  void initState() {
    super.initState();
    displayMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _prevMonth() {
    setState(() {
      displayMonth = DateTime(displayMonth.year, displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      displayMonth = DateTime(displayMonth.year, displayMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // Dom = 0

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // === CABEÇALHO DO MÊS ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                '${_monthName(displayMonth.month)} ${displayMonth.year}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // === DIAS DA SEMANA ===
          Row(
            children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // === GRID DE DIAS ===
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, i) {
              if (i < startWeekday) return const SizedBox.shrink();

              final day = i - startWeekday + 1;
              final date = DateTime(displayMonth.year, displayMonth.month, day);

              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              final isSelected = date.year == widget.selectedDate.year &&
                  date.month == widget.selectedDate.month &&
                  date.day == widget.selectedDate.day;

              final isPast = date.isBefore(DateTime(today.year, today.month, today.day));

              // Usa o método estático do controller
              final isUnavailable = CheckoutController.isDateUnavailable(date);

              final bool isDisabled = isPast || isUnavailable;

              return GestureDetector(
                onTap: isDisabled ? null : () => widget.onDateSelected(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDisabled ? const Color(0xFFB3B3B3) : const Color(0xFF18181B)),
                        fontSize: 13,
                        decoration: isUnavailable ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return months[month - 1];
  }
}