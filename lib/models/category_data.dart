// lib/models/category_data.dart

class CategoryData {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> tags; // Para filtros: Churrasco, Dia a Dia, etc
  final List<SubcategoryData> subcategories;

  const CategoryData({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.tags,
    this.subcategories = const [],
  });
}

class SubcategoryData {
  final int id;
  final String name;

  const SubcategoryData({
    required this.id,
    required this.name,
  });
}

// ====== DADOS REAIS DAS CATEGORIAS ======

class CategoriesRepository {
  static const List<CategoryData> categories = [
    // 1. BOVINOS
    CategoryData(
      id: 34,
      name: 'Bovinos',
      description: 'O rei do churrasco. Cortes nobres e tradicionais.',
      imageUrl: 'https://images.unsplash.com/photo-1600891964092-4316c288032e?q=80&w=1000',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 34, name: 'Todos'),
        SubcategoryData(id: 249, name: 'Acém'),
        SubcategoryData(id: 241, name: 'Ancho'),
        SubcategoryData(id: 246, name: 'Angus'),
        SubcategoryData(id: 242, name: 'Chorizo'),
        SubcategoryData(id: 247, name: 'Maminha'),
        SubcategoryData(id: 244, name: 'Cortes Gourmet'),
        SubcategoryData(id: 248, name: 'Cortes Magros'),
        SubcategoryData(id: 245, name: 'Costela'),
      ],
    ),

    // 2. KITS PRONTOS
    CategoryData(
      id: 71,
      name: 'Kits Prontos',
      description: 'Tudo pronto para seu evento.',
      imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 71, name: 'Todos'),
        SubcategoryData(id: 357, name: 'Até 5'),
        SubcategoryData(id: 358, name: 'Até 10'),
        SubcategoryData(id: 359, name: 'Até 15'),
        SubcategoryData(id: 360, name: 'Até 20'),
      ],
    ),

    // 3. PICANHAS
    CategoryData(
      id: 32,
      name: 'Picanhas',
      description: 'A estrela do churrasco brasileiro.',
      imageUrl: 'https://images.unsplash.com/photo-1558030006-450675393462?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 32, name: 'Todos'),
      ],
    ),

    // 4. PORCO
    CategoryData(
      id: 44,
      name: 'Porco',
      description: 'Sabor e suculência garantidos.',
      imageUrl: 'https://images.unsplash.com/photo-1603360436449-dc6b4a25b41f?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 44, name: 'Todos'),
      ],
    ),

    // 5. FRANGO
    CategoryData(
      id: 32,
      name: 'Frango',
      description: 'Leveza e versatilidade.',
      imageUrl: 'https://images.unsplash.com/photo-1587593810167-a84920ea0781?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 32, name: 'Todos'),
      ],
    ),

    // 6. EXÓTICOS
    CategoryData(
      id: 55,
      name: 'Exóticos',
      description: 'Sabores únicos e especiais.',
      imageUrl: 'https://images.unsplash.com/photo-1606850780554-b55ea684fe84?q=80&w=800',
      tags: ['Churrasco', 'Premium'],
      subcategories: [
        SubcategoryData(id: 55, name: 'Todos'),
      ],
    ),

    // 7. PESCADOS
    CategoryData(
      id: 63,
      name: 'Pescados',
      description: 'Frescor do mar para sua mesa.',
      imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 63, name: 'Todos'),
      ],
    ),

    // 8. LINGUIÇAS
    CategoryData(
      id: 51,
      name: 'Linguiças',
      description: 'O toque especial do churrasco.',
      imageUrl: 'https://images.unsplash.com/photo-1629998270465-0b5a6f344022?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 51, name: 'Todos'),
        SubcategoryData(id: 243, name: 'Linguiça Bovina'),
        SubcategoryData(id: 264, name: 'Linguiça Suína'),
      ],
    ),

    // 9. PÃO DE ALHO
    CategoryData(
      id: 73,
      name: 'Pão de Alho',
      description: 'O clássico acompanhamento.',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 73, name: 'Todos'),
      ],
    ),

    // 10. ESPETINHOS GOURMET
    CategoryData(
      id: 59,
      name: 'Espetinhos Gourmet',
      description: 'Praticidade na grelha.',
      imageUrl: 'https://images.unsplash.com/photo-1529042410759-befb1204b468?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 59, name: 'Todos'),
      ],
    ),

    // 11. QUEIJOS
    CategoryData(
      id: 252,
      name: 'Queijos',
      description: 'Perfeitos para grelhar.',
      imageUrl: 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 252, name: 'Todos'),
      ],
    ),

    // 12. HAMBÚRGUERES
    CategoryData(
      id: 390,
      name: 'Hambúrgueres',
      description: 'Suculentos e saborosos.',
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 390, name: 'Todos'),
      ],
    ),

    // 13. MASSAS E PRATOS PRONTOS
    CategoryData(
      id: 8,
      name: 'Massas e Pratos Prontos',
      description: 'Sabor de casa, pronto para você.',
      imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?q=80&w=800',
      tags: ['Dia a Dia'],
      subcategories: [
        SubcategoryData(id: 8, name: 'Todos'),
        SubcategoryData(id: 175, name: 'Massas'),
        SubcategoryData(id: 70, name: 'Massas e Tortas'),
        SubcategoryData(id: 172, name: 'Pratos Prontos'),
      ],
    ),

    // 14. COMPLEMENTOS
    CategoryData(
      id: 377,
      name: 'Complementos',
      description: 'O toque final perfeito.',
      imageUrl: 'https://images.unsplash.com/photo-1625937751876-4515cd8e7706?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 377, name: 'Todos'),
        SubcategoryData(id: 66, name: 'Complementos'),
        SubcategoryData(id: 186, name: 'Molhos'),
        SubcategoryData(id: 68, name: 'Temperos'),
      ],
    ),

    // 15. LINHA DIA A DIA
    CategoryData(
      id: 342,
      name: 'Linha Dia a Dia',
      description: 'Praticidade para o seu dia.',
      imageUrl: 'https://images.unsplash.com/photo-1504387432042-8aca549e4911?q=80&w=800',
      tags: ['Dia a Dia', 'Fitness'],
      subcategories: [
        SubcategoryData(id: 342, name: 'Todos'),
      ],
    ),

    // 16. FORNO
    CategoryData(
      id: 53,
      name: 'Forno',
      description: 'Assados deliciosos.',
      imageUrl: 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?q=80&w=800',
      tags: ['Dia a Dia'],
      subcategories: [
        SubcategoryData(id: 53, name: 'Todos'),
      ],
    ),

    // 17. AIR FRYER
    CategoryData(
      id: 350,
      name: 'Air Fryer',
      description: 'Crocância saudável.',
      imageUrl: 'https://images.unsplash.com/photo-1607532941433-304659e8198a?q=80&w=800',
      tags: ['Dia a Dia'],
      subcategories: [
        SubcategoryData(id: 350, name: 'Todos'),
      ],
    ),

    // 18. BEBIDAS
    CategoryData(
      id: 69,
      name: 'Bebidas',
      description: 'Para acompanhar.',
      imageUrl: 'https://images.unsplash.com/photo-1437418747212-8d9709afab22?q=80&w=800',
      tags: ['Churrasco', 'Dia a Dia'],
      subcategories: [
        SubcategoryData(id: 69, name: 'Todos'),
      ],
    ),

    // 19. BOUTIQUE
    CategoryData(
      id: 12,
      name: 'Boutique',
      description: 'Seleção premium especial.',
      imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=800',
      tags: ['Churrasco', 'Premium'],
      subcategories: [
        SubcategoryData(id: 12, name: 'Todos'),
      ],
    ),

    // 20. OUTROS
    CategoryData(
      id: 62,
      name: 'Outros',
      description: 'Variedades especiais.',
      imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?q=80&w=800',
      tags: ['Churrasco'],
      subcategories: [
        SubcategoryData(id: 62, name: 'Todos'),
      ],
    ),
  ];

  // Filtrar por tag
  static List<CategoryData> filterByTag(String tag) {
    if (tag == 'Todos' || tag == 'Todos 🔥') return categories;
    
    // Remove emoji e trim
    final cleanTag = tag.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    return categories.where((cat) => cat.tags.contains(cleanTag)).toList();
  }
}