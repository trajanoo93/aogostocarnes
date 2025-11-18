// lib/screens/main_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/screens/cart/cart_drawer.dart';
import 'package:ao_gosto_app/screens/home/home_screen.dart';
import 'package:ao_gosto_app/screens/orders/orders_screen.dart';
import 'package:ao_gosto_app/widgets/custom_bottom_navigation.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_flow.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const Center(child: Text('Categorias - Em breve!', style: TextStyle(fontSize: 24))),
    const OrdersScreen(),
    const Center(child: Text('Perfil - Em breve!', style: TextStyle(fontSize: 24))),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingFlow.maybeStart(context);
    });
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      showCartDrawer(context);
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        _pages[_selectedIndex],
        Align(
          alignment: Alignment.bottomCenter,
          child: CustomBottomNavigation(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            cartItemCount: Provider.of<CartController>(context).totalItems,
          ),
        ),
      ],
    ),
    floatingActionButton: kDebugMode
        ? FloatingActionButton.small(
            onPressed: () => OnboardingFlow.maybeStart(context, force: true),
            child: const Icon(Icons.person_add),
          )
        : null,
  );
}}