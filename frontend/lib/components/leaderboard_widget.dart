import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class LeaderboardEntry {
  final String username;
  final int xp;
  final int rank;
  final String? avatarUrl;
  final double? winRate;
  final int? totalTrades;

  const LeaderboardEntry({
    required this.username,
    required this.xp,
    required this.rank,
    this.avatarUrl,
    this.winRate,
    this.totalTrades,
  });
}

class LeaderboardWidget extends StatefulWidget {
  final List<LeaderboardEntry> entries;
  final String? currentUsername;
  final Function(LeaderboardEntry)? onUserTap;
  final bool showPodium;
  final double height;

  const LeaderboardWidget({
    super.key,
    required this.entries,
    this.currentUsername,
    this.onUserTap,
    this.showPodium = true,
    this.height = 600.0,
  });

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _glowController;
  late List<Animation<double>> _entryAnimations;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Create staggered animations for each entry
    _entryAnimations = List.generate(
      math.min(widget.entries.length, 10),
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Interval(
          index * 0.1,
          math.min(1.0, (index + 1) * 0.1 + 0.3),
          curve: Curves.elasticOut,
        ),
      )),
    );
  }

  void _startAnimations() {
    _slideController.forward();
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = List<LeaderboardEntry>.from(widget.entries)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _glowController]),
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
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
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Podium (top 3)
              if (widget.showPodium && sortedEntries.length >= 3)
                _buildPodium(sortedEntries.take(3).toList()),
              
              // Rest of the list
              Expanded(
                child: _buildLeaderboardList(
                  widget.showPodium ? sortedEntries.skip(3).toList() : sortedEntries,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withValues(alpha: 0.8), Colors.blue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events,
            color: Colors.yellow,
            size: 32,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Text(
            'TOP TRADERS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> topThree) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (topThree.length > 1)
            _buildPodiumEntry(topThree[1], 2, 120),
          
          // 1st place
          _buildPodiumEntry(topThree[0], 1, 150),
          
          // 3rd place
          if (topThree.length > 2)
            _buildPodiumEntry(topThree[2], 3, 100),
        ],
      ),
    );
  }

  Widget _buildPodiumEntry(LeaderboardEntry entry, int position, double height) {
    final colors = {
      1: Colors.yellow,
      2: Colors.grey[300]!,
      3: Colors.orange[800]!,
    };
    
    final icons = {
      1: Icons.looks_one,
      2: Icons.looks_two,
      3: Icons.looks_3,
    };

    return AnimatedBuilder(
      animation: _entryAnimations.isNotEmpty ? _entryAnimations[position - 1] : kAlwaysCompleteAnimation,
      builder: (context, child) {
        final animation = _entryAnimations.isNotEmpty ? _entryAnimations[position - 1] : kAlwaysCompleteAnimation;
        
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onUserTap?.call(entry);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Crown/medal
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors[position],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors[position]!.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      icons[position],
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Avatar
                  _buildAvatar(entry, 35),
                  
                  const SizedBox(height: 8),
                  
                  // Username
                  SizedBox(
                    width: 80,
                    child: Text(
                      entry.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // XP
                  Text(
                    '${_formatNumber(entry.xp)} XP',
                    style: TextStyle(
                      color: colors[position],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Podium base
                  Container(
                    width: 80,
                    height: height * animation.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors[position]!.withValues(alpha: 0.8),
                          colors[position]!.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      border: Border.all(
                        color: colors[position]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '#$position',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No more entries',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final animationIndex = widget.showPodium ? index + 3 : index;
        final animation = animationIndex < _entryAnimations.length 
            ? _entryAnimations[animationIndex] 
            : kAlwaysCompleteAnimation;
        
        return _buildLeaderboardEntry(entry, animation, index);
      },
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, Animation<double> animation, int listIndex) {
    final isCurrentUser = entry.username == widget.currentUsername;
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(300 * (1 - animation.value), 0),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentUser 
                      ? Colors.blue.withValues(alpha: 0.5)
                      : Colors.grey[700]!,
                  width: isCurrentUser ? 2 : 1,
                ),
                boxShadow: isCurrentUser ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3 * _glowAnimation.value),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ] : null,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onUserTap?.call(entry);
                },
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getRankColor(entry.rank),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '#${entry.rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Avatar
                    _buildAvatar(entry, 25),
                    
                    const SizedBox(width: 16),
                    
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  entry.username,
                                  style: TextStyle(
                                    color: isCurrentUser ? Colors.blue : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'YOU',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${_formatNumber(entry.xp)} XP',
                                style: const TextStyle(
                                  color: Colors.cyan,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (entry.winRate != null) ...[
                                const SizedBox(width: 16),
                                Text(
                                  '${(entry.winRate! * 100).toStringAsFixed(0)}% Win',
                                  style: TextStyle(
                                    color: entry.winRate! >= 0.5 ? Colors.green : Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Chevron
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(LeaderboardEntry entry, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _getAvatarColor(entry.username),
      backgroundImage: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
          ? NetworkImage(entry.avatarUrl!)
          : null,
      child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
          ? Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return Colors.yellow.withValues(alpha: 0.8);
    if (rank <= 10) return Colors.purple.withValues(alpha: 0.8);
    if (rank <= 50) return Colors.blue.withValues(alpha: 0.8);
    return Colors.grey.withValues(alpha: 0.8);
  }

  Color _getAvatarColor(String username) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    final hash = username.hashCode.abs();
    return colors[hash % colors.length];
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

// Utility class for creating sample leaderboard data
class LeaderboardSamples {
  static List<LeaderboardEntry> getSampleLeaderboard({String? currentUser}) {
    final entries = [
      const LeaderboardEntry(username: 'CryptoKing', xp: 15420, rank: 1, winRate: 0.78),
      const LeaderboardEntry(username: 'BullRun', xp: 14200, rank: 2, winRate: 0.72),
      const LeaderboardEntry(username: 'DiamondHands', xp: 13800, rank: 3, winRate: 0.69),
      const LeaderboardEntry(username: 'MoonShot', xp: 12600, rank: 4, winRate: 0.65),
      const LeaderboardEntry(username: 'PumpMaster', xp: 11900, rank: 5, winRate: 0.61),
      const LeaderboardEntry(username: 'TradingBot', xp: 11200, rank: 6, winRate: 0.58),
      const LeaderboardEntry(username: 'LeverageLord', xp: 10800, rank: 7, winRate: 0.55),
      const LeaderboardEntry(username: 'CryptoNinja', xp: 10400, rank: 8, winRate: 0.52),
      const LeaderboardEntry(username: 'BearHunter', xp: 9800, rank: 9, winRate: 0.49),
      const LeaderboardEntry(username: 'AlphaSeeker', xp: 9200, rank: 10, winRate: 0.46),
    ];

    // Add current user if specified
    if (currentUser != null) {
      entries.insert(
        5, 
        LeaderboardEntry(
          username: currentUser,
          xp: 11500,
          rank: 6,
          winRate: 0.60,
        ),
      );
      
      // Adjust ranks
      for (int i = 6; i < entries.length; i++) {
        entries[i] = LeaderboardEntry(
          username: entries[i].username,
          xp: entries[i].xp,
          rank: entries[i].rank + 1,
          winRate: entries[i].winRate,
          avatarUrl: entries[i].avatarUrl,
          totalTrades: entries[i].totalTrades,
        );
      }
    }

    return entries;
  }
}