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
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (c.orderId != null) {
          return const ThankYouScreen();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: Column(
            children: [
              // === HEADER ===
              _buildHeader(c),

              // === BODY ===
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                  child: _buildStepContent(c),
                ),
              ),

              // === FOOTER FIXO ===
              _buildFooter(c, currency),
            ],
          ),
        );
      },
    );
  }

  // === HEADER ===
  Widget _buildHeader(CheckoutController c) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: c.prevStep,
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF3F3F46)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Finalizar Compra',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Stepper(current: c.currentStep),
            ],
          ),
        ),
      ),
    );
  }

  // === CONTEÚDO ===
  Widget _buildStepContent(CheckoutController c) {
    return Column(
      children: [
        if (c.currentStep == 1) const StepAddress(),
        if (c.currentStep == 2) const StepPayment(),
      ],
    );
  }

  // === FOOTER FIXO ===
  Widget _buildFooter(CheckoutController c, NumberFormat currency) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Total', style: TextStyle(color: Color(0xFF52525B), fontWeight: FontWeight.w600, fontSize: 18)),
                const Spacer(),
                Text(currency.format(c.total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: c.isProcessing ? null : c.nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: c.isProcessing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : Text(
  _getButtonText(c, currency),
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Colors.white, 
  ),
)
              ),
            ),
            if (c.currentStep == 2)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Ambiente 100% seguro.', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  String _getButtonText(CheckoutController c, NumberFormat currency) {
    if (c.currentStep == 1) return 'Continuar para Pagamento';
    if (c.paymentMethod == 'pix') return 'Gerar QR Code Pix de ${currency.format(c.total)}';
    return 'Confirmar Pedido';
  }
}

// === STEPPER ===
class _Stepper extends StatelessWidget {
  final int current;
  const _Stepper({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = ['Onde e Quando?', 'Como Pagar?'];
    return Row(
      children: steps.asMap().entries.map((e) {
        final i = e.key + 1;
        final label = e.value;
        final isActive = current == i;
        final isDone = current > i;
        return Expanded(
          child: Row(
            children: [
              _StepDot(number: i, isActive: isActive, isDone: isDone),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? const Color(0xFF18181B) : const Color(0xFF71717A),
                    fontSize: 14,
                  ),
                ),
              ),
              if (i < steps.length) Expanded(child: _StepLine(isDone: isDone)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final bool isActive;
  final bool isDone;
  const _StepDot({required this.number, required this.isActive, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDone ? AppColors.primary : (isActive ? Colors.white : const Color(0xFFE5E7EB)),
        shape: BoxShape.circle,
        border: Border.all(color: isActive ? AppColors.primary : Colors.transparent, width: 2),
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text('$number', style: TextStyle(fontWeight: FontWeight.w900, color: isActive ? AppColors.primary : const Color(0xFF6B7280), fontSize: 14)),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isDone;
  const _StepLine({required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Container(height: 2, color: isDone ? AppColors.primary : const Color(0xFFD4D4D8));
  }
}