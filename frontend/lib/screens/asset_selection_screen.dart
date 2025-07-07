import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme/street_cred_theme.dart';
import '../providers/ink_provider.dart';
import '../providers/xp_provider.dart';

class AssetSelectionScreen extends ConsumerWidget {
  const AssetSelectionScreen({Key? key}) : super(key: key);

  // Simplified 3 assets for prototype V0
  static const List<Map<String, dynamic>> assets = [
    {
      'symbol': 'BTC',
      'name': 'Bitcoin',
      'pair': 'BTC-USDT',
      'icon': Icons.currency_bitcoin,
      'color': Color(0xFFF7931A),
    },
    {
      'symbol': 'ETH', 
      'name': 'Ethereum',
      'pair': 'ETH-USDT',
      'icon': Icons.account_balance,
      'color': Color(0xFF627EEA),
    },
    {
      'symbol': 'STRK',
      'name': 'Starknet Token',
      'pair': 'STRK-USDT', 
      'icon': Icons.scatter_plot,
      'color': Color(0xFF8C8DFC),
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentInk = ref.watch(inkProvider);
    final currentXP = ref.watch(xpProvider);
    final level = (currentXP / 100).floor() + 1;
    final xpProgress = (currentXP % 100) / 100;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A1A), // Dark night sky
              Color(0xFF1A1A2E), // Deep purple
              Color(0xFF16213E), // Darker blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Rain effect overlay
            Positioned.fill(
              child: CustomPaint(
                painter: RainPainter(),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  // Header with Hong Kong styling
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Title with neon glow
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFFFF0080),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF0080).withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            'SELECT YOUR CANVAS',
                            style: TextStyle(
                              color: Color(0xFFFF0080),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Color(0xFFFF0080),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '中環金融區 • CENTRAL DISTRICT',
                          style: TextStyle(
                            color: Color(0xFF00FFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status bar
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF00FFFF).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusItem('INK', '$currentInk', Color(0xFFFFFF00)),
                        _buildStatusItem('LEVEL', '$level', Color(0xFF00FF41)),
                        _buildStatusItem('XP', '$currentXP', Color(0xFF00FFFF)),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // XP Progress bar
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LEVEL $level PROGRESS',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '${(xpProgress * 100).toInt()}%',
                              style: TextStyle(
                                color: Color(0xFF00FF41),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: xpProgress,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF41)),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),

                  // Asset selection grid
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 2.5,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: assets.length,
                        itemBuilder: (context, index) {
                          final asset = assets[index];
                          return _buildAssetCard(context, asset, ref);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: color,
                blurRadius: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard(BuildContext context, Map<String, dynamic> asset, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // Navigate to trading screen with selected asset
        context.push('/trade/${asset['pair']}');
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              asset['color'].withOpacity(0.3),
              asset['color'].withOpacity(0.1),
              Colors.black.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: asset['color'].withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: asset['color'].withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              // Asset icon
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: asset['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  asset['icon'],
                  color: asset['color'],
                  size: 32,
                ),
              ),
              
              SizedBox(width: 20),
              
              // Asset info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      asset['symbol'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      asset['name'],
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      asset['pair'],
                      style: TextStyle(
                        color: asset['color'],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Spray can icon
              Icon(
                Icons.format_paint,
                color: Color(0xFFFF0080),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF00FFFF).withOpacity(0.2)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final random = DateTime.now().millisecondsSinceEpoch ~/ 200;
    
    // Draw rain drops
    for (int i = 0; i < 50; i++) {
      final seed = random + i;
      final x = (seed * 1234567) % size.width.toInt();
      final y = (seed * 7654321) % size.height.toInt();
      final length = 10 + (seed % 15);
      
      canvas.drawLine(
        Offset(x.toDouble(), y.toDouble()),
        Offset(x + 2.0, y + length.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}