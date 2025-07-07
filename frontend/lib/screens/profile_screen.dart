import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../services/trade_result_service.dart';
import '../components/drip_inventory_widget.dart';
import '../components/xp_burst_animation.dart';
import '../utils/transition_animations.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String? avatarUrl;
  final Function(String)? onAvatarChange;
  final VoidCallback? onViewFullCollection;
  final VoidCallback? onEditProfile;

  const ProfileScreen({
    super.key,
    required this.username,
    this.avatarUrl,
    this.onAvatarChange,
    this.onViewFullCollection,
    this.onEditProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _streakPulseController;
  late AnimationController _levelGlowController;
  late AnimationController _slideInController;
  
  late Animation<double> _streakPulseAnimation;
  late Animation<double> _levelGlowAnimation;
  late Animation<double> _slideInAnimation;

  final TradeResultService _tradeService = TradeResultService();
  
  // Mock user data - in real app, this would come from user service
  int _currentStreak = 4;
  int _totalTrades = 127;
  List<DripNFT> _recentDrips = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _startAnimations();
  }

  void _initializeAnimations() {
    _streakPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _levelGlowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideInController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _streakPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _streakPulseController,
      curve: Curves.easeInOut,
    ));

    _levelGlowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _levelGlowController,
      curve: Curves.easeInOut,
    ));

    _slideInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideInController,
      curve: Curves.elasticOut,
    ));
  }

  void _loadUserData() {
    // Simulate loading recent drips
    _recentDrips = [
      const DripNFT(
        name: "Neon Shades",
        rarity: "epic",
        imageUrl: "",
        id: "drip_001",
      ),
      const DripNFT(
        name: "Street Chain",
        rarity: "rare",
        imageUrl: "",
        id: "drip_002",
      ),
      const DripNFT(
        name: "Basic Cap",
        rarity: "common",
        imageUrl: "",
        id: "drip_003",
      ),
    ];
  }

  void _startAnimations() {
    _slideInController.forward();
    
    if (_currentStreak > 0) {
      _streakPulseController.repeat(reverse: true);
    }
    
    _levelGlowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _streakPulseController.dispose();
    _levelGlowController.dispose();
    _slideInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _slideInAnimation,
          _streakPulseAnimation,
          _levelGlowAnimation,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _slideInAnimation.value)),
            child: Opacity(
              opacity: _slideInAnimation.value,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 24),
                        _buildStatsSection(),
                        const SizedBox(height: 24),
                        _buildRecentDripsSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 24,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.withValues(alpha: 0.8),
                Colors.blue.withValues(alpha: 0.6),
                Colors.cyan.withValues(alpha: 0.4),
              ],
            ),
          ),
        ),
        title: Text(
          'PROFILE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      actions: [
        IconButton(
          onPressed: widget.onEditProfile,
          icon: const Icon(
            Icons.edit,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.2 * _levelGlowAnimation.value),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _showAvatarOptions,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.cyan,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withValues(alpha: 0.5 * _levelGlowAnimation.value),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 47,
                backgroundColor: Colors.purple,
                backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                    ? Text(
                        widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Username
          Text(
            widget.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 2),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.5 * _levelGlowAnimation.value),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              'LEVEL ${_tradeService.currentLevel}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // XP Bar
          TransitionAnimations.glowPulse(
            glowColor: Colors.cyan,
            child: _buildXpBar(),
          ),

          const SizedBox(height: 16),

          // Streak
          if (_currentStreak > 0)
            Transform.scale(
              scale: _streakPulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.orange,
                    width: 2,
                  ),
                ),
                child: Text(
                  '🔥 $_currentStreak-day streak!',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildXpBar() {
    final progress = _tradeService.currentXp / _tradeService.xpToLevelUp;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_tradeService.currentXp} XP',
              style: const TextStyle(
                color: Colors.cyan,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_tradeService.xpToLevelUp} XP',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.trending_up,
              label: 'Total XP',
              value: _formatNumber(_tradeService.currentXp + (_tradeService.currentLevel - 1) * 1000),
              color: Colors.cyan,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.swap_horiz,
              label: 'Trades',
              value: _totalTrades.toString(),
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDripsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Drips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: widget.onViewFullCollection,
                child: const Text(
                  'View Full Collection',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_recentDrips.isNotEmpty)
            DripInventoryWidget(
              drips: _recentDrips,
              crossAxisCount: 3,
              cardWidth: 100,
              cardHeight: 120,
              padding: EdgeInsets.zero,
              onDripTap: (drip) {
                HapticFeedback.lightImpact();
                _showDripDetails(drip);
              },
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 32,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No drips yet',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Complete trades to earn your first drips!',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TransitionAnimations.slideUpSpring(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Avatar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAvatarOption('📸', 'Camera'),
                  _buildAvatarOption('🖼️', 'Gallery'),
                  _buildAvatarOption('🎨', 'Generate'),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarOption(String emoji, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        // Handle avatar change
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDripDetails(DripNFT drip) {
    showDialog(
      context: context,
      builder: (context) => TransitionAnimations.fadeScaleModal(
        child: AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            drip.name,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'Rarity: ${drip.rarity.toUpperCase()}',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// Extension for sample data
extension ProfileScreenExtensions on ProfileScreen {
  static void showProfile(BuildContext context, {String username = "Player"}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProfileScreen(
          username: username,
          onViewFullCollection: () {
            // Navigate to full collection
          },
          onEditProfile: () {
            // Navigate to edit profile
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}