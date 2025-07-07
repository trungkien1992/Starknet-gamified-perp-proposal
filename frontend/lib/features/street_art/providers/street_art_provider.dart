import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/street_art_models.dart';
import '../services/street_art_service.dart';

final streetArtServiceProvider = Provider<StreetArtService>((ref) => StreetArtService());

final selectedSprayToolProvider = StateProvider<SprayTool>((ref) => SprayTool.basic);

final selectedArtStyleProvider = StateProvider<ArtStyle>((ref) => ArtStyle.tag);

final currentDistrictProvider = StateProvider<HongKongDistrict>((ref) => HongKongDistrict.centralHK);

final artCreationProgressProvider = StateProvider<double>((ref) => 0.0);

final isCreatingArtProvider = StateProvider<bool>((ref) => false);

final streetArtPiecesProvider = StateNotifierProvider<StreetArtPiecesNotifier, List<StreetArtPiece>>(
  (ref) => StreetArtPiecesNotifier(),
);

final policePatrolsProvider = StateNotifierProvider<PolicePatrolsNotifier, List<PolicePatrol>>(
  (ref) => PolicePatrolsNotifier(),
);

final rivalCrewsProvider = StateNotifierProvider<RivalCrewsNotifier, List<RivalCrew>>(
  (ref) => RivalCrewsNotifier(),
);

final nightlifeVolatilityProvider = StateProvider<double>((ref) {
  final patrols = ref.watch(policePatrolsProvider);
  final crews = ref.watch(rivalCrewsProvider);
  final district = ref.watch(currentDistrictProvider);
  
  double volatility = district.riskLevel;
  
  // Add police patrol influence
  final activePatrols = patrols.where((p) => p.isActive && p.district == district.displayName);
  for (final patrol in activePatrols) {
    volatility *= patrol.riskMultiplier;
  }
  
  // Add rival crew influence
  final localCrews = crews.where((c) => c.territory == district.displayName);
  for (final crew in localCrews) {
    if (crew.isHostile) {
      volatility *= (1.0 + crew.strength);
    }
  }
  
  return volatility.clamp(0.1, 3.0);
});

class StreetArtPiecesNotifier extends StateNotifier<List<StreetArtPiece>> {
  StreetArtPiecesNotifier() : super([]);

  void addPiece(StreetArtPiece piece) {
    state = [...state, piece];
  }

  void removePiece(String id) {
    state = state.where((piece) => piece.id != id).toList();
  }

  List<StreetArtPiece> getPiecesByDistrict(String district) {
    return state.where((piece) => piece.location == district).toList();
  }
}

class PolicePatrolsNotifier extends StateNotifier<List<PolicePatrol>> {
  PolicePatrolsNotifier() : super([]) {
    _initializePatrols();
  }

  void _initializePatrols() {
    state = [
      PolicePatrol(
        id: '1',
        district: 'Central HK',
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        duration: const Duration(minutes: 15),
        intensity: 0.8,
      ),
      PolicePatrol(
        id: '2',
        district: 'Mong Kok',
        startTime: DateTime.now().add(const Duration(minutes: 10)),
        duration: const Duration(minutes: 20),
        intensity: 0.9,
      ),
    ];
  }

  void addPatrol(PolicePatrol patrol) {
    state = [...state, patrol];
  }

  void removePatrol(String id) {
    state = state.where((patrol) => patrol.id != id).toList();
  }

  void updatePatrols() {
    // Remove expired patrols and add new ones
    final now = DateTime.now();
    final activePatrols = state.where((p) => 
      now.isBefore(p.startTime.add(p.duration))
    ).toList();
    
    state = activePatrols;
  }
}

class RivalCrewsNotifier extends StateNotifier<List<RivalCrew>> {
  RivalCrewsNotifier() : super([]) {
    _initializeCrews();
  }

  void _initializeCrews() {
    state = [
      const RivalCrew(
        name: 'Neon Dragons',
        territory: 'Central HK',
        strength: 0.7,
        isHostile: true,
      ),
      const RivalCrew(
        name: 'Electric Cats',
        territory: 'Mong Kok',
        strength: 0.6,
        isHostile: false,
      ),
      const RivalCrew(
        name: 'Cyber Wolves',
        territory: 'Causeway Bay',
        strength: 0.8,
        isHostile: true,
      ),
    ];
  }

  void addCrew(RivalCrew crew) {
    state = [...state, crew];
  }

  void removeCrew(String name) {
    state = state.where((crew) => crew.name != name).toList();
  }

  void updateCrewHostility(String name, bool isHostile) {
    state = state.map((crew) {
      if (crew.name == name) {
        return RivalCrew(
          name: crew.name,
          territory: crew.territory,
          strength: crew.strength,
          isHostile: isHostile,
        );
      }
      return crew;
    }).toList();
  }
}