import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingAddress {
  final String? street, number, complement, neighborhood, city, state, cep;
  OnboardingAddress({
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.cep,
  });
}

class OnboardingProfile {
  final String? name;
  final String? phone;
  final OnboardingAddress? address;
  OnboardingProfile({this.name, this.phone, this.address});
}

class Customer {
  final String name;
  final String phone;

  Customer({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
      };
}

class CustomerAddress {
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String cep;

  CustomerAddress({
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
  });

  Map<String, dynamic> toJson() => {
        'street': street,
        'number': number,
        'complement': complement ?? '',
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'cep': cep,
      };
}

class OnboardingService {
  static const String _base = 'https://aogosto.com.br/app/onboarding';

  Future<int> register(Customer c, CustomerAddress a) async {
    final uri = Uri.parse('$_base/register.php');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'customer': c.toJson(),
        'address': a.toJson(),
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('Falha ao registrar: HTTP ${resp.statusCode}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    if (data['ok'] == true && data['customer_id'] is int) {
      return data['customer_id'] as int;
    }
    throw Exception('Resposta inválida do servidor: ${resp.body}');
  }

  // ======================================================
  // BUSCA ENDEREÇO POR CEP (ViaCEP)
  // ======================================================
  Future<CustomerAddress?> lookupCep(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;

    final url = Uri.parse('https://viacep.com.br/ws/$digits/json/');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return null;

    final m = json.decode(resp.body);
    if (m is Map && m['erro'] != true) {
      return CustomerAddress(
        street: (m['logradouro'] ?? '').toString(),
        number: '',
        complement: null,
        neighborhood: (m['bairro'] ?? '').toString(),
        city: (m['localidade'] ?? '').toString(),
        state: (m['uf'] ?? '').toString(),
        cep: '${digits.substring(0, 5)}-${digits.substring(5)}',
      );
    }
    return null;
  }

  // ======================================================
  // PERSISTE PERFIL LOCALMENTE
  // ======================================================
  Future<void> persistProfile({
    required int id,
    required String name,
    required String phone,
    CustomerAddress? a, // 👈 permite salvar também o endereço
  }) async {
    final sp = await SharedPreferences.getInstance();

    await sp.setInt('customer_id', id);
    await sp.setString('customer_name', name);
    await sp.setString('customer_phone', phone);

    // Armazena também os campos de endereço (se existirem)
    if (a != null) {
      await sp.setString('address_street', a.street ?? '');
      await sp.setString('address_number', a.number ?? '');
      await sp.setString('address_complement', a.complement ?? '');
      await sp.setString('address_neighborhood', a.neighborhood ?? '');
      await sp.setString('address_city', a.city ?? '');
      await sp.setString('address_state', a.state ?? '');
      await sp.setString('address_cep', a.cep ?? '');
    }
  }

  // ======================================================
  // VERIFICA SE O PERFIL EXISTE
  // ======================================================
  Future<bool> hasProfile() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt('customer_id') != null;
  }

  // ======================================================
  // RECUPERA PERFIL SALVO NO BACKEND
  // ======================================================
  Future<OnboardingProfile> getProfile() async {
    final sp = await SharedPreferences.getInstance();
    final customerId = sp.getInt('customer_id');

    if (customerId == null) {
      return OnboardingProfile(name: '', phone: '', address: null);
    }

    // Busca do backend
    final uri = Uri.parse('$_base/get_profile.php?customer_id=$customerId');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (data['ok'] == true) {
        final customer = data['customer'];
        final address = data['address'];
        return OnboardingProfile(
          name: customer['name'] ?? '',
          phone: customer['phone'] ?? '',
          address: OnboardingAddress(
            street: address['street'] ?? '',
            number: address['number'] ?? '',
            complement: address['complement'] ?? '',
            neighborhood: address['neighborhood'] ?? '',
            city: address['city'] ?? '',
            state: address['state'] ?? '',
            cep: address['cep'] ?? '',
          ),
        );
      }
    }
    return OnboardingProfile(name: '', phone: '', address: null);
  }
}