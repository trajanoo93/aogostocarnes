// lib/api/firestore_service.dart - VERSÃO FINAL COMPATÍVEL COM ERP

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ao_gosto_app/models/order_model.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ SALVA NO FIRESTORE (100% COMPATÍVEL COM ERP)
  Future<void> saveOrder(
  AppOrder order,
  String customerPhone, {
  required String cd,
  required String janelaTexto,
  required bool isAgendado,
  required String customerName,
}) async {
  try {
    // ✅ O STATUS JÁ VEM CORRETO DO CHECKOUT_CONTROLLER
    // Não precisa recalcular aqui
    
    final dados = {
      // === SCHEMA E CONTROLE ===
      "_schema": 1,
      "id": order.id,
      "created_at": FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),
      "status": order.status,  // ✅ Usa o status que veio do controller
      "tipo_entrega": order.address.id.contains('pickup') ? 'pickup' : 'delivery',
      "cd": cd,
      "is_ativo": true,

      // === CLIENTE ===
      "cliente": {
        "nome": customerName,
        "telefone": customerPhone,
      },

      // === ENDEREÇO ===
      "endereco": {
        "rua": order.address.street,
        "numero": order.address.number,
        "complemento": order.address.complement ?? '',
        "bairro": order.address.neighborhood,
        "cidade": order.address.city,
        "cep": order.address.cep,
        "latitude": null,
        "longitude": null,
      },

      // === AGENDAMENTO ===
      "agendamento": {
        "is_agendado": isAgendado,
        "janela_texto": janelaTexto,
        "data": order.date,  // ✅ Data do pedido
      },

      // === PAGAMENTO ===
      "pagamento": {
        "metodo_principal": _mapMetodoPagamento(order.payment.type),
        "taxa_entrega": order.deliveryFee,
        "valor_total": order.total,
        "valor_liquido": order.total,
        "conta_stripe": null,
        "conta_pagarme": null,
      },

      // ✅ CUPOM
      "cupom": {
        "codigo": null,
        "valor": null,
        "tipo": null,
      },

      // ✅ DESCONTO CARTÃO PRESENTE
      "desconto_cartao_presente": null,

      // === ITENS ===
      "itens": order.items.map((item) {
        return {
          "nome": item.name,
          "quantidade": item.quantity,
          "variacoes": [],
        };
      }).toList(),

      // === LISTA DE PRODUTOS ===
      "lista_produtos_texto": order.items
          .map((i) => "${i.name} (Qtd: ${i.quantity}) *")
          .join("\n"),

      // === CAMPOS EXTRAS ===
      "observacao": "",
      "entregador": "-",
      "loja_origem": "App",
      "data_pedido": _formatData(order.date),
      "horario_pedido": _formatHorario(order.date),
    };

    // ✅ SALVA NA COLEÇÃO ÚNICA
    await _firestore
        .collection('pedidos')
        .doc(order.id)
        .set(dados, SetOptions(merge: true));

    debugPrint('✅ Pedido ${order.id} salvo no Firestore (status: ${order.status})');
  } catch (e) {
    debugPrint('❌ Erro ao salvar pedido ${order.id}: $e');
    rethrow;
  }
}

  /// ✅ BUSCA PEDIDOS DO USUÁRIO (por telefone)
  Stream<List<AppOrder>> getCustomerOrders(String customerPhone) {
    try {
      return _firestore
          .collection('pedidos')
          .where('cliente.telefone', isEqualTo: customerPhone)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          
          return AppOrder(
            id: data['id'] ?? doc.id,
            date: (data['agendamento']?['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: data['status'] ?? '-',
            items: (data['itens'] as List?)?.map((item) {
              return OrderItem(
                name: item['nome'] ?? 'Produto',
                imageUrl: '',
                price: 0.0,
                quantity: item['quantidade'] ?? 1,
              );
            }).toList() ?? [],
            subtotal: (data['pagamento']?['valor_total'] as num?)?.toDouble() ?? 0.0,
            deliveryFee: (data['pagamento']?['taxa_entrega'] as num?)?.toDouble() ?? 0.0,
            discount: 0.0,
            total: (data['pagamento']?['valor_total'] as num?)?.toDouble() ?? 0.0,
            address: Address(
              id: doc.id,
              street: data['endereco']?['rua'] ?? '',
              number: data['endereco']?['numero'] ?? '',
              complement: data['endereco']?['complemento'] ?? '',
              neighborhood: data['endereco']?['bairro'] ?? '',
              city: data['endereco']?['cidade'] ?? '',
              state: '',
              cep: data['endereco']?['cep'] ?? '',
            ),
            payment: PaymentMethod(
              type: _reverseMapMetodoPagamento(data['pagamento']?['metodo_principal'] ?? 'pix'),
            ),
            rating: null,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('❌ Erro ao buscar pedidos: $e');
      return Stream.value([]);
    }
  }

  /// ✅ BUSCA PEDIDO ESPECÍFICO (para ThankYouScreen)
  Stream<AppOrder?> getOrderById(String orderId) {
    try {
      return _firestore
          .collection('pedidos')
          .doc(orderId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        
        final data = doc.data()!;
        
        return AppOrder(
          id: data['id'] ?? doc.id,
          date: (data['agendamento']?['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? '-',
          items: (data['itens'] as List?)?.map((item) {
            return OrderItem(
              name: item['nome'] ?? 'Produto',
              imageUrl: '',
              price: 0.0,
              quantity: item['quantidade'] ?? 1,
            );
          }).toList() ?? [],
          subtotal: (data['pagamento']?['valor_total'] as num?)?.toDouble() ?? 0.0,
          deliveryFee: (data['pagamento']?['taxa_entrega'] as num?)?.toDouble() ?? 0.0,
          discount: 0.0,
          total: (data['pagamento']?['valor_total'] as num?)?.toDouble() ?? 0.0,
          address: Address(
            id: doc.id,
            street: data['endereco']?['rua'] ?? '',
            number: data['endereco']?['numero'] ?? '',
            complement: data['endereco']?['complemento'] ?? '',
            neighborhood: data['endereco']?['bairro'] ?? '',
            city: data['endereco']?['cidade'] ?? '',
            state: '',
            cep: data['endereco']?['cep'] ?? '',
          ),
          payment: PaymentMethod(
            type: _reverseMapMetodoPagamento(data['pagamento']?['metodo_principal'] ?? 'pix'),
          ),
          rating: null,
        );
      });
    } catch (e) {
      debugPrint('❌ Erro ao buscar pedido $orderId: $e');
      return Stream.value(null);
    }
  }

  // === MÉTODOS AUXILIARES ===
  
  String _mapMetodoPagamento(String type) {
    switch (type) {
      case 'pix':
        return 'Pix';
      case 'money':
        return 'Dinheiro';
      case 'card-on-delivery':
        return 'Cartão';
      case 'card-online':
        return 'Crédito Site';
      case 'voucher':
        return 'V.A';
      default:
        return 'Sem método de pagamento';
    }
  }

  String _reverseMapMetodoPagamento(String metodo) {
    switch (metodo) {
      case 'Pix':
        return 'pix';
      case 'Dinheiro':
        return 'money';
      case 'Cartão':
        return 'card-on-delivery';
      case 'Crédito Site':
        return 'card-online';
      case 'V.A':
      case 'Vale Alimentação':
        return 'voucher';
      default:
        return 'pix';
    }
  }

  String _formatData(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}';
  }

  String _formatHorario(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}