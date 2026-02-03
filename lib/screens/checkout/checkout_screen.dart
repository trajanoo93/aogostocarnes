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

  // ✅ Lógica inteligente para o botão Voltar (Físico ou Appbar)
  Future<bool> _onWillPop(BuildContext context, CheckoutController c) async {
    if (c.currentStep > 1) {
      // Se estiver no passo 2, volta para o 1 e NÃO fecha a tela
      c.prevStep();
      return false; // Impede o pop
    }
    return true; // Se estiver no passo 1, deixa fechar
  }

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

        // ✅ PopScope (Novo WillPopScope) para controlar o botão físico do Android
        return PopScope(
          canPop: c.currentStep == 1, // Só deixa fechar se estiver no passo 1
          onPopInvoked: (didPop) {
            if (didPop) return;
            // Se não fechou (estava no passo 2), volta um passo
            c.prevStep();
          },
          child: Scaffold(
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
                _buildFooter(context, c, currency),
              ],
            ),
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
              // ✅ Botão Voltar Inteligente
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
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
              
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _InlineStepper(current: c.currentStep),
                ),
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

  Widget _buildFooter(BuildContext context, CheckoutController c, NumberFormat currency) {
    // Lógica para desabilitar botão visualmente se não puder prosseguir
    final canProceed = c.canProceedToPayment;
    
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
              // Aviso contextual se tentar avançar sem dados
              if (!canProceed && !c.isProcessing && c.currentStep == 2)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getValidationMessage(c),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
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
                  onPressed: c.isProcessing 
                      ? null 
                      : () => _handleButtonPress(context, c),
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
                          c.finalizarButtonText,
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
  
  // Substitua o método _handleButtonPress por este:
  void _handleButtonPress(BuildContext context, CheckoutController c) async {
    if (!c.canProceedToPayment) {
      _showValidationDialog(context, c);
      return;
    }
    
    // ✅ NOVO: Captura erros (como estoque insuficiente)
    try {
      await c.nextStep();
    } catch (e) {
      // Remove "Exception:" do texto se houver
      final message = e.toString().replaceAll("Exception: ", "");
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.red[700]),
              const SizedBox(width: 12),
              const Text('Atenção'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
    }
  }
  
  void _showValidationDialog(BuildContext context, CheckoutController c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Atenção'),
          ],
        ),
        content: Text(_getValidationMessage(c)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  String _getValidationMessage(CheckoutController c) {
    if (c.userPhone.isEmpty || c.userPhone.length < 10) {
      return 'Por favor, adicione um telefone válido';
    }
    
    if (c.deliveryType == DeliveryType.delivery) {
      if (c.selectedAddressId == null) {
        return 'Por favor, selecione um endereço de entrega';
      }
      if (c.deliveryFee < 0) {
        return 'CEP fora da área de entrega. Tente retirar na loja.';
      }
      if (c.deliveryFee < 9.90) {
        return 'Taxa de entrega inválida';
      }
    } else {
      if (c.selectedPickup.isEmpty) {
        return 'Por favor, selecione um local de retirada';
      }
    }
    
    if (c.selectedDate == DateTime(0) || c.selectedTimeSlot == null) {
      return 'Por favor, selecione data e horário';
    }
    
    if (c.paymentMethod.isEmpty) {
      return 'Por favor, selecione uma forma de pagamento';
    }
    
    if (c.needsChange && c.changeForAmount.isEmpty) {
      return 'Por favor, informe o valor para o troco';
    }
    
    return 'Complete todas as informações para continuar';
  }
}

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
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final index = (i ~/ 2) + 1;
          final isDone = current > index;

          return Container(
            width: 32,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDone ? Colors.white : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final step = steps[stepIndex];
        final isActive = current == stepIndex + 1;
        final isDone = current > stepIndex + 1;

        return _InlineStepItem(
          number: step['number'] as String,
          label: step['label'] as String,
          icon: step['icon'] as IconData,
          isActive: isActive,
          isDone: isDone,
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
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone || isActive
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  isDone ? Icons.check_rounded : icon,
                  size: 16,
                  color:
                      isDone || isActive ? AppColors.primary : Colors.white70,
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
                          : Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        number,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: isActive ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}