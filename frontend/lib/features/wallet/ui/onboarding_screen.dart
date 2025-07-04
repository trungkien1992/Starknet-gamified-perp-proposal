import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_button.dart' as scb;
import '../../../app/widgets/street_cred_card.dart';
import '../../../app/widgets/street_cred_header.dart';
import '../models/wallet_models.dart';
import '../providers/wallet_providers.dart';
import 'widgets/onboarding_step_widget.dart';
import 'widgets/provider_selection_widget.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = ref.watch(onboardingStepsProvider);
    final authState = ref.watch(walletAuthProvider);
    
    // Auto-advance on successful authentication
    ref.listen(walletAuthProvider, (previous, next) {
      if (next.isAuthenticated && !next.isConnectingWallet && _currentStep == 1) {
        _nextStep();
      }
      if (next.wallet != null && _currentStep == 2) {
        _nextStep();
      }
    });

    const themeColor = Color(0xFF00FFFF);

    return Scaffold(
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(themeColor),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress
              Padding(
                padding: const EdgeInsets.all(StreetCredDesignSystem.spacingL),
                child: Column(
                  children: [
                    StreetCredHeader(
                      title: 'ONBOARDING',
                      themeColor: themeColor,
                      showBrandSymbol: true,
                    ),
                    const SizedBox(height: StreetCredDesignSystem.spacingL),
                    _buildProgressIndicator(steps.length),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                      _animationController.forward();
                    },
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      return _buildStepContent(step, authState);
                    },
                  ),
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(StreetCredDesignSystem.spacingL),
                child: _buildNavigationButtons(steps, authState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int totalSteps) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index <= _currentStep;
        final isCompleted = index < _currentStep;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: index > 0 ? 4 : 0,
              right: index < totalSteps - 1 ? 4 : 0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isCompleted
                    ? const Color(0xFF00FF41)
                    : isActive
                        ? const Color(0xFF00FFFF)
                        : const Color(0xFF2A2A2A),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(OnboardingStep step, WalletAuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: StreetCredDesignSystem.spacingL,
      ),
      child: Column(
        children: [
          const SizedBox(height: StreetCredDesignSystem.spacingXL),
          
          // Step content based on index
          if (step.index == 0) ...[
            OnboardingStepWidget(step: step),
          ] else if (step.index == 1) ...[
            OnboardingStepWidget(step: step),
            const SizedBox(height: StreetCredDesignSystem.spacingXL),
            ProviderSelectionWidget(
              onProviderSelected: _handleProviderSelection,
              isLoading: authState.isLoading,
            ),
          ] else if (step.index == 2) ...[
            OnboardingStepWidget(step: step),
            const SizedBox(height: StreetCredDesignSystem.spacingXL),
            _buildWalletSetupWidget(authState),
          ] else if (step.index == 3) ...[
            OnboardingStepWidget(step: step),
            const SizedBox(height: StreetCredDesignSystem.spacingXL),
            _buildCompletionWidget(authState),
          ],
          
          const SizedBox(height: StreetCredDesignSystem.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildWalletSetupWidget(WalletAuthState authState) {
    if (authState.wallet != null) {
      return StreetCredCard(
        themeColor: const Color(0xFF00FF41),
        size: CardSize.medium,
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF00FF41),
              size: 48,
            ),
            const SizedBox(height: StreetCredDesignSystem.spacingM),
            Text(
              'Wallet Created!',
              style: StreetCredDesignSystem.titleStyle(
                const Color(0xFF00FF41),
              ),
            ),
            const SizedBox(height: StreetCredDesignSystem.spacingS),
            Text(
              'Address: ${_truncateAddress(authState.wallet!.address)}',
              style: StreetCredDesignSystem.captionStyle(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return StreetCredCard(
      themeColor: const Color(0xFF00FFFF),
      size: CardSize.medium,
      child: Column(
        children: [
          if (authState.isConnectingWallet) ...[
            const CircularProgressIndicator(
              color: Color(0xFF00FFFF),
            ),
            const SizedBox(height: StreetCredDesignSystem.spacingM),
            Text(
              'Creating your wallet...',
              style: StreetCredDesignSystem.bodyStyle(),
            ),
          ] else ...[
            const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF00FFFF),
              size: 48,
            ),
            const SizedBox(height: StreetCredDesignSystem.spacingM),
            Text(
              'Ready to create wallet',
              style: StreetCredDesignSystem.titleStyle(
                const Color(0xFF00FFFF),
              ),
            ),
            const SizedBox(height: StreetCredDesignSystem.spacingS),
            Text(
              'Tap the button below to generate your secure Starknet wallet.',
              style: StreetCredDesignSystem.bodyStyle(),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionWidget(WalletAuthState authState) {
    return StreetCredCard(
      themeColor: const Color(0xFFFFD700),
      size: CardSize.large,
      child: Column(
        children: [
          const Icon(
            Icons.celebration,
            color: Color(0xFFFFD700),
            size: 64,
          ),
          const SizedBox(height: StreetCredDesignSystem.spacingL),
          Text(
            'Welcome to StreetCred!',
            style: StreetCredDesignSystem.titleStyle(
              const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: StreetCredDesignSystem.spacingM),
          Text(
            'You\'re ready to start spray painting the streets with your trades!',
            style: StreetCredDesignSystem.bodyStyle(),
            textAlign: TextAlign.center,
          ),
          if (authState.user != null) ...[
            const SizedBox(height: StreetCredDesignSystem.spacingL),
            Text(
              'Welcome, ${authState.user!.name}!',
              style: StreetCredDesignSystem.subtitleStyle(
                const Color(0xFF00FFFF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(List<OnboardingStep> steps, WalletAuthState authState) {
    final currentStep = steps[_currentStep];
    final isLastStep = _currentStep == steps.length - 1;
    final canProceed = _canProceedFromCurrentStep(authState);

    return Column(
      children: [
        // Primary action button
        scb.StreetCredButton(
          text: _getButtonText(currentStep, authState, isLastStep),
          themeColor: _getButtonColor(_currentStep),
          style: scb.ButtonStyle.primary,
          width: double.infinity,
          height: 56,
          isLoading: _isStepLoading(authState),
          onPressed: canProceed ? () => _handlePrimaryAction(authState, isLastStep) : null,
        ),
        
        // Back button (except for first step)
        if (_currentStep > 0) ...[
          const SizedBox(height: StreetCredDesignSystem.spacingM),
          scb.StreetCredButton(
            text: 'Back',
            themeColor: const Color(0xFF666666),
            style: scb.ButtonStyle.secondary,
            width: double.infinity,
            onPressed: _previousStep,
          ),
        ],
        
        // Skip button for non-essential steps
        if (_currentStep == 0) ...[
          const SizedBox(height: StreetCredDesignSystem.spacingM),
          TextButton(
            onPressed: () => context.go('/assets'),
            child: Text(
              'Skip onboarding',
              style: StreetCredDesignSystem.captionStyle(),
            ),
          ),
        ],
      ],
    );
  }

  String _getButtonText(OnboardingStep step, WalletAuthState authState, bool isLastStep) {
    if (_currentStep == 1 && authState.isLoading) {
      return 'Connecting...';
    }
    if (_currentStep == 2 && authState.isConnectingWallet) {
      return 'Creating Wallet...';
    }
    if (isLastStep) {
      return 'Start Trading!';
    }
    return step.buttonText;
  }

  Color _getButtonColor(int stepIndex) {
    switch (stepIndex) {
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

  bool _isStepLoading(WalletAuthState authState) {
    return authState.isLoading || authState.isConnectingWallet;
  }

  bool _canProceedFromCurrentStep(WalletAuthState authState) {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        return authState.isAuthenticated;
      case 2:
        return authState.wallet != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _handlePrimaryAction(WalletAuthState authState, bool isLastStep) {
    if (isLastStep) {
      _completeOnboarding();
    } else if (_currentStep == 2 && authState.isAuthenticated && authState.wallet == null) {
      _createWallet();
    } else {
      _nextStep();
    }
  }

  void _handleProviderSelection(AuthProvider provider) async {
    try {
      await ref.read(walletAuthProvider.notifier).authenticateWithSocial(provider);
    } catch (e) {
      _showError('Authentication failed: ${e.toString()}');
    }
  }

  void _createWallet() async {
    try {
      await ref.read(walletAuthProvider.notifier).connectStarknetWallet();
    } catch (e) {
      _showError('Wallet creation failed: ${e.toString()}');
    }
  }

  void _completeOnboarding() async {
    try {
      await ref.read(walletAuthProvider.notifier).completeOnboarding();
      if (mounted) {
        context.go('/assets');
      }
    } catch (e) {
      _showError('Failed to complete onboarding: ${e.toString()}');
    }
  }

  void _nextStep() {
    if (_currentStep < ref.read(onboardingStepsProvider).length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}