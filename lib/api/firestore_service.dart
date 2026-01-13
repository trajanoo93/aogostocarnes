// lib/api/firestore_service.dart - VERSÃO FINAL COM PREÇOS

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ao_gosto_app/models/order_model.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ SALVA NO FIRESTORE (COM PREÇOS)
  Future<void> saveOrder(
    AppOrder order,
    String customerPhone, {
    required String cd,
    required String janelaTexto,
    required bool isAgendado,
    required String customerName,
    required String deliveryType,  // Novo: 'delivery' ou 'pickup'
    Coupon? coupon,
    String? orderNotes,
  }) async {  
    try {
      final metodoPrincipal = _mapMetodoPagamentoParaSite(order.payment.type);

      // ✅ FORMATA LISTA DE PRODUTOS (COM PREÇO)
      final listaProdutosTexto = order.items.map((i) {
  // Monta a string base
  String itemText = "${i.name} (Qtd: ${i.quantity})";
  
  // ✅ ADICIONA VARIAÇÕES SE EXISTIR
  if (i.selectedAttributes != null && i.selectedAttributes!.isNotEmpty) {
    final variacoesTexto = i.selectedAttributes!.entries
        .map((e) => "${e.key}: ${e.value}")
        .join(" | ");
    itemText += " - $variacoesTexto";
  } else {
    // Se não tiver variação, adiciona o preço
    itemText += " - R\$ ${i.price.toStringAsFixed(2)}";
  }
  
  itemText += " *";
  return itemText;
}).join("\n");

      final dataPedido = "${order.date.day.toString().padLeft(2, '0')}-${order.date.month.toString().padLeft(2, '0')}";
      final horarioPedido = "${order.date.hour.toString().padLeft(2, '0')}:${order.date.minute.toString().padLeft(2, '0')}";

      final dados = {
        "_schema": 1,
        "id": order.id,
        "created_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
        "status": order.status,
        "tipo_entrega": deliveryType,  // Atualizado: Usa param
        "cd": cd,
        "is_ativo": true,

        "cliente": {
          "nome": customerName,
          "telefone": customerPhone,
        },

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

        "agendamento": {
          "is_agendado": isAgendado,
          "janela_texto": janelaTexto,
          "data": order.date,
        },

        "pagamento": {
          "metodo_principal": metodoPrincipal,
          "taxa_entrega": order.deliveryFee,
          "subtotal": order.subtotal,  // ✅ SUBTOTAL
          "desconto": order.discount,  // ✅ DESCONTO
          "valor_total": order.total,
          "valor_liquido": order.total,
          "conta_stripe": null,
          "conta_pagarme": null,
        },

        "cupom": {
          "codigo": coupon?.code,
          "valor": coupon?.discount,
          "tipo": coupon != null ? "percent" : null,
        },

        "desconto_cartao_presente": null,

        // ✅ ITENS COM PREÇO!
       // ✅ ITENS COM PREÇO E VARIAÇÕES!
"itens": order.items.map((item) {
  final itemData = <String, dynamic>{
    "nome": item.name,
    "quantidade": item.quantity,
    "preco": item.price,  // ✅ PREÇO!
  };

  // ✅ ADICIONA VARIAÇÕES SE EXISTIR
  if (item.variationId != null && item.variationId! > 0) {
    itemData["variation_id"] = item.variationId;
    
    if (item.selectedAttributes != null && item.selectedAttributes!.isNotEmpty) {
      itemData["variacoes"] = item.selectedAttributes!.entries
          .map((e) => "${e.key}: ${e.value}")
          .toList();
    }
  } else {
    itemData["variacoes"] = [];
  }

  return itemData;
}).toList(),

        "lista_produtos_texto": listaProdutosTexto,
        "observacao": orderNotes ?? "",
        "entregador": "-",
        "loja_origem": "App",
        "data_pedido": dataPedido,
        "horario_pedido": horarioPedido,
      };

      await _firestore
          .collection('pedidos')
          .doc(order.id)
          .set(dados, SetOptions(merge: true));

      debugPrint('✅ Pedido ${order.id} salvo');
      if (coupon != null) {
        debugPrint('🎫 Cupom: R\$ ${coupon.discount.toStringAsFixed(2)}');
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      rethrow;
    }
  }

  String _mapMetodoPagamentoParaSite(String type) {
    switch (type) {
      case 'pix': return 'Pix';
      case 'money': return 'Dinheiro';
      case 'card-on-delivery': return 'Cartão';
      case 'card-online': return 'Crédito Site';
      case 'voucher': return 'Vale Alimentação';
      default: return 'Sem método de pagamento';
    }
  }

  /// ✅ BUSCA PEDIDOS (COM PREÇOS)
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
          
          final subtotal = (data['pagamento']?['subtotal'] as num?)?.toDouble() ?? 0.0;
          final deliveryFee = (data['pagamento']?['taxa_entrega'] as num?)?.toDouble() ?? 0.0;
          final discount = (data['pagamento']?['desconto'] as num?)?.toDouble() ?? 
                          (data['cupom']?['valor'] as num?)?.toDouble() ?? 0.0;
          final total = (data['pagamento']?['valor_total'] as num?)?.toDouble() ?? 0.0;
          
          return AppOrder(
            id: data['id'] ?? doc.id,
            date: (data['agendamento']?['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: data['status'] ?? '-',
            
            items: (data['itens'] as List?)?.map((item) {
  return OrderItem(
    name: item['nome'] ?? 'Produto',
    imageUrl: '',
    price: (item['preco'] as num?)?.toDouble() ?? 0.0,
    quantity: item['quantidade'] ?? 1,
    variationId: item['variation_id'] as int?,  // ✅ NOVO
    selectedAttributes: (item['variacoes'] as List?)?.isNotEmpty == true
        ? Map<String, String>.fromIterable(
            (item['variacoes'] as List).where((v) => v.toString().contains(':')),
            key: (v) => v.toString().split(':')[0].trim(),
            value: (v) => v.toString().split(':')[1].trim(),
          )
        : null,  // ✅ NOVO
  );
}).toList() ?? [],
            
            subtotal: subtotal,
            deliveryFee: deliveryFee,
            discount: discount,  // ✅ DESCONTO!
            total: total,
            
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
            rating: (data['rating'] as int?),
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('❌ Erro: $e');
      return Stream.value([]);
    }
  }

  Stream<AppOrder?> getOrderById(String orderId) {
    try {
      return _firestore
          .collection('pedidos')
          .doc(orderId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        
        final data = doc.data()!;
        
        final subtotal = (data['pagamento']?['subtotal'] as num?)?.toDouble() ?? 0.0;
        final deliveryFee = (data['pagamento']?['taxa_entrega'] as num?)?.toDouble() ?? 0.0;
        final discount = (data['pagamento']?['desconto'] as num?)?.toDouble() ?? 
                        (data['cupom']?['valor'] as num?)?.toDouble() ?? 0.0;
        final total = (data['pagamento']?['valor_total'] as num?)?.toDouble() ?? 0.0;
        
        return AppOrder(
          id: data['id'] ?? doc.id,
          date: (data['agendamento']?['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? '-',
          
          items: (data['itens'] as List?)?.map((item) {
            return OrderItem(
              name: item['nome'] ?? 'Produto',
              imageUrl: '',
              price: (item['preco'] as num?)?.toDouble() ?? 0.0,
              quantity: item['quantidade'] ?? 1,
            );
          }).toList() ?? [],
          
          subtotal: subtotal,
          deliveryFee: deliveryFee,
          discount: discount,
          total: total,
          
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
          rating: (data['rating'] as int?),
        );
      });
    } catch (e) {
      debugPrint('❌ Erro: $e');
      return Stream.value(null);
    }
  }

  String _reverseMapMetodoPagamento(String metodo) {
    switch (metodo) {
      case 'Pix': return 'pix';
      case 'Dinheiro': return 'money';
      case 'Cartão': return 'card-on-delivery';
      case 'Crédito Site': return 'card-online';
      case 'Vale Alimentação':
      case 'V.A': return 'voucher';
      default: return 'pix';
    }
  }
}