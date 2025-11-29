// lib/api/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/models/order_model.dart';
import 'package:flutter/foundation.dart';
import 'package:ao_gosto_app/api/product_image_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'pedidos';
  final ProductImageService _imageService = ProductImageService();

  Future<void> saveOrder(
    AppOrder order,
    String appCustomerId, {
    required String cd,
    required String janelaTexto,
    required bool isAgendado,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      final cleanCustomerId = appCustomerId.replaceAll('"', '').trim();
      
      await _db.collection(_collection).doc(order.id).set({
        '_schema': 1,
        'id': order.id,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
        'is_ativo': true,

        'cliente': {
          'nome': customerName.trim(),
          'telefone': customerPhone.replaceAll(RegExp(r'[^\d]'), ''),
          'customerPhone': customerPhone.replaceAll(RegExp(r'[^\d]'), ''), 
        },

        'endereco': {
          'rua': order.address.street,
          'numero': order.address.number,
          'complemento': order.address.complement,
          'bairro': order.address.neighborhood,
          'cidade': order.address.city,
          'estado': order.address.state,
          'cep': order.address.cep,
        },

        'agendamento': {
          'data': Timestamp.fromDate(order.date),
          'is_agendado': isAgendado,
          'janela_texto': janelaTexto,
        },

        'data_pedido': DateFormat('dd-MM').format(DateTime.now()),
        'horario_pedido': DateFormat('HH:mm').format(DateTime.now()),
        'tipo_entrega': order.payment.type.contains('Entrega') ? 'delivery' : 'pickup',
        'loja_origem': 'App',
        'cd': cd,
        'status': isAgendado ? 'Agendado' : '-',

        'pagamento': {
          'metodo_principal': _mapMetodoPrincipal(order.payment.type),
          'taxa_entrega': order.deliveryFee,
          'valor_liquido': order.total,
          'valor_total': order.total,
        },

        'itens': order.items.map((item) => {
          'nome': item.name,
          'quantidade': item.quantity,
          'preco_unitario': item.price,
          'total': item.price * item.quantity,
          'lista_produtos_texto': '${item.name} x${item.quantity}',
        }).toList(),

        'entregador': '',
      });
      
      debugPrint('✅ Pedido ${order.id} salvo com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao salvar pedido: $e');
      rethrow;
    }
  }

  String _mapMetodoPrincipal(String type) {
    if (type.contains('pix')) return 'Pix';
    if (type.contains('money')) return 'Dinheiro';
    if (type.contains('card')) return 'Cartão';
    return 'Pix';
  }

  /// ✅ CORRIGIDO: Query sem duplicação
  Stream<List<AppOrder>> getCustomerOrders(String customerPhone) async* {
    final cleanPhone = customerPhone.replaceAll(RegExp(r'[^\d]'), '');

    debugPrint('🔍 Buscando pedidos para: $cleanPhone');

    await for (final snapshot in _db
        .collection(_collection)
        .where('cliente.customerPhone', isEqualTo: cleanPhone)
        .where('loja_origem', isEqualTo: 'App')
        .orderBy('created_at', descending: true)
        .snapshots()) {

      debugPrint('📦 ${snapshot.docs.length} pedidos encontrados');

      final orders = <AppOrder>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        String paymentType = 'Não informado';
        if (data['pagamento'] != null) {
          final pagamento = data['pagamento'] as Map<String, dynamic>;
          paymentType = pagamento['metodo_principal'] ?? 'Não informado';
        }

        final items = <OrderItem>[];
        if (data['itens'] != null) {
          final itensList = data['itens'] as List;

          for (final i in itensList) {
            final productName = i['nome'] ?? 'Item sem nome';
            final imageUrl = await _imageService.getProductImage(productName);

            items.add(OrderItem(
              name: productName,
              imageUrl: imageUrl,
              price: (i['preco_unitario'] ?? 0.0).toDouble(),
              quantity: (i['quantidade'] ?? 0).toInt(),
            ));
          }
        }

        orders.add(AppOrder(
          id: doc.id,
          date: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? '-',
          rating: data['rating'],
          items: items,
          subtotal: _calculateTotal(data['itens']),
          deliveryFee: (data['pagamento']?['taxa_entrega'] ?? 0.0).toDouble(),
          discount: 0,
          total: (data['pagamento']?['valor_total'] ?? _calculateTotal(data['itens'])).toDouble(),
          address: Address(
            id: doc.id,
            street: data['endereco']?['rua'] ?? '',
            number: data['endereco']?['numero'] ?? '',
            complement: data['endereco']?['complemento'] ?? '',
            neighborhood: data['endereco']?['bairro'] ?? '',
            city: data['endereco']?['cidade'] ?? '',
            state: data['endereco']?['estado'] ?? '',
            cep: data['endereco']?['cep'] ?? '',
          ),
          payment: PaymentMethod(type: paymentType),
        ));
      }

      yield orders;
    }
  }

  double _calculateTotal(dynamic itens) {
    if (itens == null || itens is! List) return 0.0;
    
    return itens.fold(0.0, (sum, i) {
      if (i == null) return sum;
      return sum + ((i['total'] ?? 0.0) as num).toDouble();
    });
  }
}