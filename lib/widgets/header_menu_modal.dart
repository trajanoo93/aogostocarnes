// lib/widgets/header_menu_modal.dart - VERSÃO COMPLETA COM WHATSAPP DINÂMICO
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/unidades/unidades_screen.dart';
import 'package:ao_gosto_app/state/navigation_controller.dart';
import 'package:ao_gosto_app/services/remote_config_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HeaderMenuModal extends StatefulWidget {
  const HeaderMenuModal({super.key});

  @override
  State<HeaderMenuModal> createState() => _HeaderMenuModalState();
}

class _HeaderMenuModalState extends State<HeaderMenuModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _userName = 'Usuário';
  double _cashbackBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('customer_name') ?? 'Usuário';
        _cashbackBalance = prefs.getDouble('cashback_balance') ?? 0.0;
      });
    } catch (e) {
      // Fallback
    }
  }

  Future<void> _launchWhatsApp() async {
    try {
      final config = await RemoteConfigService.fetchConfig();
      final uri = Uri.parse(config.getWhatsAppUrl('Olá! Gostaria de falar com vocês.'));
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Fallback
      final uri = Uri.parse('https://wa.me/5531997682271');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // HEADER LARANJA COM PERFIL
              _buildHeader(),

              // MENU ITEMS
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Meu Perfil',
                        onTap: () {
                          Navigator.pop(context);
                          NavigationController.changeTab?.call(3);
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Fale no WhatsApp',
                        iconColor: const Color(0xFF25D366),
                        onTap: _launchWhatsApp,
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Divider(height: 1),
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.wallet_outlined,
                        title: 'Cashback',
                        subtitle: 'Em breve!',
                        isComingSoon: true,
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.whatshot_outlined,
                        title: 'Churrascômetro',
                        subtitle: 'Em breve!',
                        isComingSoon: true,
                        onTap: () {},
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.store_outlined,
                        title: 'Nossas Unidades',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UnidadesScreen(),
                            ),
                          );
                        },
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Divider(height: 1),
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.bug_report_outlined,
                        title: 'Relatar Problema',
                        iconColor: Colors.red[400],
                        onTap: () {
                          Navigator.pop(context);
                          _showReportDialog();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // FOOTER COM LOGO
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Olá,👋',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wallet_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cashback disponível',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'R\$ ${_cashbackBalance.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    bool isComingSoon = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isComingSoon ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isComingSoon
                      ? Colors.grey[100]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isComingSoon
                        ? Colors.grey[300]!
                        : (iconColor ?? AppColors.primary).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isComingSoon
                      ? Colors.grey[400]
                      : (iconColor ?? AppColors.primary),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isComingSoon
                            ? Colors.grey[600]
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isComingSoon)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              if (isComingSoon)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Em breve',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Image.asset(
          'assets/icon/app_icon.png',
          height: 30,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Relatar Problema',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Entre em contato conosco pelo WhatsApp para relatar qualquer problema!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchWhatsApp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abrir WhatsApp'),
          ),
        ],
      ),
    );
  }
}