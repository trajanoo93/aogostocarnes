// lib/screens/orders/orders_screen.dart - VERSÃO CORRIGIDA

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/models/order_model.dart';
import 'package:ao_gosto_app/screens/orders/order_detail_screen.dart';
import 'package:ao_gosto_app/api/firestore_service.dart';
import 'package:ao_gosto_app/state/customer_provider.dart';
import 'package:ao_gosto_app/api/product_image_service.dart'; // ✅ ADICIONA

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  String? _customerId;
  bool _isLoading = true;

  late AnimationController _fadeController;
  late AnimationController _arrowController;
  late Animation<double> _arrowAnimation;
  
  // ✅ SERVIÇO DE IMAGENS
  final ProductImageService _imageService = ProductImageService();
  final Map<String, Map<String, String>> _orderImages = {}; // {orderId: {productName: imageUrl}}

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _arrowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -8)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -8, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_arrowController);

    _loadCustomerId();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerId() async {
    try {
      final sp = await SharedPreferences.getInstance();
      
      String? phone = sp.getString('customer_phone');
      
      if (phone == null || phone.isEmpty) {
        final customerProv = CustomerProvider.instance;
        
        if (customerProv.customer == null) {
          final name = sp.getString('customer_name');
          final fallbackPhone = sp.getString('user_phone');
          
          if (fallbackPhone != null && name != null) {
            await customerProv.loadOrCreateCustomer(
              name: name,
              phone: fallbackPhone,
            );
          }
        }
        
        phone = customerProv.customer?.phone;
        
        if (phone != null && phone.isNotEmpty) {
          await sp.setString('customer_phone', phone);
        }
      }

      if (phone == null || phone.isEmpty) {
        if (mounted) {
          setState(() {
            _customerId = null;
            _isLoading = false;
          });
        }
        return;
      }

      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

      if (mounted) {
        setState(() {
          _customerId = cleanPhone;
          _isLoading = false;
        });

        _fadeController.forward();

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _arrowController.repeat();
          }
        });
      }
    } catch (e) {
      print('❌ ERRO ao carregar customer_id: $e');
      if (mounted) {
        setState(() {
          _customerId = null;
          _isLoading = false;
        });
      }
    }
  }

  // ✅ BUSCA IMAGENS DOS PRODUTOS DO PEDIDO
  Future<void> _loadOrderImages(AppOrder order) async {
    if (_orderImages.containsKey(order.id)) return; // Já carregou
    
    final images = <String, String>{};
    for (final item in order.items.take(4)) { // Só as 4 primeiras
      final imageUrl = await _imageService.getProductImage(item.name);
      images[item.name] = imageUrl;
    }
    
    if (mounted) {
      setState(() {
        _orderImages[order.id] = images;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} • '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_customerId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _buildErrorState(),
      );
    }

    return StreamBuilder<List<AppOrder>>(
      stream: FirestoreService().getCustomerOrders(_customerId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: _buildErrorState(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(context),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: _buildEmptyStateProfessional(context),
          );
        }

        final orders = snapshot.data!;
        
        // ✅ CARREGA IMAGENS DOS PEDIDOS
        for (final order in orders) {
          _loadOrderImages(order);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context),
          body: FadeTransition(
            opacity: _fadeController,
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                itemCount: orders.length,
                itemBuilder: (context, i) => _buildOrderCard(orders[i], i),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meus Pedidos',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.grey[900],
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Acompanhe suas entregas',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateProfessional(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final categoriasIconCenterX = size.width * 0.15;
    const baseBottom = 72.0;
    final arrowBottom = baseBottom + bottomPadding;

    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Lottie.asset(
                      'assets/lottie/empty_box.json',
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                      repeat: false,
                    ),
                  ),

                  const SizedBox(height: 40),

                  FadeTransition(
                    opacity: _fadeController,
                    child: Text(
                      'Nenhum pedido ainda',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[900],
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  FadeTransition(
                    opacity: _fadeController,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                          height: 1.5,
                          letterSpacing: -0.2,
                        ),
                        children: const [
                          TextSpan(text: 'Que tal pedir sua '),
                          TextSpan(
                            text: 'Caixinha Laranja',
                            style: TextStyle(
                              color: Color(0xFFFA4815),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: '?'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: arrowBottom,
            left: categoriasIconCenterX - 24,
            child: FadeTransition(
              opacity: _fadeController,
              child: AnimatedBuilder(
                animation: _arrowAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _arrowAnimation.value),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explore as categorias',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary.withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 28,
                      color: AppColors.primary,
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 24),
              Text(
                'Algo deu errado',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Por favor, tente novamente',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _loadCustomerId(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  🎴 CARD DE PEDIDO (VERSÃO CORRIGIDA)
  // ═══════════════════════════════════════════════════════════
  Widget _buildOrderCard(AppOrder order, int index) {
    final displayStatus = _getDisplayStatus(order.status);
    final style = _getStatusStyle(displayStatus);
    final statusIcon = _getStatusIcon(displayStatus);
    
    final isCompleted = order.status == 'Concluído' || order.status == 'Entregue';

    final itemPreview = order.items.isEmpty
        ? 'Sem itens'
        : '${order.items[0].name}'
            '${order.items.length > 1 ? ' + ${order.items.length - 1} item${order.items.length > 2 ? 's' : ''}' : ''}';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: order),
              ),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${order.id}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(order.date),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // ✅ IMAGENS REAIS DOS PRODUTOS
                  Row(
                    children: [
                      ...order.items.take(4).map((item) {
                        final imageUrl = _orderImages[order.id]?[item.name];
                        
                        return Container(
                          width: 52,
                          height: 52,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.restaurant,
                                      color: Colors.grey[400],
                                      size: 24,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.restaurant,
                                  color: Colors.grey[400],
                                  size: 24,
                                ),
                        );
                      }),
                      if (order.items.length > 4)
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+${order.items.length - 4}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemPreview,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.items.length} ${order.items.length == 1 ? 'item' : 'itens'}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // ✅ RATING (SE CONCLUÍDO)
                  if (isCompleted && order.rating != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < order.rating! ? Icons.star : Icons.star_border,
                          size: 16,
                          color: i < order.rating! ? Colors.amber : Colors.grey[300],
                        );
                      }),
                    ),
                  ],
                  
                  Divider(height: 32, color: Colors.grey[200]),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'R\$ ${order.total.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey[900],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: style.$1,
                          borderRadius: BorderRadius.circular(8),
                          // ✅ SEM SOMBRA!
                        ),
                        child: Row(
                          children: [
                            Icon(
                              statusIcon,
                              size: 16,
                              color: style.$2,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayStatus,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: style.$2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  🏷️ MAPEAMENTO DE STATUS (COMPATÍVEL COM DETAIL)
  // ═══════════════════════════════════════════════════════════
  String _getDisplayStatus(String originalStatus) {
    final normalized = originalStatus.toLowerCase().trim();
    
    // ✅ MESMO MAPEAMENTO DO ORDER DETAIL
    if (normalized == 'pendente' || normalized == 'pending') {
      return 'Recebido';
    }
    if (normalized == 'processando' || normalized == 'processing') {
      return 'Recebido';
    }
    if (normalized == '-' || normalized == '-') {
      return 'Recebido';
    }
    if (normalized == 'recebido') {
      return 'Recebido';
    }
    if (normalized == 'registrado' || normalized == 'registered') {
      return 'Montado';
    }
    if (normalized == 'montado' || normalized == 'em preparo') {
      return 'Montado';
    }
    if (normalized == 'saiu pra entrega' || normalized == 'saiu para entrega') {
      return 'Saiu pra Entrega';
    }
    if (normalized == 'a caminho' || normalized == 'out_for_delivery') {
      return 'A Caminho';
    }
    if (normalized == 'entregue' || normalized == 'completed') {
      return 'Concluído';
    }
    if (normalized == 'concluído') {
      return 'Concluído';
    }
    if (normalized == 'agendado' || normalized == 'scheduled') {
      return 'Agendado';
    }
    if (normalized == 'cancelado' || normalized == 'cancelled') {
      return 'Cancelado';
    }
    
    return originalStatus;
  }

  // ═══════════════════════════════════════════════════════════
  //  🎯 ÍCONES CORRETOS (SEM FERRAMENTA)
  // ═══════════════════════════════════════════════════════════
  IconData _getStatusIcon(String displayStatus) {
    final Map<String, IconData> statusIcons = {
      'Recebido': Icons.check_circle_rounded, // ✅ Check
      'Montado': Icons.inventory_2_rounded, // ✅ Caixa (não ferramenta!)
      'Agendado': Icons.calendar_today_rounded,
      'Saiu pra Entrega': Icons.two_wheeler_rounded,
      'Concluído': Icons.done_all_rounded,
      'Cancelado': Icons.cancel_rounded,
      'A Caminho': Icons.two_wheeler_rounded,
    };
    return statusIcons[displayStatus] ?? Icons.help_outline_rounded;
  }

  (Color, Color) _getStatusStyle(String displayStatus) {
    final styles = {
      'Recebido': (AppColors.primary.withOpacity(0.1), AppColors.primary), // ✅ Laranja
      'Montado': (const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
      'Agendado': (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'Saiu pra Entrega': (const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
      'Concluído': (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      'Cancelado': (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      'A Caminho': (const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
    };

    return styles[displayStatus] ?? (Colors.grey[100]!, Colors.grey[700]!);
  }
}