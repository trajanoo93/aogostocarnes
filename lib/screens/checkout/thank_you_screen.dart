// lib/screens/checkout/thank_you_screen.dart - VERSÃO FINAL COM STREAMBUILDER
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart';
import 'package:ao_gosto_app/api/firestore_service.dart';
import 'package:ao_gosto_app/models/order_model.dart';
import 'dart:async';

class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    final address = c.addresses.firstWhere(
      (a) => a.id == c.selectedAddressId,
      orElse: () => c.addresses.first,
    );
    final pickup = c.pickupLocations[c.selectedPickup];

    final whatsappMessage = Uri.encodeComponent(
      'Oi! Fiz um pedido no app (#${c.orderId}) e tenho uma dúvida. Pode me ajudar?',
    );
    final whatsappUrl = 'https://wa.me/5531997682271?text=$whatsappMessage';

    // ✅ Se PIX, mostra interface dedicada
    if (c.paymentMethod == 'pix' && c.pixCode != null) {
      return _PixThankYouScreen(
  orderId: c.orderId!,
  pixCode: c.pixCode!,
  expiresAt: DateTime.now().add(const Duration(minutes: 15)),  // Força 15 minutos na UI, ignora valor real
  total: currency.format(c.total),
  whatsappUrl: whatsappUrl,
);
    }

    // ✅ Interface padrão para outros métodos
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === ÍCONE DE SUCESSO ===
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // === TÍTULO + NÚMERO DO PEDIDO ===
              Center(
                child: Text(
                  'Pedido #${c.orderId}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18181B),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Center(
                child: Text(
                  'Seu pedido foi realizado com sucesso!\nEstamos preparando tudo para que sua experiência seja incrível!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF71717A),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // === RESUMO DO PEDIDO ===
              Container(
                decoration: _cardDeco(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo do Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow('Subtotal', currency.format(c.subtotal)),
                    _SummaryRow(
                      'Taxa de Entrega',
                      currency.format(c.deliveryType == DeliveryType.delivery ? c.deliveryFee : 0.0),
                    ),
                    const Divider(height: 26),
                    _SummaryRow(
                      'Total',
                      currency.format(c.total),
                      bold: true,
                      big: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // === DETALHES DA ENTREGA/RETIRADA ===
              Container(
                decoration: _cardDeco(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          c.deliveryType == DeliveryType.delivery
                              ? Icons.local_shipping_rounded
                              : Icons.store_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          c.deliveryType == DeliveryType.delivery ? 'Entrega' : 'Retirada',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFAF1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF16A34A),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.deliveryType == DeliveryType.delivery
                                ? 'Será entregue em:'
                                : 'Pronto para retirada em:',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF166534),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.deliveryType == DeliveryType.delivery
                                ? '${address.street}, ${address.number}\n${address.neighborhood}, ${address.city} - ${address.state}'
                                : '${pickup?['name']}\n${pickup?['address']}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF18181B),
                            ),
                          ),
                          if (c.deliveryType == DeliveryType.pickup)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                '📱 Por favor, apresente o número do seu pedido ao chegar.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF71717A),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // === OBSERVAÇÕES (SE HOUVER) ===
              if (c.orderNotes.isNotEmpty)
                Container(
                  decoration: _cardDeco(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            color: Color(0xFF71717A),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Observações',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          '"${c.orderNotes}"',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // === BOTÕES DE AÇÃO ===
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(whatsappUrl)),
                      icon: const Icon(Icons.chat_rounded, color: Colors.white),
                      label: const Text(
                        'Falar no WhatsApp',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Voltar para o Início',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//       PIX THANK YOU SCREEN COM STREAMBUILDER REAL-TIME
// ═══════════════════════════════════════════════════════════
class _PixThankYouScreen extends StatefulWidget {
  final String orderId;
  final String pixCode;
  final DateTime expiresAt;
  final String total;
  final String whatsappUrl;

  const _PixThankYouScreen({
    required this.orderId,
    required this.pixCode,
    required this.expiresAt,
    required this.total,
    required this.whatsappUrl,
  });

  @override
  State<_PixThankYouScreen> createState() => _PixThankYouScreenState();
}

class _PixThankYouScreenState extends State<_PixThankYouScreen> {
  String? _customerPhone;

  @override
  void initState() {
    super.initState();
    _loadCustomerPhone();
  }

  Future<void> _loadCustomerPhone() async {
    final sp = await SharedPreferences.getInstance();
    final phone = sp.getString('customer_phone');
    if (phone != null && mounted) {
      setState(() {
        _customerPhone = phone.replaceAll(RegExp(r'\D'), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ AGUARDA TELEFONE
    if (_customerPhone == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ✅ STREAMBUILDER PARA ESCUTAR STATUS EM TEMPO REAL
    return StreamBuilder<AppOrder?>(
      stream: FirestoreService().getOrderById(widget.orderId),
      builder: (context, snapshot) {
        // Extrai status
        final status = snapshot.data?.status ?? '-';

        // ✅ SE PAGO → MOSTRA CONFIRMAÇÃO
        if (status == 'processing') {
          return _buildPaymentConfirmed();
        }

        // ✅ AGUARDANDO PAGAMENTO
        return _buildPixPending();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //                  PAGAMENTO CONFIRMADO
  // ═══════════════════════════════════════════════════════════
  Widget _buildPaymentConfirmed() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Ícone de sucesso
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF059669)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // ✅ Título
                const Text(
                  '✅ Pagamento Confirmado!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18181B),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Subtítulo
                Text(
                  'Pedido #${widget.orderId}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Seu pedido está sendo preparado\ne logo estará a caminho!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF71717A),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // ✅ Botão voltar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Voltar para o Início',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //                  AGUARDANDO PAGAMENTO PIX
  // ═══════════════════════════════════════════════════════════
  Widget _buildPixPending() {
  return Scaffold(
    backgroundColor: const Color(0xFFFAFAFA),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ✅ HEADER LIMPO (sem fundo verde estridente)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ✅ Ícone QR Code discreto
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ✅ Número do pedido + botão copiar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Pedido ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      Text(
                        '#${widget.orderId}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // ✅ Botão copiar ID
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.orderId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text('ID copiado!'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.content_copy_rounded,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        tooltip: 'Copiar ID',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // ✅ Total (discreto)
                  Text(
                    'Total: ${widget.total}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // === CARD DO PIX (mantém como estava) ===
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.pix_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pagar com PIX',
                              style: TextStyle(
                                fontSize: 18,
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

                  const SizedBox(height: 24),

                  // === CÓDIGO PIX ===
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        SelectableText(
                          widget.pixCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF18181B),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.pixCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text(
                                        'Código PIX copiado!',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            label: const Text(
                              'Copiar Código PIX',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // === TIMER ===
                  _PremiumPixTimer(expiresAt: widget.expiresAt),

                  const SizedBox(height: 20),

                  // === INSTRUÇÕES ===
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Como pagar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF075985),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Copie o código PIX acima\n'
                          '2. Abra o app do seu banco\n'
                          '3. Escolha "Pix Copia e Cola"\n'
                          '4. Cole o código e confirme',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: Color(0xFF075985),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // === BOTÕES ===
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(widget.whatsappUrl)),
                    icon: const Icon(Icons.chat_rounded, size: 22),
                    label: const Text(
                      'Dúvidas? Fale no WhatsApp',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF18181B),
                      side: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Voltar para o Início',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
} 

} 


// ═══════════════════════════════════════════════════════════
//            TIMER PREMIUM COM ANIMAÇÃO
// ═══════════════════════════════════════════════════════════
class _PremiumPixTimer extends StatefulWidget {
  final DateTime expiresAt;
  const _PremiumPixTimer({required this.expiresAt});

  @override
  State<_PremiumPixTimer> createState() => _PremiumPixTimerState();
}

class _PremiumPixTimerState extends State<_PremiumPixTimer> {
  late Timer _timer;
  int _remainingSeconds = 0;
  double _progress = 1.0;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    final diff = widget.expiresAt.difference(DateTime.now()).inSeconds;
    
    if (diff <= 0) {
      setState(() {
        _remainingSeconds = 0;
        _progress = 0;
      });
      _timer.cancel();
    } else {
      setState(() {
        _remainingSeconds = diff;
        _progress = diff / 900; // 60 minutos
      });
    }
  }

  String get _timeText {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color get _progressColor {
    if (_progress > 0.5) return const Color(0xFF00C9A7);
    if (_progress > 0.25) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tempo restante',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF71717A),
              ),
            ),
            Text(
              _timeText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _progressColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                width: MediaQuery.of(context).size.width * _progress * 0.85,
                decoration: BoxDecoration(
                  color: _progressColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: _progressColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          _remainingSeconds > 0
              ? 'Pague dentro do prazo para garantir seu pedido'
              : 'PIX expirado! Entre em contato pelo WhatsApp',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: _remainingSeconds > 0
                ? const Color(0xFF71717A)
                : const Color(0xFFEF4444),
            fontWeight: _remainingSeconds > 0
                ? FontWeight.w500
                : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//                    WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════
class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold, big;
  const _SummaryRow(this.label, this.value, {this.bold = false, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF71717A), fontSize: 15),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              fontSize: big ? 20 : 15,
              color: const Color(0xFF18181B),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        )
      ],
    );