// lib/widgets/cached_image.dart - IMAGENS OTIMIZADAS

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget otimizado para imagens de produtos
/// Usa cache automático e placeholder suave
class CachedProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CachedProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final widget = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      
      // ✨ Placeholder suave enquanto carrega
      placeholder: (context, url) => Container(
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
      
      // ✨ Erro com ícone elegante
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFF3F4F6),
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: Color(0xFF9CA3AF),
        ),
      ),
      
      // ✨ Fade suave ao carregar
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      
      // ✨ Cache por 7 dias
      memCacheWidth: 400, // Reduz uso de memória
      memCacheHeight: 400,
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: widget,
      );
    }

    return widget;
  }
}

/// Widget para imagens pequenas (thumbnails)
/// Ainda mais otimizado para listas
class CachedThumbnail extends StatelessWidget {
  final String imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const CachedThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 80,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return CachedProductImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }
}

/// Widget para hero images (tela de detalhes)
/// Carrega em alta qualidade
class CachedHeroImage extends StatelessWidget {
  final String imageUrl;
  final double height;

  const CachedHeroImage({
    super.key,
    required this.imageUrl,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      
      placeholder: (context, url) => Container(
        height: height,
        color: const Color(0xFFF3F4F6),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      
      errorWidget: (context, url, error) => Container(
        height: height,
        color: const Color(0xFFF3F4F6),
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Color(0xFF9CA3AF),
        ),
      ),
      
      fadeInDuration: const Duration(milliseconds: 500),
      
      // ✨ Sem limitar resolução (imagem grande)
    );
  }
}