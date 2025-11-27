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

  static final CustomerProvider instance = CustomerProvider._();
  CustomerProvider._();

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
        final addresses = initialAddress != null ? [initialAddress] : <CustomerAddress>[];
        final newCustomer = CustomerData(
          uid: uid,
          name: name,
          phone: phone,
          addresses: addresses,
          fcmToken: fcmToken,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await docRef.set(newCustomer.toMap());
        _customer = newCustomer;
      }

      final sp = await SharedPreferences.getInstance();
      await sp.setString('customer_phone', phone);
      await sp.setString('customer_name', name);
      await sp.setBool('onboarding_done', true);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Erro CustomerProvider: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<void> saveAddress(CustomerAddress address, {bool setAsDefault = false}) async {
    if (_customer == null) return;

    var updatedAddresses = List<CustomerAddress>.from(_customer!.addresses);

    final index = updatedAddresses.indexWhere((a) => a.id == address.id);
    if (index >= 0) {
      updatedAddresses[index] = address;
    } else {
      updatedAddresses.add(address);
    }

    if (setAsDefault) {
      updatedAddresses = updatedAddresses.map((a) => a.copyWith(isDefault: a.id == address.id)).toList();
    }

    final updated = _customer!.copyWith(addresses: updatedAddresses);
    await updateCustomer(updated);
  }
}