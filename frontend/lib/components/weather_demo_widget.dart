import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/weather_provider.dart';
import '../services/weather_service.dart';
import '../app/theme/street_cred_theme.dart';

class WeatherDemoWidget extends ConsumerWidget {
  const WeatherDemoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherDisplay = ref.watch(weatherDisplayProvider);
    final weatherActions = ref.read(weatherActionsProvider);
    final isRaining = ref.watch(isRainingProvider);
    final volatilityMultiplier = ref.watch(volatilityMultiplierProvider);
    final inkEfficiencyBonus = ref.watch(inkEfficiencyBonusProvider);

    return Positioned(
      top: 120,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRaining ? StreetCredTheme.neonBlue : StreetCredTheme.neonYellow,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'WEATHER CONTROL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Current weather status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weatherDisplay['emoji'],
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weatherDisplay['description'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${weatherDisplay['temperature']}°C',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Market effects
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: weatherDisplay['favorable'] 
                    ? StreetCredTheme.neonGreen.withValues(alpha: 0.2)
                    : StreetCredTheme.neonYellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                weatherDisplay['marketImpact'],
                style: TextStyle(
                  color: weatherDisplay['favorable'] 
                      ? StreetCredTheme.neonGreen
                      : StreetCredTheme.neonYellow,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Effects display
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEffectRow(
                  'Volatility',
                  '${volatilityMultiplier.toStringAsFixed(1)}x',
                  volatilityMultiplier > 1.2 ? StreetCredTheme.neonGreen : Colors.grey,
                ),
                _buildEffectRow(
                  'Ink Efficiency',
                  '${inkEfficiencyBonus.toStringAsFixed(1)}x',
                  inkEfficiencyBonus > 1.0 ? StreetCredTheme.neonBlue : Colors.grey,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Toggle button
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: () => weatherActions.toggleWeather(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRaining 
                      ? StreetCredTheme.neonBlue 
                      : StreetCredTheme.neonYellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  isRaining ? 'CLEAR SKIES' : 'MAKE IT RAIN',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              'Tap weather icon in header\nor use this button',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 9,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}