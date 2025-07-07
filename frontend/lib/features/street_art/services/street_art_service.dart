import 'dart:async';
import 'dart:math';
import '../models/street_art_models.dart';

class StreetArtService {
  final Random _random = Random();
  
  Future<StreetArtPiece> createStreetArt({
    required ArtStyle style,
    required SprayTool tool,
    required String location,
    required double leverage,
    required double volatility,
  }) async {
    // Simulate creation time based on style
    await Future.delayed(Duration(milliseconds: (style.creationTime.inMilliseconds * 0.1).round()));
    
    // Calculate success probability based on volatility and tool quality
    final successProbability = _calculateSuccessProbability(volatility, tool, style);
    final isSuccessful = _random.nextDouble() < successProbability;
    
    // Calculate PnL result based on leverage, volatility, and success
    final pnlResult = _calculatePnL(leverage, volatility, isSuccessful);
    
    return StreetArtPiece(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      style: style,
      tool: tool,
      location: location,
      createdAt: DateTime.now(),
      leverageUsed: leverage,
      pnlResult: pnlResult,
      isSuccessful: isSuccessful,
    );
  }

  double _calculateSuccessProbability(double volatility, SprayTool tool, ArtStyle style) {
    // Base success rate
    double baseSuccess = 0.7;
    
    // Tool quality affects success rate
    switch (tool) {
      case SprayTool.basic:
        baseSuccess *= 0.8;
        break;
      case SprayTool.pro:
        baseSuccess *= 1.0;
        break;
      case SprayTool.legendary:
        baseSuccess *= 1.2;
        break;
    }
    
    // Style complexity affects success rate
    switch (style) {
      case ArtStyle.tag:
        baseSuccess *= 1.1;
        break;
      case ArtStyle.piece:
        baseSuccess *= 1.0;
        break;
      case ArtStyle.wildstyle:
        baseSuccess *= 0.9;
        break;
      case ArtStyle.threedimensional:
        baseSuccess *= 0.8;
        break;
    }
    
    // Volatility affects success (higher volatility = higher risk but also higher reward potential)
    baseSuccess *= (1.0 - (volatility - 1.0) * 0.2);
    
    return baseSuccess.clamp(0.1, 0.95);
  }

  double _calculatePnL(double leverage, double volatility, bool isSuccessful) {
    // Base PnL calculation similar to perp trading
    final baseReturn = (_random.nextDouble() - 0.5) * 0.1; // -5% to +5%
    
    // Apply leverage
    double leveragedReturn = baseReturn * leverage;
    
    // Apply volatility multiplier
    leveragedReturn *= volatility;
    
    // If unsuccessful, apply penalty
    if (!isSuccessful) {
      leveragedReturn *= -1.5; // Penalty for getting caught/failing
    }
    
    return leveragedReturn;
  }

  Stream<double> getCreationProgress(ArtStyle style) async* {
    final totalDuration = style.creationTime;
    final steps = 100;
    final stepDuration = totalDuration.inMilliseconds / steps;
    
    for (int i = 0; i <= steps; i++) {
      yield i / steps;
      await Future.delayed(Duration(milliseconds: stepDuration.round()));
    }
  }

  List<PolicePatrol> generatePolicePatrols(List<HongKongDistrict> districts) {
    final patrols = <PolicePatrol>[];
    
    for (final district in districts) {
      // Generate 0-2 patrols per district
      final patrolCount = _random.nextInt(3);
      
      for (int i = 0; i < patrolCount; i++) {
        final startTime = DateTime.now().add(
          Duration(minutes: _random.nextInt(60) - 30), // -30 to +30 minutes
        );
        
        final patrol = PolicePatrol(
          id: '${district.displayName}_$i',
          district: district.displayName,
          startTime: startTime,
          duration: Duration(minutes: 10 + _random.nextInt(20)), // 10-30 minutes
          intensity: 0.3 + _random.nextDouble() * 0.7, // 0.3-1.0
        );
        
        patrols.add(patrol);
      }
    }
    
    return patrols;
  }

  int calculateInkCost(ArtStyle style, SprayTool tool, double leverage) {
    int baseCost = 0;
    
    switch (style) {
      case ArtStyle.tag:
        baseCost = 10;
        break;
      case ArtStyle.piece:
        baseCost = 25;
        break;
      case ArtStyle.wildstyle:
        baseCost = 50;
        break;
      case ArtStyle.threedimensional:
        baseCost = 100;
        break;
    }
    
    // Apply tool efficiency
    baseCost = (baseCost * tool.inkCostMultiplier).round();
    
    // Apply leverage multiplier
    baseCost = (baseCost * leverage).round();
    
    return baseCost;
  }

  double calculateXPReward(StreetArtPiece piece, double volatility) {
    double baseXP = piece.style.baseXpReward.toDouble();
    
    // Apply leverage multiplier
    baseXP *= piece.leverageUsed;
    
    // Apply volatility bonus
    baseXP *= (1.0 + volatility * 0.5);
    
    // Apply success/failure modifier
    if (piece.isSuccessful) {
      baseXP *= 1.5;
    } else {
      baseXP *= 0.3;
    }
    
    return baseXP;
  }
}