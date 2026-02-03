// lib/models/store_unit.dart

class StoreUnit {
  final String name;
  final String address;
  final String phone;
  final String hours;

  /// Ex: "prudente", "cidadenova", "ouropreto"
  final String imageSlug;

  /// Ex: "jpg" (padrão), "png"
  final String imageExt;

  final double lat;
  final double lng;

  /// Calculado dinamicamente (em metros)
  final double? distance;

  static const String _baseImageUrl = 'https://aogosto.com.br/unidades/uploads';

  const StoreUnit({
    required this.name,
    required this.address,
    required this.phone,
    required this.hours,
    required this.imageSlug,
    this.imageExt = 'jpg',
    required this.lat,
    required this.lng,
    this.distance,
  });

  /// URL final: https://aogosto.com.br/unidades/uploads/{slug}.{ext}
  String get imageUrl => '$_baseImageUrl/$imageSlug.$imageExt';

  String get whatsappUrl =>
      'https://wa.me/55${phone.replaceAll(RegExp(r'\D'), '')}';

  String get mapsUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

  String get formattedDistance {
    if (distance == null) return '';
    if (distance! < 1000) {
      return '${distance!.toStringAsFixed(0)}m';
    }
    return '${(distance! / 1000).toStringAsFixed(1)}km';
  }

  StoreUnit copyWith({
    String? name,
    String? address,
    String? phone,
    String? hours,
    String? imageSlug,
    String? imageExt,
    double? lat,
    double? lng,
    double? distance,
  }) {
    return StoreUnit(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      hours: hours ?? this.hours,
      imageSlug: imageSlug ?? this.imageSlug,
      imageExt: imageExt ?? this.imageExt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      distance: distance ?? this.distance,
    );
  }
}

class StoresRepository {
  static final List<StoreUnit> units = [
    const StoreUnit(
      name: 'Afonsos',
      imageSlug: 'afonsos',
      address:
          'Av. Nossa Sra. do Carmo, 1270 - São Pedro, Belo Horizonte - MG, 30330-000',
      phone: '(31) 3286-2807',
      hours:
          'Seg a Sex: 07:30 às 19:00\nSáb: 07:30 às 16:30\nDom: 07:30 às 12:30',
      lat: -19.949701366077793,
      lng: -43.936905175390464,
    ),
    const StoreUnit(
      name: 'Cidade Nova',
      imageSlug: 'cidadenova',
      address: 'Av. Cristiano Machado, 2312 - Cidade Nova, Belo Horizonte',
      phone: '(31) 9 8256-4794',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.8874714,
      lng: -43.9290403,
    ),
    const StoreUnit(
      name: 'Barreiro',
      imageSlug: 'barreiro',
      address: 'Av. Sinfrônio Brochado, 612 - Barreiro, Belo Horizonte',
      phone: '(31) 9 9534-8704',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.9763743,
      lng: -44.0184645,
    ),
    const StoreUnit(
      name: 'Central de Delivery',
      imageSlug: 'central',
      address: 'Central de Delivery - Belo Horizonte',
      phone: '(31) 2298-0807',
      hours: 'Seg a Sex: Até 21h\nSáb: Até 21h\nDom: Até 17h',
      lat: -19.9072211,
      lng: -43.9294909,
    ),
    const StoreUnit(
      name: 'Silva Lobo',
      imageSlug: 'silvalobo',
      address: 'Av. Silva Lobo, 770 - Nova Suíça, Belo Horizonte',
      phone: '(31) 9 7201-4492',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.930014,
      lng: -43.972302,
    ),
    const StoreUnit(
      name: 'Belvedere',
      imageSlug: 'belvedere',
      address: 'Av. Luiz Paulo Franco, 961 - Belvedere, Belo Horizonte',
      phone: '(31) 9 7304-9750',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.9754216,
      lng: -43.943332,
    ),
    const StoreUnit(
      name: 'Buritis',
      imageSlug: 'buritis',
      address: 'Av. Professor Mário Werneck, 1542 - Buritis, Belo Horizonte',
      phone: '(31) 9 9328-7517',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.9700819,
      lng: -43.9653186,
    ),
    const StoreUnit(
      name: 'Mangabeiras',
      imageSlug: 'mangabeiras',
      address: 'Av. dos Bandeirantes, 1600 - Mangabeiras, Belo Horizonte',
      phone: '(31) 9 8258-7179',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.9503454,
      lng: -43.9218962,
    ),
    const StoreUnit(
      name: 'Prudente de Morais',
      imageSlug: 'prudente',
      address: 'Av. Prudente de Morais, 1159 - Santo Antônio, Belo Horizonte',
      phone: '(31) 9 7304-8792',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.9458992,
      lng: -43.949172,
    ),
    const StoreUnit(
      name: 'Silviano Brandão',
      imageSlug: 'silviano',
      address: 'Av. Silviano Brandão, 825 - Floresta, Belo Horizonte',
      phone: '(31) 9 8256-4824',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.9080117,
      lng: -43.9286144,
    ),
    const StoreUnit(
      name: 'Pampulha',
      imageSlug: 'pampulha',
      address: 'Av. Otacílio Negrão de Lima, 6000 - Pampulha, Belo Horizonte',
      phone: '(31) 9 7304-9877',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.8467672,
      lng: -43.9751728,
    ),
    const StoreUnit(
      name: 'Castelo',
      imageSlug: 'castelo',
      address: 'Av. dos Engenheiros, 1438 - Castelo, Belo Horizonte',
      phone: '(31) 9 9947-4595',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.8865154,
      lng: -44.0047992,
    ),
    const StoreUnit(
      name: 'Eldorado',
      imageSlug: 'eldorado',
      address: 'Av. João César de Oliveira, 1055 - Eldorado, Contagem',
      phone: '(31) 9 8257-4157',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.9431775,
      lng: -44.0381746,
    ),
    const StoreUnit(
      name: 'Sion',
      imageSlug: 'sion', // <- agora é sion.jpg
      address: 'R. Haiti, 354 - Sion, Belo Horizonte',
      phone: '(31) 2298-0807',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.9576175,
      lng: -43.940856,
    ),
    const StoreUnit(
      name: 'Lagoa Santa',
      imageSlug: 'lagoasanta',
      address: 'Av. Acdo. Nilo Figueiredo, 2303 - Bela Vista, Lagoa Santa - MG',
      phone: '(31) 9 7334-3479',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.643017314631035,
      lng: -43.90429593345364,
    ),
    const StoreUnit(
      name: 'Ouro Preto',
      imageSlug: 'ouropreto',
      address: 'R. Conceição do Mato Dentro, 370 - Ouro Preto, BH',
      phone: '(31) 2298-0807',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      lat: -19.87108193099367,
      lng: -43.97989437539252,
    ),
  ];
}
