// lib/state/customer_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_data.dart';
import '../services/notification_service.dart';

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
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final docRef = _firestore.collection('clientes_app').doc(cleanPhone);
      final doc = await docRef.get();

      if (doc.exists) {
        _customer = CustomerData.fromDocument(doc);
      } else {
        final addresses = initialAddress != null ? [initialAddress] : <CustomerAddress>[];
        final newCustomer = CustomerData(
          uid: cleanPhone,
          name: name,
          phone: phone,
          addresses: addresses,
          fcmToken: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await docRef.set(newCustomer.toMap());
        _customer = newCustomer;
      }

      // SALVA O FCM TOKEN NO FIRESTORE (A MÁGICA ACONTECE AQUI!)
      final token = await NotificationService.getToken();
      if (token != null && token.isNotEmpty) {
        await docRef.set({'fcmToken': token}, SetOptions(merge: true));
        print('FCM Token salvo no Firestore: $token');
        _customer = _customer?.copyWith(fcmToken: token);
      }

      // Salva dados locais
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

  // Atualiza o token se mudar (boa prática)
  Future<void> updateFcmToken() async {
    final token = await NotificationService.getToken();
    if (token != null && _customer != null) {
      await _firestore
          .collection('clientes_app')
          .doc(_customer!.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
      _customer = _customer!.copyWith(fcmToken: token);
      notifyListeners();
      print('Token atualizado: $token');
    }
  }
}