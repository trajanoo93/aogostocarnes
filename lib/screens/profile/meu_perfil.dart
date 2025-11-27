// lib/screens/profile/meu_perfil.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:ao_gosto_app/state/customer_provider.dart';
import 'package:ao_gosto_app/models/customer_data.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/profile/widgets/address_form_sheet.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class MeuPerfilPage extends StatefulWidget {
  const MeuPerfilPage({super.key});

  @override
  State<MeuPerfilPage> createState() => _MeuPerfilPageState();
}

class _MeuPerfilPageState extends State<MeuPerfilPage> {
  bool _isLoading = true;
  String _name = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<CustomerProvider>(context, listen: false);

      if (provider.customer == null) {
        final prefs = await SharedPreferences.getInstance();
        final phone = prefs.getString('customer_phone');
        final name = prefs.getString('customer_name');
        if (phone != null && name != null) {
          await provider.loadOrCreateCustomer(name: name, phone: phone);
        }
      }

      final customer = provider.customer;
      if (customer != null) {
        _name = customer.name;
        _phone = customer.phone;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<CustomerAddress> _getAddresses() {
    final customer = Provider.of<CustomerProvider>(context, listen: false).customer;
    return customer?.addresses ?? [];
  }

  @override
Widget build(BuildContext context) {
  return Consumer<CustomerProvider>(
    builder: (context, provider, child) {
      final customer = provider.customer;

      if (customer == null || provider.isLoading) {
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }

      return Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        _buildAvatar(),
                        const SizedBox(height: 16),
                        Text(
                          customer.name, // ← agora atualiza na hora
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Dados Pessoais'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.person_outline_rounded,
                      title: 'Nome completo',
                      value: customer.name,
                      onEdit: () => _showEditBottomSheet('Nome', customer.name),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.phone_outlined,
                      title: 'Telefone',
                      value: _formatPhone(customer.phone),
                      onEdit: _showEditPhoneBottomSheet,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Endereços'),
                    const SizedBox(height: 12),
                    ...customer.addresses.map((addr) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAddressCard(addr),
                        )),
                    _buildAddAddressButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

 
  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 50),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value.isEmpty ? 'Não informado' : value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: value.isEmpty ? Colors.grey[400] : AppColors.textPrimary)),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: Icon(Icons.edit_outlined, color: Colors.grey[400], size: 20)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(CustomerAddress addr) {
  final isDefault = addr.isDefault;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDefault ? AppColors.primary : Colors.grey[200]!, width: isDefault ? 2 : 1),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.home_outlined, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Text(addr.apelido, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Padrão', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
            // POPUPMENU LINDO, BRANCO E CLEAN
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              offset: const Offset(0, 45),
              onSelected: (value) async {
                final provider = Provider.of<CustomerProvider>(context, listen: false);

                if (value == 'edit') {
                  _showAddressBottomSheet(addressMap: addr.toMap());
                } else if (value == 'default') {
                  final updated = addr.copyWith(isDefault: true);
                  await provider.saveAddress(updated, setAsDefault: true);
                } else if (value == 'delete') {
                  final customer = provider.customer!;
                  final newList = customer.addresses.where((a) => a.id != addr.id).toList();
                  await provider.updateCustomer(customer.copyWith(addresses: newList));
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Editar'),
                    ],
                  ),
                ),
                if (!isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                        SizedBox(width: 12),
                        Text('Tornar padrão'),
                      ],
                    ),
                  ),
                if (!isDefault)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${addr.street}, ${addr.number}', style: const TextStyle(fontWeight: FontWeight.w600)),
              if (addr.complement?.isNotEmpty == true) Text(addr.complement!),
              Text('${addr.neighborhood} - ${addr.city}/${addr.state}'),
              Text('CEP: ${addr.cep}'),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildAddAddressButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddressBottomSheet(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text('Adicionar novo endereço',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    return phone;
  }

  // ====================== EDIÇÃO DE NOME (agora salva no Firestore) ======================
  void _showEditBottomSheet(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    final customer = provider.customer;
    if (customer == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, color: Colors.grey[300])),
              const SizedBox(height: 24),
              Text('Editar $field', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: field,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newValue = controller.text.trim();
                        if (newValue.isNotEmpty) {
                          await provider.updateCustomer(customer.copyWith(name: newValue));
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================== EDIÇÃO DE TELEFONE (agora salva no Firestore) ======================
  void _showEditPhoneBottomSheet() async {
    final phoneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    final customer = provider.customer;
    if (customer == null) return;

    final controller = TextEditingController(text: _formatPhone(customer.phone));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, color: Colors.grey[300])),
              const SizedBox(height: 24),
              const Text('Editar Telefone', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [phoneMask],
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(31) 99999-9999',
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final clean = phoneMask.getUnmaskedText();
                        if (clean.length == 11) {
                          await provider.updateCustomer(customer.copyWith(phone: clean));
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================== BOTTOM SHEET DE ENDEREÇO (compatível com AddressFormSheet antigo) ======================
  void _showAddressBottomSheet({Map<String, dynamic>? addressMap}) {
    final address = addressMap != null ? CustomerAddress.fromMap(addressMap) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormSheet(
        address: addressMap, // AddressFormSheet ainda espera Map<String, dynamic>?
        onSave: (addressData) async {
          final provider = Provider.of<CustomerProvider>(context, listen: false);

          final novoEndereco = CustomerAddress(
            id: address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
            apelido: addressData['apelido'] ?? 'Endereço',
            street: addressData['street'],
            number: addressData['number'],
            complement: addressData['complement'],
            neighborhood: addressData['neighborhood'],
            city: addressData['city'],
            state: addressData['state'],
            cep: addressData['cep'],
            isDefault: address?.isDefault ?? false,
          );

          await provider.saveAddress(novoEndereco, setAsDefault: novoEndereco.isDefault);
        },
      ),
    );
  }
}