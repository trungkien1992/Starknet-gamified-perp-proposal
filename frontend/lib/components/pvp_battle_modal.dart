import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';

enum BattlePhase {
  setup,
  countdown,
  battle,
  victory,
  defeat,
}

class PvpBattleModal extends StatefulWidget {
  final double userPnL;
  final String userName;
  final int userXp;
  final String? userAvatar;
  final VoidCallback? onVictory;
  final VoidCallback? onDefeat;
  final VoidCallback? onChallengeAgain;
  final VoidCallback? onClose;

  const PvpBattleModal({
    super.key,
    required this.userPnL,
    required this.userName,
    required this.userXp,
    this.userAvatar,
    this.onVictory,
    this.onDefeat,
    this.onChallengeAgain,
    this.onClose,
  });

  @override
  State<PvpBattleModal> createState() => _PvpBattleModalState();
}

class _PvpBattleModalState extends State<PvpBattleModal>
    with TickerProviderStateMixin {
  late AnimationController _setupController;
  late AnimationController _countdownController;
  late AnimationController _battleController;
  late AnimationController _resultController;
  late AnimationController _confettiController;
  late AnimationController _grayscaleController;

  late Animation<double> _setupAnimation;
  late Animation<double> _countdownAnimation;
  late Animation<double> _battleAnimation;
  late Animation<double> _resultAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _grayscaleAnimation;

  BattlePhase _currentPhase = BattlePhase.setup;
  int _countdownNumber = 3;
  String _botName = '';
  double _botPnL = 0.0;
  bool _userWon = false;
  List<ConfettiParticle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateBotOpponent();
    _startBattle();
  }

  void _initializeAnimations() {
    _setupController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _battleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _grayscaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _setupAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _setupController,
      curve: Curves.elasticOut,
    ));

    _countdownAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.linear,
    ));

    _battleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _battleController,
      curve: Curves.easeInOut,
    ));

    _resultAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    ));

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));

    _grayscaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _grayscaleController,
      curve: Curves.easeInOut,
    ));
  }

  void _generateBotOpponent() {
    final botNames = [
      'CryptoPunk',
      'DeFiMaster',
      'LeverageKing',
      'BullishBot',
      'BearSlayer',
      'MoonShot',
      'DiamondHands',
      'PumpBot',
      'RektHunter',
      'AlphaSeeker',
    ];

    _botName = botNames[math.Random().nextInt(botNames.length)];
    
    // Generate bot PnL with slight bias towards making it competitive
    final random = math.Random();
    _botPnL = (random.nextGaussian() * 5.0 + (widget.userPnL * 0.3));
    _botPnL = double.parse(_botPnL.toStringAsFixed(2));
    
    _userWon = widget.userPnL > _botPnL;
  }

  void _startBattle() async {
    // Phase 1: Setup
    setState(() => _currentPhase = BattlePhase.setup);
    _setupController.forward();
    await Future.delayed(const Duration(milliseconds: 800));

    // Phase 2: Countdown
    setState(() => _currentPhase = BattlePhase.countdown);
    _countdownController.forward();
    
    // Countdown numbers
    for (int i = 3; i >= 1; i--) {
      setState(() => _countdownNumber = i);
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 800));
    }
    
    await Future.delayed(const Duration(milliseconds: 400));

    // Phase 3: Battle
    setState(() => _currentPhase = BattlePhase.battle);
    _battleController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));

    // Phase 4: Result
    if (_userWon) {
      setState(() => _currentPhase = BattlePhase.victory);
      _generateConfetti();
      _confettiController.forward();
      HapticFeedback.heavyImpact();
      widget.onVictory?.call();
    } else {
      setState(() => _currentPhase = BattlePhase.defeat);
      _grayscaleController.forward();
      HapticFeedback.lightImpact();
      widget.onDefeat?.call();
    }
    
    _resultController.forward();
  }

  void _generateConfetti() {
    _confettiParticles = List.generate(40, (index) {
      return ConfettiParticle(
        position: Offset(0, 0),
        velocity: Offset(
          (math.Random().nextDouble() - 0.5) * 400,
          -math.Random().nextDouble() * 200 - 100,
        ),
        color: _getRandomConfettiColor(),
        size: math.Random().nextDouble() * 8 + 4,
        rotation: math.Random().nextDouble() * math.pi * 2,
        rotationSpeed: (math.Random().nextDouble() - 0.5) * 10,
      );
    });
  }

  Color _getRandomConfettiColor() {
    final colors = [
      Colors.yellow,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.cyan,
      Colors.lime,
      Colors.red,
      Colors.blue,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  @override
  void dispose() {
    _setupController.dispose();
    _countdownController.dispose();
    _battleController.dispose();
    _resultController.dispose();
    _confettiController.dispose();
    _grayscaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _setupController,
        _countdownController,
        _battleController,
        _resultController,
        _confettiController,
        _grayscaleController,
      ]),
      builder: (context, child) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Backdrop
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.8),
                ),
              ),

              // Grayscale overlay for defeat
              if (_currentPhase == BattlePhase.defeat)
                AnimatedBuilder(
                  animation: _grayscaleAnimation,
                  builder: (context, child) {
                    return Container(
                      color: Colors.grey.withValues(alpha: 0.3 * _grayscaleAnimation.value),
                    );
                  },
                ),

              // Confetti layer
              if (_confettiParticles.isNotEmpty)
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: ConfettiPainter(
                    particles: _confettiParticles,
                    animation: _confettiAnimation,
                  ),
                ),

              // Main content
              Center(
                child: Container(
                  width: 350,
                  height: 500,
                  margin: const EdgeInsets.all(20),
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
                      color: _userWon ? Colors.green : Colors.red,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_userWon ? Colors.green : Colors.red).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: _buildCurrentPhaseContent(),
                ),
              ),

              // Close button
              Positioned(
                top: 50,
                right: 20,
                child: IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white70, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentPhaseContent() {
    switch (_currentPhase) {
      case BattlePhase.setup:
        return _buildSetupPhase();
      case BattlePhase.countdown:
        return _buildCountdownPhase();
      case BattlePhase.battle:
        return _buildBattlePhase();
      case BattlePhase.victory:
      case BattlePhase.defeat:
        return _buildResultPhase();
    }
  }

  Widget _buildSetupPhase() {
    return Transform.scale(
      scale: _setupAnimation.value,
      child: Opacity(
        opacity: _setupAnimation.value,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PVP BATTLE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildVSLayout(),
            const SizedBox(height: 40),
            const Text(
              'Get Ready!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildVSLayout(),
        const SizedBox(height: 60),
        Transform.scale(
          scale: 1.0 + (math.sin(_countdownAnimation.value * math.pi * 6) * 0.2),
          child: Text(
            _countdownNumber > 0 ? _countdownNumber.toString() : 'GO!',
            style: TextStyle(
              color: _countdownNumber > 0 ? Colors.orange : Colors.green,
              fontSize: 80,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBattlePhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildVSLayout(),
        const SizedBox(height: 60),
        Transform.scale(
          scale: 1.0 + (math.sin(_battleAnimation.value * math.pi * 4) * 0.1),
          child: const Text(
            'TRADING!',
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultPhase() {
    return Transform.scale(
      scale: _resultAnimation.value,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildVSLayout(),
          const SizedBox(height: 40),
          
          // Result text
          Text(
            _userWon ? 'VICTORY!' : 'DEFEAT',
            style: TextStyle(
              color: _userWon ? Colors.green : Colors.red,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Reward/encouragement text
          if (_userWon) ...[
            const Text(
              'XP +30',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Great trading!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ] else ...[
            const Text(
              'Better luck next time!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
          
          const SizedBox(height: 30),
          
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.onChallengeAgain != null)
                ElevatedButton(
                  onPressed: widget.onChallengeAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Challenge Again'),
                ),
              
              ElevatedButton(
                onPressed: widget.onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVSLayout() {
    return Row(
      children: [
        // User side
        Expanded(
          child: _buildPlayerCard(
            name: widget.userName,
            pnl: widget.userPnL,
            xp: widget.userXp,
            isUser: true,
          ),
        ),
        
        // VS separator
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.purple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        // Bot side
        Expanded(
          child: _buildPlayerCard(
            name: _botName,
            pnl: _botPnL,
            xp: math.Random().nextInt(200) + 50,
            isUser: false,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard({
    required String name,
    required double pnl,
    required int xp,
    required bool isUser,
  }) {
    final pnlColor = pnl >= 0 ? Colors.green : Colors.red;
    final pnlText = pnl >= 0 ? '+${pnl.toStringAsFixed(2)}%' : '${pnl.toStringAsFixed(2)}%';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUser ? Colors.blue : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: isUser ? Colors.blue : Colors.orange,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Name
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // PnL
          Text(
            pnlText,
            style: TextStyle(
              color: pnlColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // XP
          Text(
            '${xp} XP',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiParticle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final Animation<double> animation;

  ConfettiPainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (var particle in particles) {
      final progress = animation.value;
      final x = centerX + particle.position.dx + (particle.velocity.dx * progress);
      final y = centerY + particle.position.dy + (particle.velocity.dy * progress) + (200 * progress * progress);

      if (x < -50 || x > size.width + 50 || y > size.height + 50) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + (particle.rotationSpeed * progress));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size),
          Radius.circular(particle.size / 4),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Extension for gaussian random
extension on math.Random {
  double nextGaussian() {
    double u = 0, v = 0;
    while (u == 0) u = nextDouble();
    while (v == 0) v = nextDouble();
    return math.sqrt(-2.0 * math.log(u)) * math.cos(2.0 * math.pi * v);
  }
}