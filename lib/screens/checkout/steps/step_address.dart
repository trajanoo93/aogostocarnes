// lib/screens/checkout/steps/step_address.dart 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/state/customer_provider.dart';
import 'package:ao_gosto_app/models/customer_data.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart';
import 'package:ao_gosto_app/screens/checkout/widgets/calendar_widget.dart';
import 'package:ao_gosto_app/screens/checkout/widgets/time_slot_grid.dart';
import 'package:ao_gosto_app/screens/checkout/widgets/summary_checkout.dart';
import 'package:ao_gosto_app/screens/profile/widgets/address_form_sheet.dart';
import 'package:ao_gosto_app/services/remote_config_service.dart';

class StepAddress extends StatelessWidget {
  const StepAddress({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final customerProv = context.watch<CustomerProvider>();
    final customer = customerProv.customer;

    if (customer == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final addresses = customer.addresses;

    return Column(
      children: [
        // 1. CONTATO
        _ContactSection(),
        const SizedBox(height: 12),
        
        // 2. TIPO DE ENTREGA (com setState)
        _UltraModernDeliveryType(),
        const SizedBox(height: 12),
        
        // 3. ENDEREÇO OU RETIRADA
        if (c.deliveryType == DeliveryType.delivery)
          _AddressSection(addresses: addresses, controller: c)
        else
          _PickupSection(),
        const SizedBox(height: 12),
        
        // 4. AGENDAMENTO
        _ScheduleSection(),
        const SizedBox(height: 12),
        
        // 5. OBSERVAÇÕES
        _NotesSection(),
        const SizedBox(height: 12),
        
        // 6. RESUMO DO PEDIDO (NO FIM!)
        const SummaryCheckout(),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//              CONTATO COM ÍCONE WHATSAPP
// ═══════════════════════════════════════════════════════════
class _ContactSection extends StatefulWidget {
  @override
  State<_ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<_ContactSection> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    final c = context.read<CheckoutController>();
    _controller = TextEditingController(text: c.userPhone);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDeco(),
      child: c.isEditingPhone
          ? Column(
              children: [
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '(00) 00000-0000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _controller.text = c.userPhone;
                          c.cancelEditPhone();
                          setState(() {});
                        },
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await c.savePhone(_controller.text);
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Salvar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.formatPhone(c.userPhone.isEmpty ? '—' : c.userPhone),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      const Text(
                        'WhatsApp para notificações',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  onPressed: () {
                    c.startEditPhone();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF71717A),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//    TIPO DE ENTREGA - ULTRA MODERNO (COM ATUALIZAÇÃO INSTANTÂNEA)
// ═══════════════════════════════════════════════════════════
class _UltraModernDeliveryType extends StatefulWidget {
  @override
  State<_UltraModernDeliveryType> createState() => _UltraModernDeliveryTypeState();
}

class _UltraModernDeliveryTypeState extends State<_UltraModernDeliveryType> {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como você prefere receber?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _DeliveryOptionCard(
                  title: 'Receber',
                  subtitle: 'em casa',
                  icon: Icons.electric_bike_rounded,
                  primaryColor: AppColors.primary,
                  secondaryColor: const Color(0xFFFF8C00),
                  lightColor: const Color(0xFFFFF7ED),
                  active: c.deliveryType == DeliveryType.delivery,
                  onTap: () {
                    c.setDeliveryType(DeliveryType.delivery);
                    setState(() {});
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _DeliveryOptionCard(
                  title: 'Retirar',
                  subtitle: 'na loja',
                  icon: Icons.storefront_rounded,
                  primaryColor: const Color(0xFF16A34A),
                  secondaryColor: const Color(0xFF059669),
                  lightColor: const Color(0xFFECFDF5),
                  active: c.deliveryType == DeliveryType.pickup,
                  onTap: () {
                    c.setDeliveryType(DeliveryType.pickup);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final Color lightColor;
  final bool active;
  final VoidCallback onTap;

  const _DeliveryOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.lightColor,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: active ? 1.0 : 0.0),
        builder: (context, value, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: 130,
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withOpacity(0.15 + (value * 0.05)),
                        lightColor,
                      ],
                    )
                  : null,
              color: active ? null : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? primaryColor : const Color(0xFFE5E7EB),
                width: active ? 2 : 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.15 * value),
                        blurRadius: 20 * value,
                        offset: Offset(0, 8 * value),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Padrão decorativo no fundo
                if (active)
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Opacity(
                      opacity: 0.1 * value,
                      child: Icon(
                        icon,
                        size: 100,
                        color: primaryColor,
                      ),
                    ),
                  ),
                
                // Conteúdo
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ícone
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: active
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [primaryColor, secondaryColor],
                                )
                              : null,
                          color: active ? null : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3 * value),
                                    blurRadius: 12 * value,
                                    offset: Offset(0, 4 * value),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: active ? Colors.white : const Color(0xFF71717A),
                          size: 28,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Texto
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: active
                              ? const Color(0xFF18181B)
                              : const Color(0xFF71717A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? const Color(0xFF52525B)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      
                      // Indicador ativo
                      if (active)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          height: 3,
                          width: 40 * value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Check badge
                if (active)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ✅ ATUALIZADO: ENDEREÇO COM VALIDAÇÃO DE FRETE
// ═══════════════════════════════════════════════════════════
class _AddressSection extends StatelessWidget {
  final List<CustomerAddress> addresses;
  final CheckoutController controller;
  
  const _AddressSection({
    required this.addresses,
    required this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Endereço de Entrega',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
              
              TextButton.icon(
                onPressed: () => _showAddressSheet(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Novo'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          
          if (addresses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nenhum endereço cadastrado',
                  style: TextStyle(color: Color(0xFF71717A)),
                ),
              ),
            )
          else
            const SizedBox(height: 12),
          
          ...addresses.map((addr) {
            final isSelected = addr.id == controller.selectedAddressId;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  controller.selectAddress(addr.id);
                  controller.refreshFee();
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.05)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFD4D4D8),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              )
                            : null,
                      ),
                      
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  addr.apelido,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF18181B),
                                  ),
                                ),
                                
                                if (addr.isDefault)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Padrão',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${addr.street}, ${addr.number}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF71717A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          // ✅ CARD DE TAXA DE ENTREGA
          if (controller.selectedAddressId != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Taxa de Entrega',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF71717A),
                    ),
                  ),
                  const Spacer(),
                  
                  // ✅ LOADING
                  if (controller.isCalculatingFee)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  
                  // ✅ ERRO (CEP FORA DE ÁREA)
                  else if (controller.deliveryFee < 0)
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Fora de área',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    )
                  
                  // ✅ TAXA VÁLIDA
                  else
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        key: ValueKey(controller.deliveryFee),
                        controller.deliveryFee > 0
                            ? 'R\$ ${controller.deliveryFee.toStringAsFixed(2)}'
                            : 'Grátis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: controller.deliveryFee > 0
                              ? const Color(0xFF18181B)
                              : Colors.green[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // ✅ BANNER DE ERRO QUANDO CEP FORA DE ÁREA
          if (controller.selectedAddressId != null && controller.deliveryFee < 0)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_off_rounded,
                      color: Colors.red[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CEP fora da área de entrega',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Infelizmente não entregamos neste endereço. Você pode retirar o pedido em uma de nossas lojas.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

void _showAddressSheet(BuildContext context) {
  final provider = Provider.of<CustomerProvider>(context, listen: false);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddressFormSheet(
      onSave: (data) async {
        final novoEndereco = CustomerAddress(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          apelido: data['apelido'] ?? 'Endereço',
          street: data['street'],
          number: data['number'],
          complement: data['complement'],
          neighborhood: data['neighborhood'],
          city: data['city'],
          state: data['state'],
          cep: data['cep'],
          isDefault: provider.customer?.addresses.isEmpty ?? true,
        );

        await provider.saveAddress(novoEndereco, setAsDefault: novoEndereco.isDefault);
        Navigator.pop(context);
      },
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//                    RETIRADA (CORRIGIDA)
// ═══════════════════════════════════════════════════════════
class _PickupSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    
    return FutureBuilder<RemoteConfig>(
      future: RemoteConfigService.fetchConfig(),
      builder: (context, snapshot) {
        final pickupStores = snapshot.data?.pickupStores ?? {
          'barreiro': true,
          'sion': true,
          'central': true,
          'lagosanta': true,
        };
        
        // ✅ FILTRA APENAS LOJAS HABILITADAS
        final availableStores = c.pickupLocations.entries
            .where((e) => pickupStores[e.key] == true)
            .toList();
        
        if (availableStores.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: _boxDeco(),
            child: const Text(
              'Nenhuma unidade de retirada disponível no momento',
              style: TextStyle(color: Color(0xFF71717A)),
            ),
          );
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: _boxDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Local de Retirada',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
              
              const SizedBox(height: 12),
              
              ...availableStores.map((e) {
                final key = e.key;
                final loc = e.value;
                final active = key == c.selectedPickup;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => c.selectPickup(key),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary.withOpacity(0.05)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : const Color(0xFFD4D4D8),
                                width: 2,
                              ),
                            ),
                            child: active
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 10,
                                  )
                                : null,
                          ),
                          
                          const SizedBox(width: 12),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc['name']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF18181B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loc['address']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF71717A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  AGENDAMENTO COM FORMATAÇÃO INTELIGENTE
// ═══════════════════════════════════════════════════════════
class _ScheduleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final hasSchedule = c.selectedTimeSlot != null;
    
    // ✨ Verifica se a data selecionada é um dia fechado
    final isClosed = CheckoutController.isClosedDay(c.selectedDate);
    
    // ✨ Verifica se é um dia especial
    final isSpecial = CheckoutController.isSpecialDay(c.selectedDate);
    
    // ✨ Obtém os slots disponíveis
    final slots = c.getTimeSlots();
    final hasNoSlots = slots.isEmpty && !isClosed;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quando você quer receber?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // ✨ Input de data com formatação inteligente
          InkWell(
            onTap: () => _showCalendarModal(context, c),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: hasSchedule
                        ? AppColors.primary
                        : const Color(0xFF71717A),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.getSmartDateLabel(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hasSchedule
                            ? const Color(0xFF18181B)
                            : const Color(0xFF71717A),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 🎄 DIA FECHADO (RECESSO)
          if (isClosed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[50]!, Colors.orange[50]!],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.celebration_rounded,
                      color: Colors.red[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estamos de recesso! 🎉',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Não realizamos entregas neste dia.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          
          // 🎁 DIA ESPECIAL (HORÁRIO REDUZIDO)
          else if (isSpecial && slots.isNotEmpty)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[50]!, Colors.orange[50]!],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.amber[800],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Horários especiais neste dia 🎄',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TimeSlotGrid(
                    slots: slots,
                    selectedSlot: c.selectedTimeSlot,
                    onSlotSelected: (slot) {
                      c.setTimeSlot(slot);
                    },
                  ),
                ),
              ],
            )
          
          // 😔 SEM SLOTS (HORÁRIOS ESGOTADOS)
          else if (hasNoSlots)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Horários esgotados',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Selecione outro dia ou tente amanhã',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          
          // ✅ SLOTS DISPONÍVEIS
          else if (slots.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: TimeSlotGrid(
                slots: slots,
                selectedSlot: c.selectedTimeSlot,
                onSlotSelected: (slot) {
                  c.setTimeSlot(slot);
                },
              ),
            ),
          
          // ✅ RESUMO DO AGENDAMENTO
          if (hasSchedule && !isClosed)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${c.getSmartDateLabel()} • ${c.selectedTimeSlot}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

void _showCalendarModal(BuildContext context, CheckoutController c) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      height: MediaQuery.of(ctx).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Selecione a Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CalendarWidget(
              selectedDate: c.selectedDate,
              onDateSelected: (date) {
                c.selectedDate = date;
                c.selectedTimeSlot = null;
                c.notifyListeners();
                Navigator.pop(ctx);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//                    OBSERVAÇÕES
// ═══════════════════════════════════════════════════════════
class _NotesSection extends StatefulWidget {
  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  bool _editing = false;
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    final c = context.read<CheckoutController>();
    _controller = TextEditingController(text: c.orderNotes);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final hasNotes = c.orderNotes.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Observações',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
              
              if (!_editing && !hasNotes)
                TextButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          
          if (_editing || hasNotes) const SizedBox(height: 12),
          
          if (_editing)
            Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Favor buzinar ao chegar',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _controller.text = c.orderNotes;
                        setState(() => _editing = false);
                      },
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        c.orderNotes = _controller.text;
                        setState(() => _editing = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Salvar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else if (hasNotes)
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.orderNotes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _controller.text = c.orderNotes;
                    setState(() => _editing = true);
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Color(0xFF71717A),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

BoxDecoration _boxDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );