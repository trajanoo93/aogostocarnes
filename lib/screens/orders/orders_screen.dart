// lib/screens/orders/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/models/order_models.dart';
import 'package:ao_gosto_app/screens/orders/order_detail_screen.dart';
import 'package:ao_gosto_app/api/firestore_service.dart'; 

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getCustomerId(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final customerId = snapshot.data!;

        return StreamBuilder<List<Order>>(
          stream: FirestoreService().getCustomerOrders(customerId),
          builder: (ctx, streamSnapshot) {
            if (streamSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!streamSnapshot.hasData || streamSnapshot.data!.isEmpty) {
              return Scaffold(
                backgroundColor: const Color(0xFFF9FAFB),
                appBar: AppBar(
                  backgroundColor: const Color(0xFFF9FAFB),
                  elevation: 0,
                  title: const Text(
                    'Meus Pedidos',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                  ),
                  centerTitle: false,
                ),
                body: const Center(child: Text('Nenhum pedido encontrado')),
              );
            }

            final orders = streamSnapshot.data!;

            return Scaffold(
              backgroundColor: const Color(0xFFF9FAFB),
              appBar: AppBar(
                backgroundColor: const Color(0xFFF9FAFB),
                elevation: 0,
                title: const Text(
                  'Meus Pedidos',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                ),
                centerTitle: false,
              ),
              body: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (ctx, i) => _buildOrderCard(orders[i]),
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _getCustomerId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt('customer_id')?.toString() ?? '';
  }

  Widget _buildOrderCard(Order order) {
    final style = statusStyles[order.status] ?? (Colors.grey[200]!, Colors.grey[700]!);
    final itemPreview = '${order.items[0].name}${order.items.length > 1 ? ' + ${order.items.length - 1} item${order.items.length > 2 ? 's' : ''}' : ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pedido #${order.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                    Text(DateFormat('dd \'de\' MMMM, yyyy - HH:mm').format(order.date), style: const TextStyle(fontSize: 13, color: Color(0xFF71717A))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: style.$1, borderRadius: BorderRadius.circular(999)),
                child: Text(order.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: style.$2)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ...order.items.take(3).map((item) => Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrl),
                        fit: BoxFit.cover,
                        onError: (_, __) => const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  )),
              if (order.items.length > 3)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('+${order.items.length - 3}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  itemPreview,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 14, color: Color(0xFF71717A))),
                  Text('R\$ ${order.total.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                ),
                icon: const Icon(Icons.chevron_right, size: 20),
                label: const Text('Ver Detalhes', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              if (order.status == 'Entregue') const SizedBox(width: 8),
              if (order.status == 'Entregue')
                ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(order),
                  icon: const Icon(Icons.star, size: 20),
                  label: const Text('Avaliar', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Avalie sua experiência', textAlign: TextAlign.center),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return IconButton(
              onPressed: () {
                setState(() => order.rating = i + 1);
                Navigator.pop(ctx);
              },
              icon: Icon(Icons.star, color: (order.rating ?? 0) > i ? Colors.amber : Colors.grey[300]),
            );
          }),
        ),
      ),
    );
  }

  final Map<String, (Color, Color)> statusStyles = {
    'Entregue': (const Color(0xFFDCFCE7), const Color(0xFF166534)),
    'A Caminho': (const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
    'Em Preparo': (const Color(0xFFFFFBEB), const Color(0xFF92400E)),
    'Cancelado': (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
  };
}