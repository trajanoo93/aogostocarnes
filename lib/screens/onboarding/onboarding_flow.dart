// screens/onboarding/onboarding_flow.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/state/customer_provider.dart';   
import 'package:ao_gosto_app/models/customer_data.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  static Future<void> maybeStart(BuildContext context, {bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!force && done) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const OnboardingFlow(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

enum _Step { name, phone, cep, address }

class _OnboardingFlowState extends State<OnboardingFlow> with TickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  _Step _step = _Step.name;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _cepFocus = FocusNode();
  final _numberFocus = FocusNode();
  final _complementFocus = FocusNode();

  final _phoneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final _cepMask = MaskTextInputFormatter(mask: '#####-###', filter: {"#": RegExp(r'[0-9]')});

  bool _isLoading = false;
  String? _error;
  bool _saveAddress = true;

  String? _street, _neighborhood, _city, _state;
  double? _deliveryFee;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    _nameCtrl.addListener(() => setState(() {}));
    _phoneCtrl.addListener(() => setState(() {}));
    _cepCtrl.addListener(() => setState(() {}));
    _numberCtrl.addListener(() => setState(() {}));
    _complementCtrl.addListener(() => setState(() {}));

    _nameFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
    _cepFocus.addListener(() => setState(() {}));
    _numberFocus.addListener(() => setState(() {}));
    _complementFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cepCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _cepFocus.dispose();
    _numberFocus.dispose();
    _complementFocus.dispose();
    super.dispose();
  }

  String get _firstName => _nameCtrl.text.trim().split(' ').firstOrNull ?? 'você';

  void _nextStep(_Step next) {
    _animCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _step = next);
        _animCtrl.forward();
        if (next == _Step.address) {
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) FocusScope.of(context).requestFocus(_numberFocus);
          });
        }
      }
    });
  }

  bool get _canProceedName => _nameCtrl.text.trim().isNotEmpty;
  bool get _canProceedPhone => _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length >= 10;
  bool get _canProceedCep => _cepCtrl.text.replaceAll(RegExp(r'\D'), '').length == 8;

  Future<void> _fetchCepAndFee() async {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _street = _neighborhood = _city = _state = _deliveryFee = null;
    });

    try {
      final viaResp = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/')).timeout(const Duration(seconds: 8));
      if (viaResp.statusCode != 200 || json.decode(viaResp.body)['erro'] == true) {
        throw Exception('CEP não encontrado');
      }
      final data = json.decode(viaResp.body);
      _street = data['logradouro']?.toString().trim();
      _neighborhood = data['bairro']?.toString().trim();
      _city = data['localidade']?.toString().trim();
      _state = data['uf']?.toString().trim();

      final feeResp = await http.get(Uri.parse('https://aogosto.com.br/delivery/wp-json/custom/v1/shipping-cost?cep=$cep')).timeout(const Duration(seconds: 8));
      if (feeResp.statusCode != 200) throw Exception('Erro ao calcular frete');
      final feeData = json.decode(feeResp.body);
      final options = feeData['shipping_options'] as List?;
      if (options?.isNotEmpty != true) throw Exception('Frete não disponível');
      _deliveryFee = double.tryParse(options!.first['cost'].toString().replaceAll(',', '.')) ?? 0.0;
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
      if (_error == null && _deliveryFee != null && mounted) {
        _nextStep(_Step.address);
      }
    }
  }

  Future<void> _saveAndFinish() async {
    if (_numberCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final telefoneLimpo = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

      final novoEndereco = CustomerAddress(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        apelido: "Minha Casa",
        street: _street ?? '',
        number: _numberCtrl.text.trim(),
        complement: _complementCtrl.text.trim().isEmpty ? null : _complementCtrl.text.trim(),
        neighborhood: _neighborhood ?? '',
        city: _city ?? '',
        state: _state ?? '',
        cep: _cepCtrl.text.replaceAll(RegExp(r'\D'), ''),
        isDefault: true,
      );

      await CustomerProvider.instance.loadOrCreateCustomer(
        name: _nameCtrl.text.trim(),
        phone: telefoneLimpo,
        initialAddress: novoEndereco,
      );

      CartController.instance.setDeliveryFee(_deliveryFee ?? 0.0);

      final sp = await SharedPreferences.getInstance();
      await sp.setBool('onboarding_done', true);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: false,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(opacity: _fadeAnim, child: _currentStep()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _currentStep() {
    switch (_step) {
      case _Step.name:
        return _stepName();
      case _Step.phone:
        return _stepPhone();
      case _Step.cep:
        return _stepCep();
      case _Step.address:
        return _stepAddress();
    }
  }

  // === INPUT MODERNO IDÊNTICO AO HTML ===
  Widget _customInput({
    required String placeholder,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool autofocus = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasContent = controller.text.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? const Color(0xFFFA4815) : const Color(0xFFE4E4E7),
          width: 2,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFFFA4815).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 0),
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: isFocused || hasContent 
                ? const Color(0xFFFA4815) 
                : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: const Color(0xFF18181B),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF71717A),
                  fontSize: 18,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              cursorColor: const Color(0xFFFA4815),
            ),
          ),
        ],
      ),
    );
  }

  // === BOTÃO IDÊNTICO AO HTML ===
  Widget _primaryButton(String text, VoidCallback? onPressed, {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? const Color(0xFF9CA3AF) : const Color(0xFFFA4815),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: const Color(0xFF9CA3AF),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  // === STEPS COM EMOJIS ===
  Widget _stepName() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Oi! 👋 Bem-vindo à Ao Gosto Carnes.',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF18181B),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Pra começar, como podemos te chamar?',
            style: GoogleFonts.poppins(fontSize: 18, color: const Color(0xFF71717A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _customInput(
            placeholder: 'Seu nome',
            icon: Icons.person_outline,
            controller: _nameCtrl,
            focusNode: _nameFocus,
            autofocus: true,
          ),
          const SizedBox(height: 24),
          _primaryButton('Continuar', _canProceedName ? () => _nextStep(_Step.phone) : null),
        ],
      );

  Widget _stepPhone() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Perfeito, $_firstName 😄',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF18181B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Pode nos passar seu número? Assim a gente te avisa quando o pedido sair pra entrega.',
            style: GoogleFonts.poppins(fontSize: 18, color: const Color(0xFF71717A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _customInput(
            placeholder: '(00) 00000-0000',
            icon: Icons.phone_outlined,
            controller: _phoneCtrl,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            inputFormatters: [_phoneMask],
            autofocus: true,
          ),
          const SizedBox(height: 24),
          _primaryButton('Continuar', _canProceedPhone ? () => _nextStep(_Step.cep) : null),
        ],
      );

  Widget _stepCep() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Agora me conta seu CEP rapidinho 👇',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF18181B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Assim eu vejo se a gente entrega aí e já calculo a taxa certinha.',
            style: GoogleFonts.poppins(fontSize: 18, color: const Color(0xFF71717A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _customInput(
            placeholder: '00000-000',
            icon: Icons.location_on_outlined,
            controller: _cepCtrl,
            focusNode: _cepFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [_cepMask],
            autofocus: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 14)),
          ],
          const SizedBox(height: 24),
          _primaryButton(
            _isLoading ? 'Verificando...' : 'Verificar CEP',
            _canProceedCep && !_isLoading ? _fetchCepAndFee : null,
            loading: _isLoading,
          ),
        ],
      );

  Widget _stepAddress() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Legal! Entregamos na sua região 🎉',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF18181B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'A taxa de entrega é de ',
                  style: GoogleFonts.poppins(fontSize: 18, color: const Color(0xFF71717A)),
                ),
                TextSpan(
                  text: 'R\$ ${_deliveryFee?.toStringAsFixed(2).replaceAll('.', ',') ?? '--'}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFA4815),
                  ),
                ),
                TextSpan(
                  text: '. Só confirma pra mim o número e complemento, tá?',
                  style: GoogleFonts.poppins(fontSize: 18, color: const Color(0xFF71717A)),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _addressField(
            label: 'Rua',
            value: _street ?? '',
            isReadOnly: true,
          ),
          const SizedBox(height: 16),
          _addressField(
            label: 'Número',
            controller: _numberCtrl,
            focusNode: _numberFocus,
          ),
          const SizedBox(height: 16),
          _addressField(
            label: 'Complemento (opcional)',
            controller: _complementCtrl,
            focusNode: _complementFocus,
          ),
          const SizedBox(height: 16),
          _addressField(
            label: 'Bairro',
            value: _neighborhood ?? '',
            isReadOnly: true,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _saveAddress,
                  onChanged: (v) => setState(() => _saveAddress = v ?? true),
                  activeColor: const Color(0xFFFA4815),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Salvar este endereço para próximos pedidos',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFF3F3F46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _primaryButton(
            'Salvar e finalizar',
            _numberCtrl.text.trim().isNotEmpty && !_isLoading ? _saveAndFinish : null,
            loading: _isLoading,
          ),
        ],
      ),
    );
  }

  // === CAMPO DE ENDEREÇO IDÊNTICO AO HTML (FLOATING LABEL) ===
  Widget _addressField({
    required String label,
    String? value,
    TextEditingController? controller,
    FocusNode? focusNode,
    bool isReadOnly = false,
  }) {
    final isFocused = focusNode?.hasFocus ?? false;
    final hasContent = isReadOnly || (controller != null && controller.text.isNotEmpty);
    final shouldFloat = isFocused || hasContent;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 68),
      decoration: BoxDecoration(
        color: isReadOnly ? const Color(0xFFF4F4F5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReadOnly 
              ? const Color(0xFFD4D4D8)
              : (isFocused ? const Color(0xFFFA4815) : const Color(0xFFD4D4D8)),
          width: isFocused && !isReadOnly ? 2 : 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // Label flutuante
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            top: shouldFloat ? 4 : 16,
            left: 0,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: GoogleFonts.poppins(
                fontSize: shouldFloat ? 12 : 16,
                color: isFocused && !isReadOnly
                    ? const Color(0xFFFA4815)
                    : const Color(0xFF71717A),
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
              child: Text(label),
            ),
          ),
          // Campo de texto
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: isReadOnly
                ? Text(
                    value ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF3F3F46),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  )
                : TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF18181B),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    cursorColor: const Color(0xFFFA4815),
                  ),
          ),
        ],
      ),
    );
  }
}