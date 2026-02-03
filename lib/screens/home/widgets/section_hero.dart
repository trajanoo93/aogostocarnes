// lib/screens/home/widgets/section_hero.dart

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SectionHero extends StatefulWidget {
  final List<String> banners;
  final double height;
  final String? title;
  final String? subtitle;
  final String? ctaText;
  final VoidCallback? onCTAPressed;

  const SectionHero({
    super.key,
    this.banners = const [
      'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/bannerApp1.jpg?q=80&w=1600&auto=format&fit=crop',
      
    ],
    this.height = 200,
    this.title,
    this.subtitle,
    this.ctaText,
    this.onCTAPressed,
  });

  @override
  State<SectionHero> createState() => _SectionHeroState();
}

class _SectionHeroState extends State<SectionHero> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(16);
    return Column(
      children: [
        ClipRRect(
          borderRadius: border,
          child: Stack(
            children: [
              SizedBox(
                height: widget.height,
                width: double.infinity,
                child: CarouselSlider.builder(
                  itemCount: widget.banners.length,
                  itemBuilder: (context, index, _) {
                    final url = widget.banners[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => Container(
                            color: Colors.black12,
                          ),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.error, color: Colors.white),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                        if (widget.title != null ||
                            widget.subtitle != null ||
                            widget.ctaText != null)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.title != null)
                                  Text(
                                    widget.title!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white70,
                                        ),
                                  ),
                                ],
                                if (widget.ctaText != null) ...[
                                  const SizedBox(height: 8),
                                  FilledButton(
                                    onPressed: widget.onCTAPressed,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(widget.ctaText!),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                  options: CarouselOptions(
                    height: widget.height,
                    viewportFraction: 1.0,
                    autoPlay: true,
                    enableInfiniteScroll: true,
                    onPageChanged: (index, _) =>
                        setState(() => _current = index),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.banners.length, (i) {
                    final isActive = i == _current;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
