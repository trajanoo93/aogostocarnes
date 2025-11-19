// lib/screens/home/widgets/section_hero.dart

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

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
      'https://images.unsplash.com/photo-1553163147-622ab57be1c7?q=80&w=1600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=1600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1558030006-450675393462?q=80&w=1600&auto=format&fit=crop',
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
                        Image.network(url, fit: BoxFit.cover),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                        if (widget.title != null || widget.subtitle != null || widget.ctaText != null)
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
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white70,
                                        ),
                                  ),
                                ],
                                if (widget.ctaText != null) ...[
                                  const SizedBox(height: 8),
                                  FilledButton(
                                    onPressed: widget.onCTAPressed,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
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
                    onPageChanged: (index, _) => setState(() => _current = index),
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
