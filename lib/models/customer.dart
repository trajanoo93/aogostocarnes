class Customer {
  final int? id;
  final String name;
  final String phone;

  Customer({this.id, required this.name, required this.phone});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
      };
}

class CustomerAddress {
  final int? id;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String cep;

  CustomerAddress({
    this.id,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'cep': cep,
      };
}
