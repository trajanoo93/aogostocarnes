// lib/screens/main_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/screens/cart/cart_drawer.dart';
import 'package:ao_gosto_app/screens/home/home_screen.dart';
import 'package:ao_gosto_app/screens/orders/orders_screen.dart';
import 'package:ao_gosto_app/widgets/custom_bottom_navigation.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_flow.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // PÁGINAS — 4 telas (índice 4 é o botão do carrinho que abre o drawer)
  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const Center(
      child: Text(
        'Categorias',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ), // Placeholder temporário
    const OrdersScreen(),
    const Center(
      child: Text(
        'Perfil',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ), // Futuro
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingFlow.maybeStart(context);
    });
  }

  void _onItemTapped(int index) async {
    if (index == 4) {
      // Botão flutuante do carrinho → abre o drawer
      await showCartDrawer(context);
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      // FAB de debug (onboarding)
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

      // NOVO RODAPÉ MODERNO COM BADGE FUNCIONANDO!
      bottomNavigationBar: Consumer<CartController>(
        builder: (context, cart, child) {
          return CustomBottomNavigation(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          );
        },
      ),
    );
  }
}