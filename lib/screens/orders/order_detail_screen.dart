// lib/screens/orders/order_detail_screen.dart - VERSÃO FINAL CORRIGIDA
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ao_gosto_app/models/order_model.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/api/product_image_service.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════
//  🎯 MAPEAMENTO INTELIGENTE DE STATUS
// ═══════════════════════════════════════════════════════════

class OrderStatusInfo {
  final String displayName;
  final List<TextSpan> richDescription;
  final IconData icon;
  final Color color;

  const OrderStatusInfo({
    required this.displayName,
    required this.richDescription,
    required this.icon,
    required this.color,
  });

  static OrderStatusInfo fromBackendStatus(String backendStatus) {
    final status = backendStatus.toLowerCase().trim();
    
    switch (status) {
      case 'pendente':
      case 'pending':
        return OrderStatusInfo(
          displayName: 'Aguardando Pagamento',
          richDescription: [
            const TextSpan(text: 'Estamos aguardando a '),
            const TextSpan(
              text: 'confirmação do seu pagamento',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: ' para iniciar o preparo. Assim que confirmarmos, '),
            const TextSpan(
              text: 'começaremos imediatamente',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: '! 🔄'),
          ],
          icon: Icons.schedule_rounded,
          color: AppColors.primary,
        );
      
      case 'processando':
      case 'processing':
      case 'recebido':
        return OrderStatusInfo(
          displayName: 'Recebido',
          richDescription: [
            const TextSpan(text: 'Seu pedido foi '),
            const TextSpan(
              text: 'confirmado com sucesso',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: '! Nossa equipe já recebeu e '),
            const TextSpan(
              text: 'em breve começaremos a preparar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: ' tudo com muito carinho 🎉'),
          ],
          icon: Icons.check_circle_rounded,
          color: AppColors.primary,
        );
      
      case 'registrado':
      case 'registered':
      case 'montado':
      case 'em preparo':
        return OrderStatusInfo(
          displayName: 'Montado',
          richDescription: [
            const TextSpan(text: 'Estamos '),
            const TextSpan(
              text: 'separando e embalando',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: ' seus produtos com todo cuidado para garantir que '),
            const TextSpan(
              text: 'chegue perfeito',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: '! 📦'),
          ],
          icon: Icons.inventory_2_rounded,
          color: AppColors.primary,
        );
      
      case 'saiu pra entrega':
      case 'saiu para entrega':
      case 'a caminho':
      case 'out_for_delivery':
        return OrderStatusInfo(
          displayName: 'Saiu pra Entrega',
          richDescription: [
            const TextSpan(text: 'Seu pedido '),
            const TextSpan(
              text: 'já saiu para entrega',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: ' e está '),
            const TextSpan(
              text: 'a caminho do seu endereço',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: '! Prepare-se para receber 🏍️💨'),
          ],
          icon: Icons.two_wheeler_rounded,
          color: AppColors.primary,
        );
      
      case 'concluído':
      case 'completed':
      case 'entregue':
        return const OrderStatusInfo(
          displayName: 'Concluído',
          richDescription: [
            TextSpan(text: 'Pedido '),
            TextSpan(
              text: 'entregue com sucesso',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: '! Esperamos que tenha gostado de tudo. '),
            TextSpan(
              text: 'Obrigado pela preferência',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: '! ❤️'),
          ],
          icon: Icons.done_all_rounded,
          color: Color(0xFF10B981),
        );
      
      case 'agendado':
      case 'scheduled':
        return OrderStatusInfo(
          displayName: 'Agendado',
          richDescription: [
            const TextSpan(text: 'Seu pedido está '),
            const TextSpan(
              text: 'programado para ser entregue',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: ' na '),
            const TextSpan(
              text: 'data e horário escolhidos',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: '. Fique tranquilo! 📅'),
          ],
          icon: Icons.event_rounded,
          color: AppColors.primary,
        );
      
      case 'cancelado':
      case 'cancelled':
        return const OrderStatusInfo(
          displayName: 'Cancelado',
          richDescription: [
            TextSpan(text: 'Este pedido foi '),
            TextSpan(
              text: 'cancelado',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: '. Se tiver alguma dúvida, '),
            TextSpan(
              text: 'entre em contato conosco',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' pelo WhatsApp 💬'),
          ],
          icon: Icons.cancel_rounded,
          color: Color(0xFFEF4444),
        );
      
      default:
        return OrderStatusInfo(
          displayName: 'Processando',
          richDescription: const [
            TextSpan(text: 'Estamos '),
            TextSpan(
              text: 'verificando seu pedido',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: '...'),
          ],
          icon: Icons.sync_rounded,
          color: AppColors.primary,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  🎨 PÁGINA PRINCIPAL
// ═══════════════════════════════════════════════════════════

class OrderDetailScreen extends StatefulWidget {
  final AppOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> 
    with TickerProviderStateMixin {
  int? _userRating;
  bool _isSubmittingRating = false;
  late AnimationController _dotsController;
  final ProductImageService _imageService = ProductImageService();
  final Map<String, String> _productImages = {};
  
  String? _deliveryType;
  DateTime? _scheduledDate;
  String? _scheduledWindow;

  @override
  void initState() {
    super.initState();
    _userRating = widget.order.rating;
    
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _loadProductImages();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(widget.order.id)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _deliveryType = data['tipo_entrega'] as String?;
          _scheduledWindow = data['agendamento']?['janela_texto'] as String?;
          
          final agendamentoData = data['agendamento']?['data'];
          if (agendamentoData is Timestamp) {
            _scheduledDate = agendamentoData.toDate();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar detalhes: $e');
    }
  }

  Future<void> _loadProductImages() async {
    for (final item in widget.order.items) {
      final imageUrl = await _imageService.getProductImage(item.name);
      if (mounted) {
        setState(() {
          _productImages[item.name] = imageUrl;
        });
      }
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _submitRating(int rating) async {
    setState(() {
      _isSubmittingRating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(widget.order.id)
          .update({'rating': rating});

      setState(() {
        _userRating = rating;
        _isSubmittingRating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Obrigado pela sua avaliação!',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmittingRating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Erro ao enviar avaliação. Tente novamente.',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final phone = '553134613297';
    final message = Uri.encodeComponent(
      'Olá 👋, acabei de fazer o pedido #${widget.order.id} no App e gostaria de tirar uma dúvida'
    );
    final url = 'https://wa.me/$phone?text=$message';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getStatusIndex(String status) {
    final normalizedStatus = OrderStatusInfo.fromBackendStatus(status).displayName;
    
    if (normalizedStatus == 'Aguardando Pagamento') return 0;
    if (normalizedStatus == 'Recebido') return 0;
    if (normalizedStatus == 'Montado') return 1;
    if (normalizedStatus == 'Saiu pra Entrega') return 2;
    if (normalizedStatus == 'Concluído') return 3;
    if (normalizedStatus == 'Agendado') return 0;
    
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = OrderStatusInfo.fromBackendStatus(widget.order.status);
    final currentStatusIndex = _getStatusIndex(widget.order.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // HEADER
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pedido #${widget.order.id}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              
                              Text(
                                statusInfo.displayName,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.2,
                                ),
                              ),
                              
                              const SizedBox(height: 4),
                              
                              // ✅ DATA/HORA DE CRIAÇÃO
                              Text(
                                '${DateFormat('dd/MM/yyyy').format(widget.order.date)} às ${DateFormat('HH:mm').format(widget.order.date)}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.7),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // TIMELINE
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildModernStatusTracker(currentStatusIndex, statusInfo),
            ),
          ),

          // BALÃO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: statusInfo.color.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.support_agent_rounded,
                          color: statusInfo.color,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: AnimatedBuilder(
                          animation: _dotsController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(3, (index) {
                                  final delay = index * 0.33;
                                  final opacity = (((_dotsController.value + delay) % 1.0) * 2 - 1).abs();
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 1),
                                    child: Opacity(
                                      opacity: 0.3 + (opacity * 0.7),
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: statusInfo.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          children: statusInfo.richDescription,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ AGENDAMENTO (SÓ DATA + SLOT)
          if (_scheduledDate != null || _deliveryType != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      if (_deliveryType != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _deliveryType == 'pickup'
                                ? const Color(0xFFF59E0B).withOpacity(0.1)
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _deliveryType == 'pickup'
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _deliveryType == 'pickup'
                                    ? Icons.store_rounded
                                    : Icons.delivery_dining_rounded,
                                size: 16,
                                color: _deliveryType == 'pickup'
                                    ? const Color(0xFFF59E0B)
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _deliveryType == 'pickup' ? 'RETIRADA' : 'ENTREGA',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _deliveryType == 'pickup'
                                      ? const Color(0xFFF59E0B)
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      if (_scheduledDate != null) ...[
                        if (_deliveryType != null) const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_rounded,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Agendado para',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // ✅ SÓ DATA (SEM HORÁRIO)
                              Text(
                                DateFormat('dd/MM/yyyy').format(_scheduledDate!),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[900],
                                ),
                              ),
                              // ✅ JANELA (SLOT)
                              if (_scheduledWindow != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _scheduledWindow!,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // AVALIAÇÃO
          if (widget.order.status == 'Concluído' || widget.order.status == 'Entregue')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildRatingSection(),
              ),
            ),

          // ITENS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildSection(
                title: 'Itens do Pedido',
                icon: Icons.shopping_bag_rounded,
                child: Column(
                  children: widget.order.items.asMap().entries.map((entry) {
                    final item = entry.value;
                    final isLast = entry.key == widget.order.items.length - 1;

                    return Column(
                      children: [
                        _buildOrderItem(item),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Colors.grey[200]),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // ENDEREÇO + PAGAMENTO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSection(
                      title: 'Endereço',
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.primary,
                      child: Text(
                        '${widget.order.address.street}, ${widget.order.address.number}\n'
                        '${widget.order.address.complement.isNotEmpty ? '${widget.order.address.complement}\n' : ''}'
                        '${widget.order.address.neighborhood}\n'
                        '${widget.order.address.city} - ${widget.order.address.state}\n'
                        '${widget.order.address.cep}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSection(
                      title: 'Pagamento',
                      icon: Icons.payment_rounded,
                      iconColor: AppColors.primary,
                      child: _buildPaymentBadge(widget.order.payment.type),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RESUMO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildSection(
                title: 'Resumo',
                icon: Icons.receipt_long_rounded,
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', widget.order.subtotal),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Taxa de entrega', widget.order.deliveryFee),
                    
                    if (widget.order.discount > 0) ...[
                      const SizedBox(height: 12),
                      _buildSummaryRow('Desconto', -widget.order.discount, isDiscount: true),
                    ],
                    
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Total', widget.order.total, isTotal: true),
                  ],
                ),
              ),
            ),
          ),

          // BOTÃO WHATSAPP
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: ElevatedButton.icon(
                onPressed: _openWhatsApp,
                icon: const Icon(Icons.chat_rounded, size: 20),
                label: const Text(
                  'Pedir Ajuda',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusTracker(int currentIndex, OrderStatusInfo currentStatusInfo) {
    final statuses = [
      ('Recebido', Icons.check_circle_rounded),
      ('Montado', Icons.inventory_2_rounded),
      ('A Caminho', Icons.two_wheeler_rounded),
      ('Concluído', Icons.done_all_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acompanhe seu pedido',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: List.generate(statuses.length, (index) {
              final isActive = index <= currentIndex;
              final isCurrent = index == currentIndex;
              final status = statuses[index];
              
              final iconColor = isActive ? AppColors.primary : Colors.grey[300]!;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            width: isCurrent ? 64 : (isActive ? 52 : 44),
                            height: isCurrent ? 64 : (isActive ? 52 : 44),
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              status.$2,
                              color: isActive ? Colors.white : Colors.grey[500],
                              size: isCurrent ? 32 : (isActive ? 26 : 22),
                            ),
                          ),
                        ),

                        if (index < statuses.length - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: List.generate(statuses.length, (index) {
              final status = statuses[index];
              final isActive = index <= currentIndex;
              final isCurrent = index == currentIndex;
              
              return Expanded(
                child: Text(
                  status.$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isCurrent ? 11 : 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.grey[900] : Colors.grey[500],
                    letterSpacing: 0,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                _userRating != null
                    ? 'Sua avaliação'
                    : 'Avalie sua experiência',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isSelected = _userRating != null && starValue <= _userRating!;

              return GestureDetector(
                onTap: _isSubmittingRating ? null : () => _submitRating(starValue),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    size: 40,
                    color: isSelected ? Colors.amber : Colors.grey[300],
                  ),
                ),
              );
            }),
          ),
          if (_isSubmittingRating) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    IconData? icon,
    Color? iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: iconColor ?? Colors.grey[600]),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    final imageUrl = _productImages[item.name];
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.restaurant,
                      color: Colors.grey[400],
                    ),
                  ),
                )
              : Icon(Icons.restaurant, color: Colors.grey[400]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Qtd: ${item.quantity}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'R\$ ${(item.price * item.quantity).toStringAsFixed(2).replaceAll('.', ',')}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBadge(String type) {
    IconData paymentIcon;
    String paymentLabel;
    
    final normalizedType = type.toLowerCase();
    
    if (normalizedType.contains('pix')) {
      paymentIcon = Icons.pix_rounded;
      paymentLabel = 'Pix';
    } else if (normalizedType.contains('money') || normalizedType.contains('dinheiro')) {
      paymentIcon = Icons.payments_rounded;
      paymentLabel = 'Dinheiro';
    } else if (normalizedType.contains('card') || normalizedType.contains('cartão')) {
      paymentIcon = Icons.credit_card_rounded;
      paymentLabel = 'Cartão';
    } else if (normalizedType.contains('voucher') || normalizedType.contains('vale')) {
      paymentIcon = Icons.card_giftcard_rounded;
      paymentLabel = 'Vale';
    } else {
      paymentIcon = Icons.credit_card_rounded;
      paymentLabel = type;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paymentIcon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            paymentLabel,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: Colors.grey[isTotal ? 900 : 600],
          ),
        ),
        Text(
          value == 0 && label.contains('entrega')
              ? 'Grátis'
              : 'R\$ ${value.abs().toStringAsFixed(2).replaceAll('.', ',')}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            color: isDiscount
                ? const Color(0xFF10B981)
                : (value == 0 && label.contains('entrega'))
                    ? const Color(0xFF10B981)
                    : isTotal
                        ? AppColors.primary
                        : Colors.grey[900],
          ),
        ),
      ],
    );
  }
}