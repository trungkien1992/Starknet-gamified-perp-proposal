import 'package:flutter/material.dart';

enum TerritoryDistrict {
  central,
  tsimShaTsui,
  wanChai,
  causewyBay,
}

enum TerritoryStatus {
  locked,
  inProgress,
  conquered,
  legendary, // Multiple conquests
}

class Territory {
  final String id;
  final TerritoryDistrict district;
  final String name;
  final String description;
  final int requiredTrades;
  final int completedTrades;
  final TerritoryStatus status;
  final List<ArtPiece> artPieces;
  final Color themeColor;
  final String ownerId;
  final DateTime? conqueredAt;
  final int prestige; // Higher = more valuable territory

  Territory({
    required this.id,
    required this.district,
    required this.name,
    required this.description,
    required this.requiredTrades,
    this.completedTrades = 0,
    this.status = TerritoryStatus.locked,
    this.artPieces = const [],
    required this.themeColor,
    this.ownerId = '',
    this.conqueredAt,
    required this.prestige,
  });

  double get completionPercentage => 
      requiredTrades > 0 ? (completedTrades / requiredTrades).clamp(0.0, 1.0) : 0.0;

  bool get isConquered => status == TerritoryStatus.conquered || status == TerritoryStatus.legendary;
  
  bool get canTrade => status != TerritoryStatus.locked;

  Territory copyWith({
    String? id,
    TerritoryDistrict? district,
    String? name,
    String? description,
    int? requiredTrades,
    int? completedTrades,
    TerritoryStatus? status,
    List<ArtPiece>? artPieces,
    Color? themeColor,
    String? ownerId,
    DateTime? conqueredAt,
    int? prestige,
  }) {
    return Territory(
      id: id ?? this.id,
      district: district ?? this.district,
      name: name ?? this.name,
      description: description ?? this.description,
      requiredTrades: requiredTrades ?? this.requiredTrades,
      completedTrades: completedTrades ?? this.completedTrades,
      status: status ?? this.status,
      artPieces: artPieces ?? this.artPieces,
      themeColor: themeColor ?? this.themeColor,
      ownerId: ownerId ?? this.ownerId,
      conqueredAt: conqueredAt ?? this.conqueredAt,
      prestige: prestige ?? this.prestige,
    );
  }
}

class ArtPiece {
  final String id;
  final String name;
  final ArtPieceType type;
  final double progress; // 0.0 to 1.0
  final bool isCompleted;
  final Color color;

  ArtPiece({
    required this.id,
    required this.name,
    required this.type,
    this.progress = 0.0,
    this.isCompleted = false,
    required this.color,
  });

  ArtPiece copyWith({
    String? id,
    String? name,
    ArtPieceType? type,
    double? progress,
    bool? isCompleted,
    Color? color,
  }) {
    return ArtPiece(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      color: color ?? this.color,
    );
  }
}

enum ArtPieceType {
  background,
  character,
  details,
  effects,
}

class TerritoryData {
  static List<Territory> getHongKongTerritories() {
    return [
      Territory(
        id: 'central_ifc',
        district: TerritoryDistrict.central,
        name: 'IFC Tower Plaza',
        description: 'The crown jewel of Central. Conquer this for ultimate prestige.',
        requiredTrades: 100,
        themeColor: const Color(0xFFDC143C),
        prestige: 100,
        artPieces: [
          ArtPiece(id: 'ifc_bg', name: 'Tower Silhouette', type: ArtPieceType.background, color: Colors.grey),
          ArtPiece(id: 'ifc_char', name: 'Neon Dragon', type: ArtPieceType.character, color: Colors.red),
          ArtPiece(id: 'ifc_details', name: 'Financial Symbols', type: ArtPieceType.details, color: Colors.amber),
          ArtPiece(id: 'ifc_fx', name: 'Rain Reflections', type: ArtPieceType.effects, color: Colors.cyan),
        ],
      ),
      Territory(
        id: 'central_bank',
        district: TerritoryDistrict.central,
        name: 'Bank of China Wall',
        description: 'Geometric street art on Hong Kong\'s most iconic tower.',
        requiredTrades: 75,
        themeColor: const Color(0xFF4169E1),
        prestige: 85,
        artPieces: [
          ArtPiece(id: 'boc_bg', name: 'Triangular Patterns', type: ArtPieceType.background, color: Colors.blue),
          ArtPiece(id: 'boc_char', name: 'Abstract Phoenix', type: ArtPieceType.character, color: Colors.orange),
          ArtPiece(id: 'boc_details', name: 'Market Charts', type: ArtPieceType.details, color: Colors.green),
        ],
      ),
      Territory(
        id: 'tsim_sha_tsui_promenade',
        district: TerritoryDistrict.tsimShaTsui,
        name: 'Tsim Sha Tsui Promenade',
        description: 'Tourist hotspot with vibrant harbor views.',
        requiredTrades: 50,
        status: TerritoryStatus.inProgress,
        themeColor: const Color(0xFFFF1493),
        prestige: 70,
        artPieces: [
          ArtPiece(id: 'tst_bg', name: 'Harbor Skyline', type: ArtPieceType.background, color: Colors.purple),
          ArtPiece(id: 'tst_char', name: 'Light Show Dancer', type: ArtPieceType.character, color: Colors.pink),
        ],
      ),
      Territory(
        id: 'wan_chai_street',
        district: TerritoryDistrict.wanChai,
        name: 'Wan Chai Underground',
        description: 'Gritty underground scene for real street artists.',
        requiredTrades: 60,
        status: TerritoryStatus.inProgress,
        themeColor: const Color(0xFF228B22),
        prestige: 75,
        artPieces: [
          ArtPiece(id: 'wc_bg', name: 'Alley Walls', type: ArtPieceType.background, color: Colors.grey[800]!),
          ArtPiece(id: 'wc_char', name: 'Rebel Warrior', type: ArtPieceType.character, color: Colors.green),
          ArtPiece(id: 'wc_details', name: 'Political Messages', type: ArtPieceType.details, color: Colors.yellow),
        ],
      ),
      Territory(
        id: 'causeway_bay_plaza',
        district: TerritoryDistrict.causewyBay,
        name: 'Causeway Bay Plaza',
        description: 'Pop art paradise in the shopping district.',
        requiredTrades: 40,
        status: TerritoryStatus.inProgress,
        themeColor: const Color(0xFFFF6347),
        prestige: 60,
        artPieces: [
          ArtPiece(id: 'cb_bg', name: 'Shopping Mall', type: ArtPieceType.background, color: Colors.white),
          ArtPiece(id: 'cb_char', name: 'Fashion Icon', type: ArtPieceType.character, color: Colors.pink),
          ArtPiece(id: 'cb_details', name: 'Brand Logos', type: ArtPieceType.details, color: Colors.orange),
        ],
      ),
    ];
  }
}

class TerritoryConquest {
  final String territoryId;
  final String userId;
  final DateTime conqueredAt;
  final int tradesCompleted;
  final Duration timeToComplete;

  TerritoryConquest({
    required this.territoryId,
    required this.userId,
    required this.conqueredAt,
    required this.tradesCompleted,
    required this.timeToComplete,
  });
}