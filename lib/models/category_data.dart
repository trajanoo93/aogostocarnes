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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/pexels-cristian-rojas-8477228.jpg?q=80&w=1000',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/istockphoto-1299827873-1024x1024-1.jpg?q=80&w=800',
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
      id: 33,
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/pexels-shliftik-7333266-1.jpg?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/pexels-leeloothefirst-5769383.jpg?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/pexels-chevanon-323682.jpg?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/pexels-electra-studio-32883186-30648983.jpg?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/pexels-mateusz-dach-99805-1275692.jpg?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/capa-materia-gshow-2022-01-10t140336.156.avif?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/top-view-delicious-kebab-slate-with-salad-ketchup_11zon-2048x1365-1.webp?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/pexels-abhishek-mahajan-2249012-3928854.jpg?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/hamburguer.webp?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/massasepratosprontos.png?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/complementos.avif?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/linhadiaadia.jpg?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/forno.webp?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/categoria-airfyer.jpg?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/bebidas.jpg?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/acessorios.webp?q=80&w=800',
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
      imageUrl: 'https://aogosto.com.br/delivery/wp-content/uploads/2025/11/outros.jpg?q=80&w=800',
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