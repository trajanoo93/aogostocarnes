// lib/api/firestore_service.dart 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ao_gosto_app/models/order_model.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Salva pedido no Firestore com estrutura IDÊNTICA ao backend Python
  Future<void> saveOrder(
    AppOrder order,
    String customerPhone, {
    required String cd,
    required String janelaTexto,
    required bool isAgendado,
    required String customerName,
  }) async {
    try {
      // ✅ ESTRUTURA PADRONIZADA COM BACKEND PYTHON (CORRIGIDA)
      final dados = {
        // === SCHEMA E CONTROLE ===
        "_schema": 1,
        "id": order.id,
        "created_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
        "status": order.status,
        "tipo_entrega": order.address.id.contains('pickup') ? 'pickup' : 'delivery',
        "cd": cd,
        "is_ativo": true,

        // === CLIENTE (NA RAIZ, não dentro de agendamento) ===
        "cliente": {
          "nome": customerName,
          "telefone": customerPhone,
        },

        // === ENDEREÇO (Objeto completo) ===
        "endereco": {
          "rua": order.address.street,
          "numero": order.address.number,
          "complemento": order.address.complement ?? '',
          "bairro": order.address.neighborhood,
          "cidade": order.address.city,
          "cep": order.address.cep,
          "latitude": null,  // App não tem coordenadas
          "longitude": null,
        },

        // === AGENDAMENTO (Objeto aninhado) ===
        "agendamento": {
          "is_agendado": isAgendado,
          "janela_tempo": janelaTexto,  // ← CORRIGIDO: janela_tempo (não janela_texto)
          "data": order.date,
        },

        // === PAGAMENTO (Objeto aninhado) ===
        "pagamento": {
          "metodo_principal": _mapMetodoPagamento(order.payment.type),
          "taxa_entrega": order.deliveryFee,
          "valor_total": order.total,
          "valor_liquido": order.total,  // Sem desconto por ora
        },

        // === ITENS (Array estruturado) ===
        "itens": order.items.map((item) {
          return {
            "nome": item.name,
            "quantidade": item.quantity,
            "variacoes": [],  // App não tem variações ainda
          };
        }).toList(),

        // === LISTA DE PRODUTOS (Texto formatado) ===
        "lista_produtos_texto": order.items
            .map((i) => "${i.name} (Qtd: ${i.quantity}) *")
            .join("\n"),

        // === CAMPOS EXTRAS ===
        "observacao": "",  // App não tem observação ainda
        "entregador": "-",
        "loja_origem": "App",
        "data_pedido": _formatData(order.date),       // Ex: "11-11"
        "horario_pedido": _formatHorario(order.date), // Ex: "19:39"
      };

      // ✅ SALVAR NO FIRESTORE
      await _firestore
          .collection('orders')
          .doc(customerPhone)
          .collection('pedidos')
          .doc(order.id)
          .set(dados, SetOptions(merge: true));

      debugPrint('✅ Pedido ${order.id} salvo no Firestore com estrutura padronizada');
    } catch (e) {
      debugPrint('❌ Erro ao salvar pedido ${order.id} no Firestore: $e');
      rethrow;
    }
  }

  /// Mapeia método de pagamento para formato do backend
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

  /// Formata data para "DD-MM"
  String _formatData(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Formata horário para "HH:mm"
  String _formatHorario(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Stream de pedidos do usuário (para OrdersScreen)
  Stream<List<AppOrder>> getCustomerOrders(String customerPhone) {
    try {
      return _firestore
          .collection('orders')
          .doc(customerPhone)
          .collection('pedidos')
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

  /// Busca pedidos do usuário (versão Future)
  Future<List<AppOrder>> fetchUserOrders(String customerPhone) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .doc(customerPhone)
          .collection('pedidos')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // ✅ CONVERTE DE VOLTA PARA AppOrder
        return AppOrder(
          id: data['id'] ?? doc.id,
          date: (data['agendamento']['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? '-',
          items: (data['itens'] as List?)?.map((item) {
            return OrderItem(
              name: item['nome'] ?? 'Produto',
              imageUrl: '',  // Backend não tem imagem
              price: 0.0,    // Backend não tem preço individual
              quantity: item['quantidade'] ?? 1,
            );
          }).toList() ?? [],
          subtotal: (data['pagamento']['valor_total'] as num?)?.toDouble() ?? 0.0,
          deliveryFee: (data['pagamento']['taxa_entrega'] as num?)?.toDouble() ?? 0.0,
          discount: 0.0,
          total: (data['pagamento']['valor_total'] as num?)?.toDouble() ?? 0.0,
          address: Address(
            id: doc.id,
            street: data['endereco']['rua'] ?? '',
            number: data['endereco']['numero'] ?? '',
            complement: data['endereco']['complemento'] ?? '',
            neighborhood: data['endereco']['bairro'] ?? '',
            city: data['endereco']['cidade'] ?? '',
            state: '',  // Backend não tem estado
            cep: data['endereco']['cep'] ?? '',
          ),
          payment: PaymentMethod(
            type: _reverseMapMetodoPagamento(data['pagamento']['metodo_principal'] ?? 'pix'),
          ),
          rating: null,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar pedidos: $e');
      return [];
    }
  }

  /// Mapeia de volta para tipo do app
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
}