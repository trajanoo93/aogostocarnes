import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';

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
  final String? phone;
  final OnboardingAddress? address;
  OnboardingProfile({this.phone, this.address});
}

class OnboardingService {
  // === URL base do endpoint PHP no seu servidor ===
  static const String _base = 'https://aogosto.com.br/app/onboarding';

  // ======================================================
  // REGISTRO DE CLIENTE E ENDEREÇO
  // ======================================================
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
  // RECUPERA PERFIL SALVO LOCALMENTE (USADO PELO CHECKOUT)
  // ======================================================
  Future<OnboardingProfile> getProfile() async {
    final sp = await SharedPreferences.getInstance();

    final phone = sp.getString('customer_phone') ?? '';
    final name = sp.getString('customer_name') ?? '';

    final address = OnboardingAddress(
      street: sp.getString('address_street') ?? '',
      number: sp.getString('address_number') ?? '',
      complement: sp.getString('address_complement'),
      neighborhood: sp.getString('address_neighborhood') ?? '',
      city: sp.getString('address_city') ?? '',
      state: sp.getString('address_state') ?? '',
      cep: sp.getString('address_cep') ?? '',
    );

    return OnboardingProfile(
      phone: phone,
      address: address,
    );
  }
}
