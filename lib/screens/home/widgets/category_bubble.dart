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
        height: double.infinity, // ocupa toda a célula da lista
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end, // encosta embaixo
          children: [
            // altura fixa da “bolha”
            SizedBox(
              height: 80, // 🔹 antes ficava na casa dos 88+
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // bolha branca
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: 68,   // 🔹 menor
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: active
                          ? const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                  ),

                  // ícone
                  Container(
                    width: 60,   // 🔹 menor
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(imageUrl),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // borda ativa
                  if (active)
                    Container(
                      width: 76,  // 🔹 menor
                      height: 76,
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
            ),

            const SizedBox(height: 6),

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
