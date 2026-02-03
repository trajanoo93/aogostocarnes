import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart';
import 'package:ao_gosto_app/screens/checkout/widgets/progress_timer.dart';
import 'package:ao_gosto_app/services/remote_config_service.dart';

class StepPayment extends StatelessWidget {
  const StepPayment({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();

    return Column(
      children: [
        FutureBuilder<RemoteConfig>(
          future: RemoteConfigService.fetchConfig(),
          builder: (context, snapshot) {
            final message = snapshot.data?.customMessage;
            
            if (message == null || !message.enabled || message.message.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CustomMessageBanner(message: message),
            );
          },
        ),
        
        _UltraQuickSummary(),
        
        const SizedBox(height: 12),
        
        _PremiumPaymentMethods(),
        
        const SizedBox(height: 12),
        
        if (c.paymentMethod == 'pix' && c.pixCode != null)
          _ModernPixCard(code: c.pixCode!, expiresAt: c.pixExpiresAt!),
        
        if (c.paymentMethod == 'money')
          _ModernChangeCard(),
        
        if (c.paymentMethod == 'card-on-delivery')
          _ModernCardInfo(),
        
        if (c.paymentMethod == 'voucher')
          _ModernVoucherInfo(),
        
        const SizedBox(height: 20),
      ],
    );
  }
}

class _CustomMessageBanner extends StatelessWidget {
  final CustomMessage message;
  
  const _CustomMessageBanner({required this.message});
  
  Color _getColorByType() {
    switch (message.type) {
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
  
  IconData _getIconByType() {
    switch (message.type) {
      case 'warning':
        return Icons.warning_rounded;
      case 'error':
        return Icons.error_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final color = _getColorByType();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconByType(),
              color: color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withOpacity(0.8),
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

class _UltraQuickSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    
    String locationText = '';
    String detailsText = '';
    
    if (c.deliveryType == DeliveryType.delivery) {
      final address = c.addresses.firstWhere(
        (a) => a.id == c.selectedAddressId,
        orElse: () => c.addresses.first,
      );
      locationText = 'Entregar em';
      detailsText = '${address.street}, ${address.number}';
    } else {
      final pickup = c.pickupLocations[c.selectedPickup];
      locationText = 'Retirar em';
      detailsText = pickup?['name'] ?? '';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDeco(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              c.deliveryType == DeliveryType.delivery
                  ? Icons.local_shipping_rounded
                  : Icons.store_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF71717A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detailsText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          TextButton(
            onPressed: c.prevStep,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text(
              'Editar',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPaymentMethods extends StatefulWidget {
  @override
  State<_PremiumPaymentMethods> createState() => _PremiumPaymentMethodsState();
}

class _PremiumPaymentMethodsState extends State<_PremiumPaymentMethods> {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    
    return FutureBuilder<RemoteConfig>(
      future: RemoteConfigService.fetchConfig(),
      builder: (context, snapshot) {
        final features = snapshot.data?.features;
        final enablePix = features?.enablePixPayment ?? true;
        final enableCardOnline = features?.enableCreditCardOnline ?? false;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: _boxDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Como você quer pagar?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF18181B),
                ),
              ),
              
              const SizedBox(height: 20),
              
              _SectionHeader(
                icon: Icons.smartphone_rounded,
                title: 'Pagamento Online',
              ),
              
              const SizedBox(height: 12),
              
              if (enablePix)
                _ModernPaymentOption(
                  icon: Icons.pix_rounded,
                  title: 'PIX',
                  subtitle: 'Aprovação instantânea',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C9A7), Color(0xFF00B896)],
                  ),
                  active: c.paymentMethod == 'pix',
                  onTap: () {
                    debugPrint('💳 [PAYMENT] Selecionou: PIX');
                    c.paymentMethod = 'pix';
                    if (mounted) setState(() {});
                  },
                ),
              
              if (enablePix) const SizedBox(height: 10),
              
              _ModernPaymentOption(
                icon: Icons.credit_card_rounded,
                title: 'Cartão de Crédito',
                subtitle: enableCardOnline ? 'Pague online' : 'Em breve',
                gradient: LinearGradient(
                  colors: enableCardOnline
                      ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
                      : [Colors.grey[400]!, Colors.grey[300]!],
                ),
                active: enableCardOnline && c.paymentMethod == 'card-online',
                disabled: !enableCardOnline,
                badge: enableCardOnline ? null : _ComingSoonBadge(),
                onTap: () {
                  if (enableCardOnline) {
                    debugPrint('💳 [PAYMENT] Selecionou: Cartão Online');
                    c.paymentMethod = 'card-online';
                    if (mounted) setState(() {});
                  } else {
                    debugPrint('⚠️ [PAYMENT] Cartão Online desabilitado');
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              _SectionHeader(
                icon: Icons.handshake_rounded,
                title: 'Pagar na Entrega',
              ),
              
              const SizedBox(height: 12),
              
              _ModernPaymentOption(
                icon: Icons.payments_rounded,
                title: 'Dinheiro',
                subtitle: 'Pagamento em espécie',
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF059669)],
                ),
                active: c.paymentMethod == 'money',
                onTap: () {
                  debugPrint('💰 [PAYMENT] Selecionou: Dinheiro');
                  c.paymentMethod = 'money';
                  if (mounted) setState(() {});
                },
              ),
              
              const SizedBox(height: 10),
              
              _ModernPaymentOption(
                icon: Icons.credit_card_rounded,
                title: 'Cartão',
                subtitle: 'Débito ou crédito',
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                active: c.paymentMethod == 'card-on-delivery',
                onTap: () {
                  debugPrint('💳 [PAYMENT] Selecionou: Cartão na Entrega');
                  c.paymentMethod = 'card-on-delivery';
                  if (mounted) setState(() {});
                },
              ),
              
              const SizedBox(height: 10),
              
              _ModernPaymentOption(
                icon: Icons.restaurant_rounded,
                title: 'Vale Alimentação',
                subtitle: 'VR, Alelo, Sodexo',
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                ),
                active: c.paymentMethod == 'voucher',
                onTap: () {
                  debugPrint('🎫 [PAYMENT] Selecionou: Voucher');
                  c.paymentMethod = 'voucher';
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  
  const _SectionHeader({
    required this.icon,
    required this.title,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF71717A),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF71717A),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ModernPaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final bool active;
  final bool disabled;
  final Widget? badge;
  final VoidCallback onTap;
  
  const _ModernPaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.active,
    this.disabled = false,
    this.badge,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.05)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? AppColors.primary
                : const Color(0xFFE5E7EB),
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: active ? 1.0 : 0.0),
              builder: (context, value, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: disabled
                        ? null
                        : active
                            ? gradient
                            : null,
                    color: disabled
                        ? Colors.grey[200]
                        : active
                            ? null
                            : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3 * value),
                              blurRadius: 12 * value,
                              offset: Offset(0, 4 * value),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: disabled
                        ? Colors.grey[400]
                        : active
                            ? Colors.white
                            : const Color(0xFF71717A),
                    size: 24,
                  ),
                );
              },
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: disabled
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF18181B),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        badge!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: disabled
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ),
            
            if (!disabled)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : const Color(0xFFD4D4D8),
                    width: 2,
                  ),
                ),
                child: active
                    ? const Center(
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: const Text(
        'Em breve',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ModernPixCard extends StatelessWidget {
  final String code;
  final DateTime expiresAt;
  
  const _ModernPixCard({required this.code, required this.expiresAt});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDeco(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C9A7), Color(0xFF00B896)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C9A7).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pix_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagar com PIX',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    Text(
                      'Copie o código e cole no app do seu banco',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 120,
                  color: Color(0xFF18181B),
                ),
                SizedBox(height: 8),
                Text(
                  'Escaneie com o app do seu banco',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Código PIX copiado!'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text(
                    'Copiar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          ProgressTimer(expiresAt: expiresAt),
        ],
      ),
    );
  }
}

class _ModernChangeCard extends StatefulWidget {
  @override
  State<_ModernChangeCard> createState() => _ModernChangeCardState();
}

class _ModernChangeCardState extends State<_ModernChangeCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final c = context.read<CheckoutController>();
    _controller = TextEditingController(text: c.changeForAmount);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    
    if (c.changeForAmount != _controller.text && !_controller.selection.isValid) {
       _controller.text = c.changeForAmount;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Precisa de troco?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF18181B),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    c.needsChange = false;
                    c.changeForAmount = '';
                    _controller.clear(); 
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: !c.needsChange
                          ? AppColors.primary.withOpacity(0.1)
                          : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !c.needsChange
                            ? AppColors.primary
                            : const Color(0xFFE5E7EB),
                        width: !c.needsChange ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Não preciso',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: !c.needsChange
                              ? AppColors.primary
                              : const Color(0xFF71717A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: InkWell(
                  onTap: () {
                    c.needsChange = true;
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.needsChange
                          ? AppColors.primary.withOpacity(0.1)
                          : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: c.needsChange
                            ? AppColors.primary
                            : const Color(0xFFE5E7EB),
                        width: c.needsChange ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Sim, preciso',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.needsChange
                              ? AppColors.primary
                              : const Color(0xFF71717A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          if (c.needsChange) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Troco para quanto? Ex: 50.00',
                prefixText: 'R\$ ',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(
                  Icons.payments_rounded,
                  color: Color(0xFF71717A),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (v) {
                c.changeForAmount = v;
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ModernCardInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final total = c.total;
    
    String message;
    int parcelas;
    
    if (total >= 300) {
      message = 'Parcele em até 3x sem juros no cartão de crédito';
      parcelas = 3;
    } else if (total >= 200) {
      message = 'Parcele em até 2x sem juros no cartão de crédito';
      parcelas = 2;
    } else {
      message = 'Pagamento à vista no cartão';
      parcelas = 1;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cartão na Entrega',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18181B),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF0284C7),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF075985),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (parcelas > 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${parcelas}x sem juros',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  Text(
                    NumberFormat.simpleCurrency(locale: 'pt_BR')
                        .format(total / parcelas),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModernVoucherInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDeco(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Vale Alimentação',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18181B),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFFEA580C),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Aceitamos os principais vales',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _VoucherBrand('VR'),
                    _VoucherBrand('Alelo'),
                    _VoucherBrand('Sodexo'),
                    _VoucherBrand('Ticket'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherBrand extends StatelessWidget {
  final String name;
  const _VoucherBrand(this.name);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF18181B),
        ),
      ),
    );
  }
}

BoxDecoration _boxDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );