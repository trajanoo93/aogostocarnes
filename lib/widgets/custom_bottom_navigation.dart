// lib/widgets/custom_bottom_navigation.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';

class CustomBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation> {
  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartController>().totalItems; // ← CORRIGIDO!

    return Stack(
      children: [
        // Barra principal com efeito glass
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // ← CORRIGIDO!
              child: Container(
                color: Colors.white.withOpacity(0.92),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavItem(icon: Icons.home_rounded, label: 'Início', index: 0),
                        _buildNavItem(icon: Icons.grid_view_rounded, label: 'Categorias', index: 1),
                        const SizedBox(width: 80),
                        _buildNavItem(icon: Icons.receipt_long_rounded, label: 'Pedidos', index: 2),
                        _buildNavItem(icon: Icons.person_rounded, label: 'Conta', index: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Botão flutuante do carrinho
        Positioned(
          bottom: 20,
          left: MediaQuery.of(context).size.width / 2 - 36,
          child: GestureDetector(
            onTap: () => widget.onTap(4),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6F3C), Color(0xFFFA4815)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFA4815).withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 5),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 36),
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFA4815),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        child: Center(
                          child: Text(
                            cartItemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = widget.currentIndex == index;
    final color = isActive ? const Color(0xFFFA4815) : Colors.grey.shade500;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}