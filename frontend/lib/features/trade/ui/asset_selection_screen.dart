import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../widgets/brand_symbol.dart';
import '../../../data/providers/extended_provider.dart';
import '../../../data/datasources/extended_api_client.dart';
import '../../../components/central_background_overlay.dart';

// Provider for selected asset index (for backward compatibility with UI)
final selectedAssetProvider = StateProvider<int>((ref) => 1); // Default to ETH

class AssetSelectionScreen extends ConsumerStatefulWidget {
  const AssetSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AssetSelectionScreen> createState() =>
      _AssetSelectionScreenState();
}

class _AssetSelectionScreenState extends ConsumerState<AssetSelectionScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _glowController;
  late AnimationController _hintController;
  late AnimationController _pressController;
  late Animation<double> _glowAnimation;
  late Animation<double> _hintAnimation;
  late Animation<double> _pressAnimation;

  bool _isPressed = false;

  // Central Hong Kong focused assets for prototype
  final List<Map<String, dynamic>> assets = [
    {
      'symbol': 'HSI',
      'name': 'Hang Seng Index',
      'icon': Icons.account_balance,
      'color': Color(0xFFDC143C), // Crimson red for HSI
      'pair': 'HSI-HKD',
      'description': '中環主指數',
      'location': 'Central Financial District',
    },
    {
      'symbol': 'TCEHY',
      'name': 'Tencent Holdings',
      'icon': Icons.business_center,
      'color': Color(0xFF00D4FF), // Tencent blue
      'pair': 'TCEHY-HKD',
      'description': '科技巨頭',
      'location': 'Central Tower',
    },
    {
      'symbol': 'BTC',
      'name': 'Bitcoin',
      'icon': Icons.currency_bitcoin,
      'color': Color(0xFFF7931A), // Bitcoin orange
      'pair': 'BTC-USDT',
      'description': '數字黃金',
      'location': 'Central Crypto Hub',
    },
  ];

  @override
  void initState() {
    super.initState();

    final selectedIndex = ref.read(selectedAssetProvider);
    _pageController = PageController(
      initialPage: selectedIndex,
      viewportFraction: 0.7,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _hintController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _hintAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.elasticOut),
    );

    _glowController.repeat(reverse: true);

    // Start hint animation after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _hintController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowController.dispose();
    _hintController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedAssetProvider);
    final selectedAsset = assets[selectedIndex];
    final marketDataAsync = ref.watch(extendedMarketDataProvider(selectedAsset['pair']));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: CentralBackgroundOverlay(
        themeColor: selectedAsset['color'],
        isRaining: false,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Brand Symbol
                    BrandSymbol(size: 60, animated: true),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            selectedAsset['color'].withValues(alpha: 0.3),
                            selectedAsset['color'].withValues(alpha: 0.1),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedAsset['color'].withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '中環金融區',
                            style: StreetCredTheme.graffitiTitle.copyWith(
                              fontSize: 16,
                              letterSpacing: 1,
                              color: selectedAsset['color'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CENTRAL FINANCIAL DISTRICT',
                            style: StreetCredTheme.graffitiTitle.copyWith(
                              fontSize: 18,
                              letterSpacing: 2,
                              color: selectedAsset['color'],
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: selectedAsset['color'].withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swipe,
                          color: selectedAsset['color'],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Central district markets only',
                          style: StreetCredTheme.graffitiBody.copyWith(
                            color: selectedAsset['color'].withValues(
                              alpha: 0.8,
                            ),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: selectedAsset['color'],
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Asset Cards Carousel
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        ref.read(selectedAssetProvider.notifier).state = index;
                        // Update the selected market for Extended Exchange
                        final marketSymbol = assets[index]['pair'];
                        ref.read(selectedMarketProvider.notifier).state = marketSymbol;
                        // Reset hint animation when user interacts
                        _hintController.reset();
                      },
                      itemCount: assets.length,
                      itemBuilder: (context, index) {
                        final asset = assets[index];
                        final isSelected = index == selectedIndex;

                        return AnimatedBuilder(
                          animation: Listenable.merge([
                            _glowAnimation,
                            _pressAnimation,
                          ]),
                          builder: (context, child) {
                            return Container(
                              margin: const EdgeInsets.all(20),
                              child: GestureDetector(
                                onTapDown: (_) {
                                  setState(() => _isPressed = true);
                                  _pressController.forward();
                                },
                                onTapUp: (_) {
                                  setState(() => _isPressed = false);
                                  _pressController.reverse();
                                },
                                onTapCancel: () {
                                  setState(() => _isPressed = false);
                                  _pressController.reverse();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  transform: Matrix4.identity()
                                    ..scale(isSelected ? 1.0 : 0.85),
                                  child: Transform.scale(
                                    scale: _isPressed && isSelected
                                        ? 0.95
                                        : 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            asset['color'].withValues(
                                              alpha: isSelected ? 0.4 : 0.2,
                                            ),
                                            asset['color'].withValues(
                                              alpha: isSelected ? 0.2 : 0.1,
                                            ),
                                            StreetCredTheme.darkGrey.withValues(
                                              alpha: 0.9,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: asset['color'],
                                          width: isSelected ? 3 : 2,
                                        ),
                                        boxShadow: [
                                          // Base glow
                                          BoxShadow(
                                            color: asset['color'].withValues(
                                              alpha: isSelected
                                                  ? _glowAnimation.value * 0.6
                                                  : 0.2,
                                            ),
                                            blurRadius: isSelected ? 30 : 15,
                                            spreadRadius: isSelected ? 5 : 2,
                                          ),
                                          // Press effect - additional intense glow
                                          if (_isPressed && isSelected)
                                            BoxShadow(
                                              color: asset['color'].withValues(
                                                alpha:
                                                    _pressAnimation.value * 0.8,
                                              ),
                                              blurRadius:
                                                  40 * _pressAnimation.value,
                                              spreadRadius:
                                                  8 * _pressAnimation.value,
                                            ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(30),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Asset Symbol
                                            Text(
                                              asset['symbol'],
                                              style: StreetCredTheme
                                                  .graffitiTitle
                                                  .copyWith(
                                                    fontSize: 32,
                                                    color: asset['color'],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),

                                            const SizedBox(height: 8),

                                            // Asset Name
                                            Text(
                                              asset['name'],
                                              style: StreetCredTheme
                                                  .graffitiSubtitle
                                                  .copyWith(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                  ),
                                            ),

                                            const SizedBox(height: 4),

                                            // Description
                                            Text(
                                              asset['description'],
                                              style: StreetCredTheme
                                                  .graffitiBody
                                                  .copyWith(
                                                    fontSize: 12,
                                                    color: Colors.grey[400],
                                                  ),
                                            ),

                                            const SizedBox(height: 4),

                                            // Central Location
                                            Text(
                                              asset['location'],
                                              style: StreetCredTheme
                                                  .graffitiBody
                                                  .copyWith(
                                                    fontSize: 10,
                                                    color: asset['color'].withValues(alpha: 0.7),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),

                                            const SizedBox(height: 20),

                                            // Price Info from Extended Exchange
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: StreetCredTheme.darkAlley
                                                    .withValues(alpha: 0.6),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: asset['color']
                                                      .withValues(alpha: 0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: index == selectedIndex
                                                  ? marketDataAsync.when(
                                                      data: (marketData) => Column(
                                                        children: [
                                                          Text(
                                                            asset['pair'],
                                                            style: StreetCredTheme
                                                                .graffitiBody
                                                                .copyWith(
                                                                  color:
                                                                      Colors.grey[300],
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            '\$${marketData.price}',
                                                            style: StreetCredTheme
                                                                .graffitiSubtitle
                                                                .copyWith(
                                                                  color: marketData.isPositive
                                                                      ? StreetCredTheme.longColor
                                                                      : StreetCredTheme.shortColor,
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight.bold,
                                                                ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            '${marketData.changePercent >= 0 ? '+' : ''}${marketData.changePercent.toStringAsFixed(2)}%',
                                                            style: StreetCredTheme
                                                                .graffitiBody
                                                                .copyWith(
                                                                  color: marketData.isPositive
                                                                      ? StreetCredTheme.longColor
                                                                      : StreetCredTheme.shortColor,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight.w600,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      loading: () => Column(
                                                        children: [
                                                          Text(
                                                            asset['pair'],
                                                            style: StreetCredTheme
                                                                .graffitiBody
                                                                .copyWith(
                                                                  color: Colors.grey[300],
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            'Loading...',
                                                            style: StreetCredTheme
                                                                .graffitiSubtitle
                                                                .copyWith(
                                                                  color: Colors.grey[400],
                                                                  fontSize: 20,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      error: (error, stack) => Column(
                                                        children: [
                                                          Text(
                                                            asset['pair'],
                                                            style: StreetCredTheme
                                                                .graffitiBody
                                                                .copyWith(
                                                                  color: Colors.grey[300],
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            'Price unavailable',
                                                            style: StreetCredTheme
                                                                .graffitiSubtitle
                                                                .copyWith(
                                                                  color: Colors.red,
                                                                  fontSize: 16,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : Column(
                                                      children: [
                                                        Text(
                                                          asset['pair'],
                                                          style: StreetCredTheme
                                                              .graffitiBody
                                                              .copyWith(
                                                                color: Colors.grey[300],
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'Swipe to view',
                                                          style: StreetCredTheme
                                                              .graffitiSubtitle
                                                              .copyWith(
                                                                color: Colors.grey[500],
                                                                fontSize: 16,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // Navigation Arrows
                    if (selectedIndex > 0)
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: AnimatedBuilder(
                          animation: _hintAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(-5 * _hintAnimation.value, 0),
                              child: Center(
                                child: GestureDetector(
                                  onTap: () {
                                    _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: selectedAsset['color'].withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedAsset['color'],
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: selectedAsset['color']
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      color: selectedAsset['color'],
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    if (selectedIndex < assets.length - 1)
                      Positioned(
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: AnimatedBuilder(
                          animation: _hintAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(5 * _hintAnimation.value, 0),
                              child: Center(
                                child: GestureDetector(
                                  onTap: () {
                                    _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: selectedAsset['color'].withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedAsset['color'],
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: selectedAsset['color']
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      color: selectedAsset['color'],
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // Page Indicators
              Container(
                height: 50,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        assets.length,
                        (index) => GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == selectedIndex ? 32 : 12,
                            height: index == selectedIndex ? 12 : 8,
                            decoration: BoxDecoration(
                              color: index == selectedIndex
                                  ? selectedAsset['color']
                                  : Colors.grey[600],
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: index == selectedIndex
                                  ? [
                                      BoxShadow(
                                        color: selectedAsset['color']
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${selectedIndex + 1} of ${assets.length}',
                      style: StreetCredTheme.graffitiBody.copyWith(
                        color: selectedAsset['color'].withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            selectedAsset['color'],
                            selectedAsset['color'].withValues(alpha: 0.8),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: selectedAsset['color'].withValues(
                              alpha: _glowAnimation.value * 0.6,
                            ),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Ensure the selected market is set before navigating
                          final marketSymbol = selectedAsset['pair'];
                          ref.read(selectedMarketProvider.notifier).state = marketSymbol;
                          context.go('/arena');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selectedAsset['icon'],
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'START TRADING ${selectedAsset['symbol']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
