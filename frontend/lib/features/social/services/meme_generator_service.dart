import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/meme_models.dart';
import '../../../app/theme/street_cred_theme.dart';

class MemeGeneratorService {
  static const double _memeWidth = 400;
  static const double _memeHeight = 400;

  Future<String> generateMeme(TradeOutcome outcome, {MemeTemplate? template}) async {
    final memeTemplate = template ?? outcome.suggestedTemplate;
    final config = MemeConfig.forTemplate(memeTemplate, outcome);
    
    // Create the meme widget
    final memeWidget = _MemeWidget(
      outcome: outcome,
      config: config,
    );

    // Convert widget to image
    final imageData = await _widgetToImage(memeWidget);
    return base64Encode(imageData);
  }

  Future<ShareableContent> createShareableContent(TradeOutcome outcome, {MemeTemplate? template}) async {
    final memeTemplate = template ?? outcome.suggestedTemplate;
    final config = MemeConfig.forTemplate(memeTemplate, outcome);
    final content = ShareableContent.fromTradeOutcome(outcome, config);
    
    // Generate the meme image
    final imageData = await generateMeme(outcome, template: memeTemplate);
    
    return ShareableContent(
      imageData: imageData,
      text: content.text,
      hashtags: content.hashtags,
      url: content.url,
    );
  }

  Future<Uint8List> _widgetToImage(Widget widget) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
    
    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
    
    final RenderView renderView = RenderView(
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        devicePixelRatio: 2.0,
      ),
      view: WidgetsBinding.instance.platformDispatcher.views.first,
    );
    
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();
    
    final RenderObjectToWidgetElement<RenderBox> rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(_memeWidth, _memeHeight),
            devicePixelRatio: 2.0,
          ),
          child: widget,
        ),
      ),
    ).attachToRenderTree(buildOwner);
    
    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();
    
    final ui.Image image = await repaintBoundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
}

class _MemeWidget extends StatelessWidget {
  final TradeOutcome outcome;
  final MemeConfig config;

  const _MemeWidget({
    required this.outcome,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MemeGeneratorService._memeWidth,
      height: MemeGeneratorService._memeHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.primaryColor.withValues(alpha: 0.8),
            config.accentColor.withValues(alpha: 0.6),
            StreetCredTheme.darkGrey,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          _buildBackgroundPattern(),
          
          // Watermark
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'STREETCRED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          
          // Main content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  config.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle/Main info
                Text(
                  config.subtitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: config.accentColor,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Trade details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: config.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Asset', outcome.asset),
                      _buildDetailRow('Direction', outcome.direction),
                      _buildDetailRow('Leverage', '${outcome.leverage.toStringAsFixed(1)}x'),
                      if (outcome.territoryName != null)
                        _buildDetailRow('Territory', outcome.territoryName!),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Caption
                Text(
                  config.captions.first,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BackgroundPatternPainter(
          color: config.primaryColor.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: config.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  final Color color;

  _BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid pattern
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // Draw diagonal accents
    paint.strokeWidth = 2;
    for (double i = -size.width; i < size.width * 2; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}