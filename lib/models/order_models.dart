// lib/models/order_models.dart
import 'package:flutter/material.dart';

class Order {
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

  const Order({
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
  const OrderItem({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });
}

class Address {
  final String street, number, complement, neighborhood, city, state, cep;
  const Address({
    required this.street,
    required this.number,
    required this.complement,
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