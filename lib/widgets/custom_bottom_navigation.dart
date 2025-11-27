// lib/widgets/custom_bottom_navigation.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int cartItemCount;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.cartItemCount,
  }) : super(key: key);

  static const Map<int, IconData> _icons = {
    0: Icons.home_outlined,
    1: Icons.grid_view_outlined,
    2: Icons.assignment_turned_in_outlined,
    3: Icons.person_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // BARRA COM BLUR
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade200,
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNavItem(index: 0, label: "Início"),
                            _buildNavItem(index: 1, label: "Categorias"),
                            const SizedBox(width: 70),
                            _buildNavItem(index: 2, label: "Pedidos"),
                            _buildNavItem(index: 3, label: "Conta"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // BOTÃO CENTRAL (CESTA)
              Positioned(
                top: -10,
                left: MediaQuery.of(context).size.width / 2 - 34,
                child: GestureDetector(
                  onTap: () => onTap(4),
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6F3C), Color(0xFFFA4815)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFA4815).withOpacity(0.45),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),

                          // Badge
                          if (cartItemCount > 0)
                            Positioned(
                              top: -1,
                              right: -1,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFA4815),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 26,
                                  minHeight: 26,
                                ),
                                child: Center(
                                  child: Text(
                                    cartItemCount > 99 ? '99+' : '$cartItemCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
  }) {
    final bool isActive = currentIndex == index;
    final Color color = isActive
        ? const Color(0xFFFA4815)
        : Colors.grey.shade500;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[index]!,
              size: 26,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}