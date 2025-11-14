// screens/main_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/screens/cart/cart_drawer.dart';
import 'package:ao_gosto_app/screens/home/home_screen.dart';
import 'package:ao_gosto_app/screens/orders/orders_screen.dart'; // ADICIONADO
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_flow.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // PÁGINAS ATUALIZADAS
  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const Center(child: Text('Categorias')),
    const OrdersScreen(), // NAVEGAÇÃO FUNCIONAL
  ];

  @override
  void initState() {
    super.initState();

    // Onboarding automático
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingFlow.maybeStart(context);
    });
  }

  void _onTap(int i) async {
    if (i == 3) {
      await showCartDrawer(context);
      return;
    }
    setState(() => _selectedIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppColors.primary;
    const unselectedColor = Color(0xFF6B7280);

    return Scaffold(
      body: _pages.elementAt(_selectedIndex),

      // FAB de debug
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              heroTag: 'fab-onboarding',
              backgroundColor: Colors.black.withOpacity(0.6),
              foregroundColor: Colors.white,
              tooltip: 'Testar Onboarding',
              onPressed: () => OnboardingFlow.maybeStart(context, force: true),
              child: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            )
          : null,

      bottomNavigationBar: AnimatedBuilder(
        animation: CartController.instance,
        builder: (context, _) {
          final badge = CartController.instance.totalItems;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFD1D5DB), width: 0.6),
              ),
              boxShadow: [
                BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                currentIndex: _selectedIndex,
                onTap: _onTap,
                selectedItemColor: selectedColor,
                unselectedItemColor: unselectedColor,
                selectedIconTheme: const IconThemeData(size: 26),
                unselectedIconTheme: const IconThemeData(size: 24),
                showUnselectedLabels: true,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Início',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_rounded),
                    activeIcon: Icon(Icons.grid_view),
                    label: 'Categorias',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long_outlined),
                    activeIcon: Icon(Icons.receipt_long),
                    label: 'Pedidos',
                  ),
                  BottomNavigationBarItem(
                    label: 'Carrinho',
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_bag_outlined),
                        if (badge > 0)
                          Positioned(
                            right: -8,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              constraints: const BoxConstraints(minWidth: 18),
                              child: Text(
                                '$badge',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}