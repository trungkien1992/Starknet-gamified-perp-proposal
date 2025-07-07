import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/street_cred_design_system.dart';
import '../../../../app/widgets/street_cred_card.dart';
import '../../models/wallet_models.dart';
import '../../providers/wallet_providers.dart';

class ProviderSelectionWidget extends ConsumerWidget {
  const ProviderSelectionWidget({
    super.key,
    required this.onProviderSelected,
    this.isLoading = false,
  });

  final Function(AuthProvider) onProviderSelected;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableProviders = ref.watch(availableProvidersProvider);

    return Column(
      children: [
        Text(
          'Choose your login method',
          style: StreetCredDesignSystem.subtitleStyle(
            const Color(0xFF00FF41),
          ).copyWith(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: StreetCredDesignSystem.spacingL),
        
        // Social providers
        ...availableProviders.map((provider) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: StreetCredDesignSystem.spacingM,
            ),
            child: _buildProviderButton(provider),
          );
        }),

        const SizedBox(height: StreetCredDesignSystem.spacingL),
        
        // Privacy note
        Container(
          padding: const EdgeInsets.all(StreetCredDesignSystem.spacingM),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00FF41).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.security,
                color: Color(0xFF00FF41),
                size: 20,
              ),
              const SizedBox(width: StreetCredDesignSystem.spacingS),
              Expanded(
                child: Text(
                  'Secured by Web3Auth. Your keys, your wallet, your control.',
                  style: StreetCredDesignSystem.captionStyle().copyWith(
                    color: const Color(0xFF00FF41),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderButton(AuthProvider provider) {
    return StreetCredCard(
      themeColor: _getProviderColor(provider),
      size: CardSize.medium,
      enablePressEffect: !isLoading,
      onTap: isLoading ? null : () => onProviderSelected(provider),
      child: Row(
        children: [
          // Provider icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _getProviderColor(provider).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              _getProviderIcon(provider),
              color: _getProviderColor(provider),
              size: 24,
            ),
          ),
          
          const SizedBox(width: StreetCredDesignSystem.spacingM),
          
          // Provider text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue with ${provider.displayName}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fast & secure authentication',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
          // Loading indicator or arrow
          if (isLoading) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00FF41),
              ),
            ),
          ] else ...[
            Icon(
              Icons.arrow_forward_ios,
              color: _getProviderColor(provider),
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  Color _getProviderColor(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return const Color(0xFF4285F4);
      case AuthProvider.apple:
        return const Color(0xFFFFFFFF);
      case AuthProvider.discord:
        return const Color(0xFF5865F2);
      case AuthProvider.twitter:
        return const Color(0xFF1DA1F2);
      case AuthProvider.facebook:
        return const Color(0xFF1877F2);
      case AuthProvider.email:
        return const Color(0xFF00FF41);
      default:
        return const Color(0xFF00FFFF);
    }
  }

  IconData _getProviderIcon(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return Icons.g_mobiledata;
      case AuthProvider.apple:
        return Icons.apple;
      case AuthProvider.discord:
        return Icons.discord;
      case AuthProvider.twitter:
        return Icons.alternate_email;
      case AuthProvider.facebook:
        return Icons.facebook;
      case AuthProvider.email:
        return Icons.email;
      default:
        return Icons.login;
    }
  }
}