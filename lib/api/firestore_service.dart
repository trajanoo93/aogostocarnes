// lib/api/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'package:ao_gosto_app/models/order_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'pedidos';

  // SALVA PEDIDO NO FIRESTORE
  Future<void> saveOrder(Order order, String appCustomerId) async {
    try {
      await _db.collection(_collection).doc(order.id).set({
        '_schema': 1,
        'id': order.id,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_ativo': true,

        // CLIENTE
        'cliente': {
          'id': appCustomerId,
          'nome': order.address.street.split(' ').first, // ou usar profile.name
        },

        // ENDEREÇO
        'endereco': {
          'rua': order.address.street,
          'numero': order.address.number,
          'complemento': order.address.complement,
          'bairro': order.address.neighborhood,
          'cidade': order.address.city,
          'estado': order.address.state,
          'cep': order.address.cep,
        },

        // AGENDAMENTO
        'agendamento': {
          'data': order.date.toIso8601String().split('T').first,
          'horario': order.status == 'Entregue' ? 'Concluído' : 'Agendado',
        },

        // PEDIDO
        'data_pedido': DateFormat('dd/MM/yyyy HH:mm').format(order.date),
        'horario_pedido': 'Horário não definido', // opcional
        'tipo_entrega': order.payment.type.contains('Entrega') ? 'delivery' : 'pickup',
        'loja_origem': order.payment.type.contains('Entrega') ? 'Unidade X' : 'Retirada',
        'status': order.status,
        'observacao': '', // viria do orderNotes

        // PAGAMENTO
        'pagamento': {
          'metodo': order.payment.type,
          'detalhes': order.payment.details ?? '',
        },

        // ITENS
        'itens': order.items.map((item) => {
          'nome': item.name,
          'quantidade': item.quantity,
          'preco_unitario': item.price,
          'total': item.price * item.quantity,
          'variacoes': [], // preencher se houver
          'lista_produtos_texto': '${item.name} x${item.quantity}',
        }).toList(),

        'entregador': '', // futuro
      });
    } catch (e) {
      print('Erro Firestore: $e');
    }
  }

  // BUSCA PEDIDOS DO CLIENTE
  Stream<List<Order>> getCustomerOrders(String appCustomerId) {
    return _db
        .collection(_collection)
        .where('cliente.id', isEqualTo: appCustomerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Order(
                id: data['id'],
                date: (data['created_at'] as Timestamp).toDate(),
                status: data['status'],
                items: (data['itens'] as List).map((i) => OrderItem(
                  name: i['nome'],
                  imageUrl: '', // buscar do WooCommerce depois
                  price: i['preco_unitario'],
                  quantity: i['quantidade'],
                )).toList(),
                subtotal: data['itens'].fold(0.0, (s, i) => s + i['total']),
                deliveryFee: 0,
                discount: 0,
                total: data['itens'].fold(0.0, (s, i) => s + i['total']),
                address: Address(
                  street: data['endereco']['rua'],
                  number: data['endereco']['numero'],
                  complement: data['endereco']['complemento'],
                  neighborhood: data['endereco']['bairro'],
                  city: data['endereco']['cidade'],
                  state: data['endereco']['estado'],
                  cep: data['endereco']['cep'],
                ),
                payment: PaymentMethod(type: data['pagamento']['metodo'], details: data['pagamento']['detalhes']),
              );
            }).toList());
  }
}