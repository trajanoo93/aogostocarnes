// lib/models/customer_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAddress {
  final String id;
  final String apelido;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String cep;
  final bool isDefault;

  CustomerAddress({
    required this.id,
    required this.apelido,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
    this.isDefault = false,
  });

  factory CustomerAddress.fromMap(Map<String, dynamic> map) {
    return CustomerAddress(
      id: map['id'] ?? '',
      apelido: map['apelido'] ?? 'Endereço',
      street: map['street'] ?? '',
      number: map['number'] ?? '',
      complement: map['complement'],
      neighborhood: map['neighborhood'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      cep: map['cep'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'apelido': apelido,
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'cep': cep,
        'isDefault': isDefault,
      };

  // ESSA É A PARTE QUE FALTAVA!!!
  CustomerAddress copyWith({
    String? id,
    String? apelido,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
    String? cep,
    bool? isDefault,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      apelido: apelido ?? this.apelido,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      cep: cep ?? this.cep,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class CustomerData {
  final String uid;
  final String name;
  final String phone;
  final List<CustomerAddress> addresses;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerData({
    required this.uid,
    required this.name,
    required this.phone,
    required this.addresses,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerData.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final addressesList = data['addresses'] as List<dynamic>? ?? [];

    return CustomerData(
      uid: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      addresses: addressesList
          .map((a) => CustomerAddress.fromMap(a as Map<String, dynamic>))
          .toList(),
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'addresses': addresses.map((a) => a.toMap()).toList(),
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  CustomerData copyWith({
    String? name,
    String? phone,
    List<CustomerAddress>? addresses,
    String? fcmToken,
  }) {
    return CustomerData(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addresses: addresses ?? this.addresses,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}