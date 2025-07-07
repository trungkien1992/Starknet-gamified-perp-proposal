import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_card.dart';
import '../providers/wallet_providers.dart';

/// Widget that initializes the wallet service and shows loading/error states
class WalletLauncher extends ConsumerWidget {
  const WalletLauncher({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(walletAuthProvider);

    // Show initialization screen while wallet service is starting up
    if (!authState.isInitialized && authState.isLoading) {
      return _buildInitializationScreen();
    }

    // Show error screen if initialization failed
    if (!authState.isInitialized && authState.error != null) {
      return _buildErrorScreen(context, ref, authState.error!);
    }

    // Wallet service is ready, show the child widget
    return child;
  }

  Widget _buildInitializationScreen() {
    const themeColor = Color(0xFF00FFFF);

    return Scaffold(
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(themeColor),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(StreetCredDesignSystem.spacingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand logo/icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: themeColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: StreetCredDesignSystem.spacingXL),

                  // Loading card
                  StreetCredCard(
                    themeColor: themeColor,
                    size: CardSize.medium,
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          color: themeColor,
                        ),
                        const SizedBox(height: StreetCredDesignSystem.spacingL),
                        Text(
                          'Initializing Wallet',
                          style: StreetCredDesignSystem.titleStyle(themeColor),
                        ),
                        const SizedBox(height: StreetCredDesignSystem.spacingS),
                        Text(
                          'Setting up your secure Web3Auth wallet...',
                          style: StreetCredDesignSystem.bodyStyle(),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: StreetCredDesignSystem.spacingXL),

                  // Loading steps
                  Column(
                    children: [
                      _buildLoadingStep('🔐', 'Initializing Web3Auth', true),
                      _buildLoadingStep('⚡', 'Connecting to Starknet', true),
                      _buildLoadingStep('🛡️', 'Setting up security', true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStep(String emoji, String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: StreetCredDesignSystem.spacingS,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF00FFFF).withValues(alpha: 0.1) : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? const Color(0xFF00FFFF) : const Color(0xFF666666),
                width: 1,
              ),
            ),
            child: Center(
              child: isActive
                  ? Text(emoji, style: const TextStyle(fontSize: 16))
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: StreetCredDesignSystem.spacingM),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          if (isActive) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00FFFF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, WidgetRef ref, String error) {
    const themeColor = Color(0xFFFF4444);

    return Scaffold(
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(themeColor),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(StreetCredDesignSystem.spacingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: themeColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: StreetCredDesignSystem.spacingXL),

                  // Error card
                  StreetCredCard(
                    themeColor: themeColor,
                    size: CardSize.large,
                    child: Column(
                      children: [
                        Text(
                          'Initialization Failed',
                          style: StreetCredDesignSystem.titleStyle(themeColor),
                        ),
                        const SizedBox(height: StreetCredDesignSystem.spacingM),
                        Text(
                          'Failed to initialize the wallet service. Please check your internet connection and try again.',
                          style: StreetCredDesignSystem.bodyStyle(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: StreetCredDesignSystem.spacingL),
                        Container(
                          padding: const EdgeInsets.all(StreetCredDesignSystem.spacingM),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            error,
                            style: StreetCredDesignSystem.captionStyle().copyWith(
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: StreetCredDesignSystem.spacingXL),

                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Clear error and retry initialization
                        ref.read(walletAuthProvider.notifier).clearError();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: StreetCredDesignSystem.spacingM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Retry Initialization',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: StreetCredDesignSystem.spacingM),

                  // Continue without wallet button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to app without wallet
                        Navigator.of(context).pushReplacementNamed('/assets');
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: themeColor),
                        foregroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: StreetCredDesignSystem.spacingM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue Without Wallet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}