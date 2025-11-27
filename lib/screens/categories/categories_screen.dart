// lib/screens/categories/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/categories/category_detail_screen.dart';
import 'package:ao_gosto_app/models/category_data.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _activeFilter = 'Todos 🔥';
  
  final List<String> _filters = [
    'Todos 🔥',
    'Churrasco 🥩',
    'Dia a Dia 🍽️',
    'Fitness 💪',
  ];

  List<CategoryData> get _filteredCategories {
    return CategoriesRepository.filterByTag(_activeFilter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // CONTEÚDO PRINCIPAL
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 160,
            ),
            child: _filteredCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sentiment_dissatisfied_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma categoria encontrada.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() => _activeFilter = 'Todos 🔥'),
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: [
                      _buildCategoriesGrid(),
                    ],
                  ),
          ),

          // HEADER FIXO
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // TÍTULO (SEM LUPA)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'O que vamos ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            TextSpan(
                              text: 'preparar? 🔥',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // FILTROS
                    Container(
                      height: 60,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isActive = _activeFilter == filter;
                          
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => _activeFilter = filter),
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.primary
                                        : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // LINHA DIVISÓRIA
                    Container(
                      height: 1,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = _filteredCategories;
    
    return Column(
      children: List.generate((categories.length / 2).ceil(), (rowIndex) {
        final startIndex = rowIndex * 2;
        final endIndex = (startIndex + 2).clamp(0, categories.length);
        final rowCategories = categories.sublist(startIndex, endIndex);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // PRIMEIRO CARD
              Expanded(
                child: _buildCategoryCard(
                  rowCategories[0],
                  startIndex,
                  // Varia altura: ímpar = alto, par = normal
                  rowIndex % 2 == 0 ? 220.0 : 180.0,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // SEGUNDO CARD (se existir)
              if (rowCategories.length > 1)
                Expanded(
                  child: _buildCategoryCard(
                    rowCategories[1],
                    startIndex + 1,
                    // Inverte: par = alto, ímpar = normal
                    rowIndex % 2 == 0 ? 180.0 : 220.0,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCategoryCard(CategoryData category, int index, double height) {
    final isLarge = height > 200;
    
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryDetailScreen(category: category),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagem
                  Image.network(
                    category.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                    ),
                  ),
                  
                  // Gradiente
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.75),
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                  
                  // Conteúdo
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Nome
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: isLarge ? 20 : 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            shadows: const [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        
                        // Descrição
                        Text(
                          category.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.3,
                          ),
                          maxLines: isLarge ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Seta
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}