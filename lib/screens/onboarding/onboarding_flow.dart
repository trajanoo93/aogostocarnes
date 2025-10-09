import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../utils/app_colors.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  /// Chame uma vez após o 1º frame (ex.: no MainScreen.initState)
  static Future<void> maybeStart(BuildContext context, {bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!force && done) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingFlow(), fullscreenDialog: true),
    );
  }

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

enum _Step { name, phone, cep, address }

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Step step = _Step.name;

  // controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();

  // masks
  final _phoneMask = MaskTextInputFormatter(mask: '(##) #####-####');
  final _cepMask = MaskTextInputFormatter(mask: '#####-###');

  bool _busy = false;
  bool _saveAddress = true;

  // endereço vindo do CEP
  String? _street;
  String? _neighborhood;
  String? _city;
  String? _state;

  // taxa
  String? _shippingCost; // "29.90"

  String get _firstName {
    final t = _nameCtrl.text.trim();
    return t.isEmpty ? '' : t.split(RegExp(r'\s+')).first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cepCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    super.dispose();
  }

  // ----------------- helpers UI -----------------
  InputDecoration _decor({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _primaryButton(String label, {required VoidCallback onTap, bool busy = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: busy
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
    );
  }

  Widget _centerCard({required Widget child, Key? key}) {
    return LayoutBuilder(
      builder: (context, c) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: c.maxWidth > 520 ? 520 : c.maxWidth),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: child,
          ),
        ),
      ),
    );
  }

  String _digits(String v) => v.replaceAll(RegExp(r'[^0-9]'), '');
  String _formatBRL(String raw) {
    // "29.90" -> "R$ 29,90"
    final s = raw.replaceAll('.', ',');
    return 'R\$ $s';
  }

  // ----------------- backend: CEP + taxa -----------------
  Future<void> _lookupFromCep(String cepDigits) async {
    _street = _neighborhood = _city = _state = null;
    _shippingCost = null;
    setState(() {});

    // 1) endereço: ViaCEP
    try {
      final r = await http
          .get(Uri.parse('https://viacep.com.br/ws/$cepDigits/json/'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final m = json.decode(r.body) as Map<String, dynamic>;
        if (m['erro'] != true) {
          _street = (m['logradouro'] as String?)?.trim();
          _neighborhood = (m['bairro'] as String?)?.trim();
          _city = (m['localidade'] as String?)?.trim();
          _state = (m['uf'] as String?)?.trim();
        }
      }
    } catch (_) {}

    // 2) taxa: seu endpoint
    try {
      final r = await http
          .get(Uri.parse('https://aogosto.com.br/delivery/wp-json/custom/v1/shipping-cost?cep=$cepDigits'))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode == 200) {
        final m = json.decode(r.body) as Map<String, dynamic>;
        final opts = (m['shipping_options'] as List?) ?? [];
        if (opts.isNotEmpty && opts.first is Map<String, dynamic>) {
          _shippingCost = (opts.first['cost'] as String?) ?? _shippingCost;
        }
      }
    } catch (_) {}

    setState(() {});
  }

  // ----------------- steps -----------------
  Widget _stepName() => _centerCard(
        child: Padding(
          key: const ValueKey('step_name'),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Oi! 👋 Bem-vindo à Ao Gosto Carnes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pra começar, como podemos te chamar?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Color(0xFF6B7280), height: 1.35),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: _decor(hint: 'Seu nome', icon: Icons.person_outline_rounded),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _goFromName(),
              ),
              const SizedBox(height: 24),
              _primaryButton('Continuar', onTap: _goFromName),
            ],
          ),
        ),
      );

  void _goFromName() {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => step = _Step.phone);
  }

  Widget _stepPhone() => _centerCard(
        child: Padding(
          key: const ValueKey('step_phone'),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Perfeito, ${_firstName.isEmpty ? 'tudo certo' : _firstName} 😄',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pode nos passar seu número? Assim a gente te avisa quando o pedido sair pra entrega.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Color(0xFF6B7280), height: 1.35),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneMask],
                decoration: _decor(hint: '(00) 00000-0000', icon: Icons.phone_outlined),
                onSubmitted: (_) => _goFromPhone(),
              ),
              const SizedBox(height: 24),
              _primaryButton('Continuar', onTap: _goFromPhone),
            ],
          ),
        ),
      );

  void _goFromPhone() {
    if (_digits(_phoneCtrl.text).length < 10) return;
    setState(() => step = _Step.cep);
  }

  Widget _stepCep() => _centerCard(
        child: Padding(
          key: const ValueKey('step_cep'),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Agora me conta seu CEP rapidinho 👇',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
              ),
              const SizedBox(height: 12),
              const Text(
                'Assim eu vejo se a gente entrega aí e já calculo a taxa certinha.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Color(0xFF6B7280), height: 1.35),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _cepCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [_cepMask],
                decoration: _decor(hint: '00000-000', icon: Icons.location_on_outlined),
                onSubmitted: (_) => _verifyCep(),
              ),
              const SizedBox(height: 24),
              _primaryButton('Verificar CEP', onTap: _verifyCep, busy: _busy),
            ],
          ),
        ),
      );

  Future<void> _verifyCep() async {
    final digits = _digits(_cepCtrl.text);
    if (digits.length != 8) return;
    setState(() => _busy = true);
    await _lookupFromCep(digits);
    setState(() {
      _busy = false;
      step = _Step.address;
    });
  }

  Widget _stepAddress() {
    final cost = _shippingCost;
    return _centerCard(
      child: Padding(
        key: const ValueKey('step_address'),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Legal! Entregamos na sua região 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'A taxa de entrega é de ',
                    style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
                  ),
                  TextSpan(
                    text: cost != null ? _formatBRL(cost) : '—',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                  ),
                  const TextSpan(
                    text: '. Só confirma pra mim o número e complemento, tá?',
                    style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // rua (readonly)
            TextField(
              controller: TextEditingController(text: _street ?? ''),
              readOnly: true,
              decoration: _decor(hint: 'Rua', icon: Icons.home_outlined)
                  .copyWith(fillColor: const Color(0xFFF3F4F6)),
            ),
            const SizedBox(height: 12),

            // número (apenas dígitos)
            TextField(
              controller: _numberCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decor(hint: 'Número', icon: Icons.numbers),
            ),
            const SizedBox(height: 12),

            // complemento
            TextField(
              controller: _complementCtrl,
              decoration: _decor(hint: 'Complemento (opcional)', icon: Icons.note_outlined),
            ),
            const SizedBox(height: 12),

            // bairro (readonly)
            TextField(
              controller: TextEditingController(text: _neighborhood ?? ''),
              readOnly: true,
              decoration: _decor(hint: 'Bairro', icon: Icons.map_outlined)
                  .copyWith(fillColor: const Color(0xFFF3F4F6)),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _saveAddress,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _saveAddress = v ?? true),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Salvar este endereço para próximos pedidos',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _primaryButton('Salvar e finalizar', onTap: _finish, busy: _busy),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    if (_numberCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final customerData = {
      'name': _nameCtrl.text.trim(),
      'phone': _digits(_phoneCtrl.text),
    };
    final addressData = {
      'street': _street ?? '',
      'number': _numberCtrl.text.trim(),
      'complement': _complementCtrl.text.trim(),
      'neighborhood': _neighborhood ?? '',
      'city': _city ?? '',
      'state': _state ?? '',
      'cep': _digits(_cepCtrl.text),
    };
    try {
      final response = await http.post(
        Uri.parse('https://aogosto.com.br/app/onboarding/register.php'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'customer': customerData, 'address': addressData}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true && data['customer_id'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs
            ..setBool('onboarding_done', true)
            ..setInt('customer_id', data['customer_id'] as int)
            ..setString('customer_name', customerData['name'] ?? '')
            ..setString('customer_phone', customerData['phone'] ?? '')
            ..setString('address_cep', addressData['cep'] ?? '');
          if (!mounted) return;
          Navigator.of(context).pop();
        } else {
          throw Exception('Registro falhou: ${data['error']}');
        }
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao registrar: $e');
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao registrar: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // fundo branco e conteúdo centralizado/rolável
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (step == _Step.name) _stepName(),
                  if (step == _Step.phone) _stepPhone(),
                  if (step == _Step.cep) _stepCep(),
                  if (step == _Step.address) _stepAddress(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}