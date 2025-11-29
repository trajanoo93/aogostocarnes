// lib/screens/profile/widgets/address_form_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class AddressFormSheet extends StatefulWidget {
  final Map<String, dynamic>? address;
  final Function(Map<String, dynamic>) onSave;

  const AddressFormSheet({
    super.key,
    this.address,
    required this.onSave,
  });

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  Future<Map<String, dynamic>?> _lookupCep(String cep) async {
  final clean = cep.replaceAll(RegExp(r'\D'), '');
  if (clean.length != 8) return null;

  try {
    final resp = await http.get(Uri.parse('https://viacep.com.br/ws/$clean/json/'));
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      if (data['erro'] != true) {
        return {
          'street': data['logradouro'] ?? '',
          'neighborhood': data['bairro'] ?? '',
          'city': data['localidade'] ?? '',
          'state': data['uf'] ?? '',
        };
      }
    }
  } catch (e) {
    // silencioso
  }
  return null;
}
  
  late TextEditingController _nicknameCtrl;
  late TextEditingController _cepCtrl;
  late TextEditingController _streetCtrl;
  late TextEditingController _numberCtrl;
  late TextEditingController _complementCtrl;
  late TextEditingController _neighborhoodCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  
  bool _isLoadingCep = false;

  @override
  void initState() {
    super.initState();
    
    final addr = widget.address;
    _nicknameCtrl = TextEditingController(text: addr?['nickname'] ?? '');
    _cepCtrl = TextEditingController(text: addr?['cep'] ?? '');
    _streetCtrl = TextEditingController(text: addr?['street'] ?? '');
    _numberCtrl = TextEditingController(text: addr?['number'] ?? '');
    _complementCtrl = TextEditingController(text: addr?['complement'] ?? '');
    _neighborhoodCtrl = TextEditingController(text: addr?['neighborhood'] ?? '');
    _cityCtrl = TextEditingController(text: addr?['city'] ?? '');
    _stateCtrl = TextEditingController(text: addr?['state'] ?? '');
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _cepCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchCep() async {
  final cep = _cepCtrl.text.replaceAll(RegExp(r'\D'), '');
  if (cep.length != 8) return;

  setState(() => _isLoadingCep = true);

  final result = await _lookupCep(cep);
  if (result != null && mounted) {
    setState(() {
      _streetCtrl.text = result['street'] ?? '';
      _neighborhoodCtrl.text = result['neighborhood'] ?? '';
      _cityCtrl.text = result['city'] ?? '';
      _stateCtrl.text = result['state'] ?? '';
    });
  }

  if (mounted) setState(() => _isLoadingCep = false);
}


  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Título
              Text(
                widget.address == null ? 'Novo Endereço' : 'Editar Endereço',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preencha os dados abaixo',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Apelido
              _buildTextField(
                controller: _nicknameCtrl,
                label: 'Apelido',
                hint: 'Ex: Casa, Trabalho, Casa da sogra...',
                icon: Icons.label_outline_rounded,
                validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // CEP
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cepCtrl,
                      label: 'CEP',
                      hint: '00000-000',
                      icon: Icons.location_on_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      validator: (v) {
                        final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                        return digits.length != 8 ? 'CEP inválido' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoadingCep ? null : _searchCep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingCep
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rua
              _buildTextField(
                controller: _streetCtrl,
                label: 'Rua',
                hint: 'Nome da rua',
                icon: Icons.signpost_outlined,
                validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // Número e Complemento
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _numberCtrl,
                      label: 'Número',
                      hint: '123',
                      icon: Icons.numbers_rounded,
                      validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      controller: _complementCtrl,
                      label: 'Complemento',
                      hint: 'Apto, bloco...',
                      icon: Icons.home_work_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bairro
              _buildTextField(
                controller: _neighborhoodCtrl,
                label: 'Bairro',
                hint: 'Nome do bairro',
                icon: Icons.map_outlined,
                validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // Cidade e Estado
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      controller: _cityCtrl,
                      label: 'Cidade',
                      hint: 'Nome da cidade',
                      icon: Icons.location_city_outlined,
                      validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _buildTextField(
                      controller: _stateCtrl,
                      label: 'UF',
                      hint: 'MG',
                      icon: Icons.place_outlined,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                        LengthLimitingTextInputFormatter(2),
                      ],
                      validator: (v) {
                        final text = v?.toUpperCase() ?? '';
                        return text.length != 2 ? 'UF inválida' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Salvar Endereço',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final addressData = {
      'id': widget.address?['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'nickname': _nicknameCtrl.text.trim(),
      'street': _streetCtrl.text.trim(),
      'number': _numberCtrl.text.trim(),
      'complement': _complementCtrl.text.trim(),
      'neighborhood': _neighborhoodCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim().toUpperCase(),
      'cep': _formatCep(_cepCtrl.text),
      'isDefault': widget.address?['isDefault'] ?? false,
    };

    widget.onSave(addressData);
    Navigator.pop(context);
  }

  String _formatCep(String cep) {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) {
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    }
    return cep;
  }
}