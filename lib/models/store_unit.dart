// lib/models/store_unit.dart

class StoreUnit {
  final String name;
  final String address;
  final String phone;
  final String hours;
  final String imageUrl;
  final double lat;
  final double lng;
  double? distance; // Calculado dinamicamente

  StoreUnit({
    required this.name,
    required this.address,
    required this.phone,
    required this.hours,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    this.distance,
  });

  String get whatsappUrl => 'https://wa.me/55${phone.replaceAll(RegExp(r'\D'), '')}';
  
  String get mapsUrl => 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

  String get formattedDistance {
    if (distance == null) return '';
    if (distance! < 1000) {
      return '${distance!.toStringAsFixed(0)}m';
    }
    return '${(distance! / 1000).toStringAsFixed(1)}km';
  }
}

class StoresRepository {
  static final List<StoreUnit> units = [
    StoreUnit(
      name: 'Cidade Nova',
      address: 'Av. Cristiano Machado, 2312 - Cidade Nova, Belo Horizonte',
      phone: '(31) 9 8256-4794',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.8874714,
      lng: -43.9290403,
    ),
    StoreUnit(
      name: 'Barreiro',
      address: 'Av. Sinfrônio Brochado, 612 - Barreiro, Belo Horizonte',
      phone: '(31) 9 9534-8704',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.9763743,
      lng: -44.0184645,
    ),
    StoreUnit(
      name: 'Central de Delivery',
      address: 'Central de Delivery - Belo Horizonte',
      phone: '(31) 3461-3297',
      hours: 'Seg a Sex: Até 21h\nSáb: Até 21h\nDom: Até 17h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.9072211,
      lng: -43.9294909,
    ),
    StoreUnit(
      name: 'Silva Lobo',
      address: 'Av. Silva Lobo, 770 - Nova Suiça, Belo Horizonte',
      phone: '(31) 9 7201-4492',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.930014,
      lng: -43.972302,
    ),
    StoreUnit(
      name: 'Belvedere',
      address: 'Av. Luiz Paulo Franco, 961 - Belvedere, Belo Horizonte',
      phone: '(31) 9 7304-9750',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.9754216,
      lng: -43.943332,
    ),
    StoreUnit(
      name: 'Buritis',
      address: 'Av. Professor Mário Werneck, 1542 - Buritis, Belo Horizonte',
      phone: '(31) 9 9328-7517',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.9700819,
      lng: -43.9653186,
    ),
    StoreUnit(
      name: 'Mangabeiras',
      address: 'Av. dos Bandeirantes, 1600 - Mangabeiras, Belo Horizonte',
      phone: '(31) 9 8258-7179',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.9503454,
      lng: -43.9218962,
    ),
    StoreUnit(
      name: 'Prudente de Morais',
      address: 'Av. Prudente de Morais, 1159 - Santo Antônio, Belo Horizonte',
      phone: '(31) 9 7304-8792',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.9458992,
      lng: -43.949172,
    ),
    StoreUnit(
      name: 'Silviano Brandão',
      address: 'Av. Silviano Brandão, 825 - Floresta, Belo Horizonte',
      phone: '(31) 9 8256-4824',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.9080117,
      lng: -43.9286144,
    ),
    StoreUnit(
      name: 'Pampulha',
      address: 'Av. Otacílio Negrão de Lima, 6000 - Pampulha, Belo Horizonte',
      phone: '(31) 9 7304-9877',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.8467672,
      lng: -43.9751728,
    ),
    StoreUnit(
      name: 'Castelo',
      address: 'Av. dos Engenheiros, 1438 - Castelo, Belo Horizonte',
      phone: '(31) 9 9947-4595',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.8865154,
      lng: -44.0047992,
    ),
    StoreUnit(
      name: 'Eldorado',
      address: 'Av. João César de Oliveira, 1055 - Eldorado, Contagem',
      phone: '(31) 9 8257-4157',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.9431775,
      lng: -44.0381746,
    ),
    StoreUnit(
      name: 'Sion',
      address: 'R. Haiti, 354 - Sion, Belo Horizonte',
      phone: '(31) 3461-3297',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.9576175,
      lng: -43.940856,
    ),
    StoreUnit(
      name: 'Lagoa Santa',
      address: 'Av. Acdo. Nilo Figueiredo, 2303 - Bela Vista, Lagoa Santa - MG',
      phone: '(31) 9 7334-3479',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.643017314631035,
      lng: -43.90429593345364,
    ),
    StoreUnit(
      name: 'Ouro Preto',
      address: 'R. Conceição do Mato Dentro, 370 - Ouro Preto, BH',
      phone: '(31) 3461-3297',
      hours: 'Seg a Sex: 9h às 19h\nSáb: 9h às 18h\nDom: 9h às 14h',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800',
      lat: -19.87108193099367,
      lng: -43.97989437539252,
    ),
  ];
}