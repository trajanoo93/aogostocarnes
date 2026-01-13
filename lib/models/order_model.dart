// lib/models/order_model.dart
import 'package:flutter/material.dart';

class AppOrder {
  final String id;
  final DateTime date;
  final String status;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final Address address;
  final PaymentMethod payment;
  final int? rating;

  const AppOrder({
    required this.id,
    required this.date,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.address,
    required this.payment,
    this.rating,
  });
}

class OrderItem {
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final int? variationId;  // ✅ NOVO
  final Map<String, String>? selectedAttributes;  // ✅ NOVO
  
  const OrderItem({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.variationId,  // ✅ NOVO
    this.selectedAttributes,  // ✅ NOVO
  });
}

class Address {
  final String id;
  final String street, number, complement, neighborhood, city, state, cep;
  const Address({
    required this.id,
    required this.street,
    required this.number,
    this.complement = '',
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
  });
}

class PaymentMethod {
  final String type;
  final String? details;
  const PaymentMethod({required this.type, this.details});
}