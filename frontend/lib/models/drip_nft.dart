enum DripRarity { common, rare, epic, legendary }

class DripNFT {
  final String id;
  final String name;
  final DripRarity rarity;
  final String imageUrl;
  final bool isNew;

  DripNFT({
    required this.id,
    required this.name,
    required this.rarity,
    required this.imageUrl,
    this.isNew = false,
  });

  factory DripNFT.fromJson(Map<String, dynamic> json) {
    return DripNFT(
      id: json['id'] as String,
      name: json['name'] as String,
      rarity: DripRarity.values.firstWhere(
        (e) => e.name == (json['rarity'] as String).toLowerCase(),
      ),
      imageUrl: json['imageUrl'] as String,
      isNew: json['isNew'] ?? false,
    );
  }
}
