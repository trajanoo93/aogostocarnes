// lib/state/customer_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_data.dart';

class CustomerProvider extends ChangeNotifier {
  CustomerData? _customer;
  CustomerData? get customer => _customer;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton
  static final CustomerProvider instance = CustomerProvider._();
  CustomerProvider._();

  // Chave única baseada no telefone (ou device ID se preferir)
  Future<String> _getUid() async {
    final sp = await SharedPreferences.getInstance();
    final phone = sp.getString('customer_phone')?.replaceAll(RegExp(r'\D'), '');
    if (phone != null && phone.length >= 10) {
      return phone;
    }
    // fallback: device identifier (pode melhorar depois)
    return sp.getString('device_uid') ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Carrega ou cria cliente
  Future<void> loadOrCreateCustomer({
    required String name,
    required String phone,
    CustomerAddress? initialAddress,
    String? fcmToken,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = phone.replaceAll(RegExp(r'\D'), '');
      final docRef = _firestore.collection('clientes_app').doc(uid);

      final doc = await docRef.get();

      if (doc.exists) {
        _customer = CustomerData.fromDocument(doc);
      } else {
        final newCustomer = CustomerData(
          uid: uid,
          name: name,
          phone: phone,
          addresses: initialAddress != null ? [initialAddress] : [],
          fcmToken: fcmToken,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await docRef.set(newCustomer.toMap());
        _customer = newCustomer;
      }

      // Salva localmente pra fallback
      final sp = await SharedPreferences.getInstance();
      await sp.setString('customer_phone', phone);
      await sp.setString('customer_name', name);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Atualiza cliente (perfil, endereço, etc)
  Future<void> updateCustomer(CustomerData updated) async {
    try {
      final docRef = _firestore.collection('clientes_app').doc(updated.uid);
      await docRef.update(updated.toMap());
      _customer = updated;
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao atualizar cliente: $e");
    }
  }

  // Adiciona ou atualiza endereço
  Future<void> saveAddress(CustomerAddress address, {bool setAsDefault = false}) async {
    if (_customer == null) return;

    final updatedAddresses = _customer!.addresses.map((a) {
      if (setAsDefault) {
        return a.copyWith(isDefault: a.id == address.id);
      }
      return a.id == address.id ? address : a;
    }).toList();

    if (!_customer!.addresses.any((a) => a.id == address.id)) {
      updatedAddresses.add(address);
    }

    if (setAsDefault) {
      updatedAddresses.forEach((a) => a = a.copyWith(isDefault: a.id == address.id));
    }

    final updated = _customer!.copyWith(addresses: updatedAddresses);
    await updateCustomer(updated);
  }
}