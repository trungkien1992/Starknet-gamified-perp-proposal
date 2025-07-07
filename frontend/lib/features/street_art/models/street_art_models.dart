import 'package:flutter/material.dart';

enum SprayTool {
  basic,
  pro,
  legendary;

  String get displayName {
    switch (this) {
      case SprayTool.basic:
        return 'Basic Can';
      case SprayTool.pro:
        return 'Pro Marker';
      case SprayTool.legendary:
        return 'Legendary Airbrush';
    }
  }

  Color get toolColor {
    switch (this) {
      case SprayTool.basic:
        return Colors.grey[400]!;
      case SprayTool.pro:
        return const Color(0xFF00FFFF);
      case SprayTool.legendary:
        return const Color(0xFFFF0080);
    }
  }

  double get inkCostMultiplier {
    switch (this) {
      case SprayTool.basic:
        return 1.0;
      case SprayTool.pro:
        return 0.8;
      case SprayTool.legendary:
        return 0.6;
    }
  }
}

enum ArtStyle {
  tag,
  piece,
  wildstyle,
  threedimensional;

  String get displayName {
    switch (this) {
      case ArtStyle.tag:
        return 'Tag';
      case ArtStyle.piece:
        return 'Piece';
      case ArtStyle.wildstyle:
        return 'Wildstyle';
      case ArtStyle.threedimensional:
        return '3D';
    }
  }

  Duration get creationTime {
    switch (this) {
      case ArtStyle.tag:
        return const Duration(seconds: 5);
      case ArtStyle.piece:
        return const Duration(seconds: 15);
      case ArtStyle.wildstyle:
        return const Duration(seconds: 30);
      case ArtStyle.threedimensional:
        return const Duration(seconds: 45);
    }
  }

  int get baseXpReward {
    switch (this) {
      case ArtStyle.tag:
        return 50;
      case ArtStyle.piece:
        return 150;
      case ArtStyle.wildstyle:
        return 300;
      case ArtStyle.threedimensional:
        return 500;
    }
  }
}

class StreetArtPiece {
  final String id;
  final ArtStyle style;
  final SprayTool tool;
  final String location;
  final DateTime createdAt;
  final double leverageUsed;
  final double pnlResult;
  final bool isSuccessful;
  final String? imageUrl;

  const StreetArtPiece({
    required this.id,
    required this.style,
    required this.tool,
    required this.location,
    required this.createdAt,
    required this.leverageUsed,
    required this.pnlResult,
    required this.isSuccessful,
    this.imageUrl,
  });

  int get xpReward => (style.baseXpReward * leverageUsed).round();
}

class PolicePatrol {
  final String id;
  final String district;
  final DateTime startTime;
  final Duration duration;
  final double intensity; // 0.0 to 1.0

  const PolicePatrol({
    required this.id,
    required this.district,
    required this.startTime,
    required this.duration,
    required this.intensity,
  });

  bool get isActive => 
    DateTime.now().isAfter(startTime) && 
    DateTime.now().isBefore(startTime.add(duration));

  double get riskMultiplier => 1.0 + (intensity * 2.0);
}

class RivalCrew {
  final String name;
  final String territory;
  final double strength;
  final bool isHostile;

  const RivalCrew({
    required this.name,
    required this.territory,
    required this.strength,
    required this.isHostile,
  });
}

enum HongKongDistrict {
  centralHK,
  mongKok,
  causeWayBay,
  tsimshatSui,
  wanChai,
  saiwan;

  String get displayName {
    switch (this) {
      case HongKongDistrict.centralHK:
        return 'Central HK';
      case HongKongDistrict.mongKok:
        return 'Mong Kok';
      case HongKongDistrict.causeWayBay:
        return 'Causeway Bay';
      case HongKongDistrict.tsimshatSui:
        return 'Tsim Sha Tsui';
      case HongKongDistrict.wanChai:
        return 'Wan Chai';
      case HongKongDistrict.saiwan:
        return 'Sai Wan';
    }
  }

  Color get districtColor {
    switch (this) {
      case HongKongDistrict.centralHK:
        return const Color(0xFFDC143C);
      case HongKongDistrict.mongKok:
        return const Color(0xFFFF6B35);
      case HongKongDistrict.causeWayBay:
        return const Color(0xFF7DF9FF);
      case HongKongDistrict.tsimshatSui:
        return const Color(0xFF8A2BE2);
      case HongKongDistrict.wanChai:
        return const Color(0xFF00FF41);
      case HongKongDistrict.saiwan:
        return const Color(0xFFFFFF00);
    }
  }

  double get riskLevel {
    switch (this) {
      case HongKongDistrict.centralHK:
        return 0.8;
      case HongKongDistrict.mongKok:
        return 0.9;
      case HongKongDistrict.causeWayBay:
        return 0.7;
      case HongKongDistrict.tsimshatSui:
        return 0.6;
      case HongKongDistrict.wanChai:
        return 0.5;
      case HongKongDistrict.saiwan:
        return 0.4;
    }
  }
}