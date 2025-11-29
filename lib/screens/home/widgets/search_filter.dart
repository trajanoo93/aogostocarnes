// lib/screens/home/widgets/search_filter.dart
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/screens/home/widgets/search_modal.dart';

class SearchFilter extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchFilter({
    super.key,
    this.onChanged,
    this.onSubmitted,
  });

  void _openSearchModal(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const SearchModal();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSearchModal(context),
      child: Container(
        height: 56,
       decoration: BoxDecoration(
  color: Colors.white, // ← aqui fica 100% branco
  borderRadius: BorderRadius.circular(999),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
),

        child: AbsorbPointer(
          child: TextField(
            enabled: false,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'O que você está procurando hoje?',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFFFA4815), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}