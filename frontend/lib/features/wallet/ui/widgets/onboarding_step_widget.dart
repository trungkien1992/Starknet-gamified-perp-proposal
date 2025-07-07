import 'package:flutter/material.dart';
import '../../../../app/theme/street_cred_design_system.dart';
import '../../../../app/widgets/street_cred_card.dart';
import '../../models/wallet_models.dart';

class OnboardingStepWidget extends StatelessWidget {
  const OnboardingStepWidget({
    super.key,
    required this.step,
  });

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return StreetCredCard(
      themeColor: _getStepColor(step.index),
      size: CardSize.large,
      child: Column(
        children: [
          // Illustration placeholder
          if (step.illustration != null) ...[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: _getStepColor(step.index).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _getStepIcon(step.index),
                size: 60,
                color: _getStepColor(step.index),
              ),
            ),
            const SizedBox(height: StreetCredDesignSystem.spacingL),
          ],

          // Title
          Text(
            step.title,
            style: StreetCredDesignSystem.titleStyle(
              _getStepColor(step.index),
            ).copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: StreetCredDesignSystem.spacingM),

          // Description
          Text(
            step.description,
            style: StreetCredDesignSystem.bodyStyle(),
            textAlign: TextAlign.center,
          ),

          // Step-specific content
          if (step.index == 0) ...[
            const SizedBox(height: StreetCredDesignSystem.spacingL),
            _buildWelcomeFeatures(),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeFeatures() {
    return Column(
      children: [
        _buildFeature(
          '🎨',
          'Spray Paint Trades',
          'Swipe gestures turn boring trades into street art',
        ),
        _buildFeature(
          '⚡',
          'Lightning Fast',
          'Powered by Starknet for instant, low-cost trades',
        ),
        _buildFeature(
          '🏆',
          'Earn & Battle',
          'Gain XP, unlock NFTs, and challenge friends',
        ),
      ],
    );
  }

  Widget _buildFeature(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: StreetCredDesignSystem.spacingS,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00FFFF).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: StreetCredDesignSystem.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStepColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF00FFFF);
      case 1:
        return const Color(0xFF00FF41);
      case 2:
        return const Color(0xFFFF0080);
      case 3:
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF00FFFF);
    }
  }

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0:
        return Icons.celebration;
      case 1:
        return Icons.login;
      case 2:
        return Icons.account_balance_wallet;
      case 3:
        return Icons.rocket_launch;
      default:
        return Icons.info;
    }
  }
}