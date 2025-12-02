// lib/screens/checkout/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart';
import 'package:ao_gosto_app/screens/checkout/steps/step_address.dart';
import 'package:ao_gosto_app/screens/checkout/steps/step_payment.dart';
import 'package:ao_gosto_app/screens/checkout/thank_you_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutController(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutController>(
      builder: (context, c, child) {
        final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

        if (c.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (c.orderId != null) {
          return const ThankYouScreen();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: Column(
            children: [
              // === HEADER ULTRA COMPACTO ===
              _buildUltraCompactHeader(context, c),

              // === BODY ===
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  child: _buildStepContent(c),
                ),
              ),

              // === FOOTER ===
              _buildFooter(c, currency),
            ],
          ),
        );
      },
    );
  }

  // === HEADER ULTRA COMPACTO - TUDO EM UMA LINHA ===
  Widget _buildUltraCompactHeader(BuildContext context, CheckoutController c) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Botão Voltar
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              const SizedBox(width: 16),
              
              // Stepper inline
              Expanded(
                child: _InlineStepper(current: c.currentStep),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(CheckoutController c) {
    return Column(
      children: [
        const SizedBox(height: 16),
        if (c.currentStep == 1) const StepAddress(),
        if (c.currentStep == 2) const StepPayment(),
      ],
    );
  }

 Widget _buildFooter(CheckoutController c, NumberFormat currency) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF71717A),
                    ),
                  ),
                  Text(
                    currency.format(c.total),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF18181B),
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: c.canProceedToPayment && !c.isProcessing
                      ? c.nextStep
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: c.isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          c.finalizarButtonText, // ✅ USANDO O GETTER
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} // ✅ ADICIONE ESTA LINHA AQUI - FECHA A CLASSE _CheckoutView

// ═══════════════════════════════════════════════════════════
//           STEPPER INLINE (UMA LINHA HORIZONTAL)
// ═══════════════════════════════════════════════════════════
class _InlineStepper extends StatelessWidget {
  final int current;
  const _InlineStepper({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'number': '1', 'label': 'Entrega', 'icon': Icons.local_shipping_rounded},
      {'number': '2', 'label': 'Pagamento', 'icon': Icons.credit_card_rounded},
    ];

    return Row(
      children: List.generate(steps.length, (i) {
        final step = i + 1;
        final data = steps[i];
        final isActive = current == step;
        final isDone = current > step;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: _InlineStepItem(
                  number: data['number'] as String,
                  label: data['label'] as String,
                  icon: data['icon'] as IconData,
                  isActive: isActive,
                  isDone: isDone,
                ),
              ),
              
              // Linha conectora
              if (i < steps.length - 1)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _InlineStepItem extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDone;

  const _InlineStepItem({
    required this.number,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Círculo compacto
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: isActive ? (0.95 + (value * 0.05)) : 1.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone || isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        isDone ? Icons.check_rounded : icon,
                        color: isDone || isActive
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.6),
                        size: 16,
                      ),
                    ),
                    if (!isDone)
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              number,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        
        const SizedBox(width: 8),
        
        // Label
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
            letterSpacing: 0.2,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}