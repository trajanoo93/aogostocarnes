// lib/screens/home/widgets/category_bubble.dart

import 'package:flutter/material.dart';

class CategoryBubble extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool active;
  final VoidCallback onTap;

  const CategoryBubble({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // 🔥 Bolha branca com sombra apenas quando ativa
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white, // sempre branco
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ]
                        : [], // sem sombra quando inativa
                  ),
                ),

                // 🔥 Ícone
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(imageUrl),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // 🔥 Borda animada quando ativo
                if (active)
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFA4815),
                        width: 4,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // 🔥 Nome da categoria
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: active ? Colors.black : const Color(0xFF6B7280),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
