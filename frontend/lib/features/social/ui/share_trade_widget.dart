import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../models/meme_models.dart';
import '../providers/social_providers.dart';
import '../services/social_share_service.dart';

class ShareTradeWidget extends ConsumerStatefulWidget {
  final TradeOutcome tradeOutcome;
  final VoidCallback? onDismiss;

  const ShareTradeWidget({
    Key? key,
    required this.tradeOutcome,
    this.onDismiss,
  }) : super(key: key);

  @override
  ConsumerState<ShareTradeWidget> createState() => _ShareTradeWidgetState();
}

class _ShareTradeWidgetState extends ConsumerState<ShareTradeWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viralPotential = ref.watch(viralPotentialProvider(widget.tradeOutcome));
    final suggestedTemplates = ref.watch(suggestedMemeTemplatesProvider(widget.tradeOutcome));
    final autoSuggest = ref.watch(autoSuggestShareProvider(widget.tradeOutcome));

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              StreetCredTheme.neonPink.withValues(alpha: 0.2),
              StreetCredTheme.neonBlue.withValues(alpha: 0.2),
              StreetCredTheme.darkGrey,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: viralPotential > 0.7 
                ? StreetCredTheme.neonPink 
                : StreetCredTheme.neonBlue,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (viralPotential > 0.7 
                  ? StreetCredTheme.neonPink 
                  : StreetCredTheme.neonBlue).withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Icon(
                          autoSuggest ? Icons.whatshot : Icons.share,
                          color: autoSuggest 
                              ? StreetCredTheme.neonPink 
                              : StreetCredTheme.neonBlue,
                          size: 24,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          autoSuggest ? 'VIRAL TRADE ALERT!' : 'SHARE YOUR TRADE',
                          style: StreetCredDesignSystem.subtitleStyle(
                            autoSuggest 
                                ? StreetCredTheme.neonPink 
                                : StreetCredTheme.neonBlue,
                          ).copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          autoSuggest 
                              ? 'This trade has viral potential!' 
                              : 'Turn your trade into street art',
                          style: StreetCredDesignSystem.captionStyle().copyWith(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onDismiss,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Viral potential indicator
              if (viralPotential > 0.5) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getViralColor(viralPotential).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getViralColor(viralPotential),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getViralIcon(viralPotential),
                        color: _getViralColor(viralPotential),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(viralPotential * 100).toInt()}% Viral Potential',
                        style: StreetCredDesignSystem.captionStyle().copyWith(
                          color: _getViralColor(viralPotential),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Template selection
              Text(
                'Choose Your Meme Style',
                style: StreetCredDesignSystem.bodyStyle().copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),

              // Template grid
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestedTemplates.length,
                  itemBuilder: (context, index) {
                    final template = suggestedTemplates[index];
                    final config = MemeConfig.forTemplate(template, widget.tradeOutcome);
                    final isPrimary = index == 0;
                    
                    return Container(
                      margin: EdgeInsets.only(right: index < suggestedTemplates.length - 1 ? 12 : 0),
                      child: _buildTemplateOption(template, config, isPrimary),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildShareButton(
                      'QUICK SHARE',
                      Icons.flash_on,
                      StreetCredTheme.neonGreen,
                      () => _quickShare(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShareButton(
                      'CUSTOMIZE',
                      Icons.edit,
                      StreetCredTheme.neonBlue,
                      () => _customizeShare(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateOption(MemeTemplate template, MemeConfig config, bool isPrimary) {
    return GestureDetector(
      onTap: () => _shareWithTemplate(template),
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              config.primaryColor.withValues(alpha: 0.6),
              config.accentColor.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? StreetCredTheme.neonYellow : config.primaryColor,
            width: isPrimary ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getTemplateEmoji(template),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              _getTemplateShortName(template),
              style: StreetCredDesignSystem.captionStyle().copyWith(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            if (isPrimary) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: StreetCredTheme.neonYellow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'BEST',
                  style: TextStyle(
                    fontSize: 6,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: StreetCredDesignSystem.bodyStyle().copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getViralColor(double potential) {
    if (potential > 0.8) return StreetCredTheme.neonPink;
    if (potential > 0.6) return StreetCredTheme.neonYellow;
    return StreetCredTheme.neonGreen;
  }

  IconData _getViralIcon(double potential) {
    if (potential > 0.8) return Icons.local_fire_department;
    if (potential > 0.6) return Icons.trending_up;
    return Icons.thumb_up;
  }

  String _getTemplateEmoji(MemeTemplate template) {
    switch (template) {
      case MemeTemplate.bigWin: return '🚀';
      case MemeTemplate.bigLoss: return '💀';
      case MemeTemplate.streak: return '🔥';
      case MemeTemplate.territoryConquest: return '🏆';
      case MemeTemplate.diamondHands: return '💎';
      case MemeTemplate.paperHands: return '🧻';
      case MemeTemplate.firstTrade: return '🎯';
    }
  }

  String _getTemplateShortName(MemeTemplate template) {
    switch (template) {
      case MemeTemplate.bigWin: return 'BIG WIN';
      case MemeTemplate.bigLoss: return 'RIP';
      case MemeTemplate.streak: return 'STREAK';
      case MemeTemplate.territoryConquest: return 'TERRITORY';
      case MemeTemplate.diamondHands: return 'DIAMOND';
      case MemeTemplate.paperHands: return 'PAPER';
      case MemeTemplate.firstTrade: return 'FIRST';
    }
  }

  void _quickShare() {
    final socialShareService = ref.read(socialShareServiceProvider);
    socialShareService.shareTradeOutcome(context, widget.tradeOutcome);
    widget.onDismiss?.call();
  }

  void _customizeShare() {
    // Show template customization screen
    _showTemplateCustomization();
  }

  void _shareWithTemplate(MemeTemplate template) {
    final socialShareService = ref.read(socialShareServiceProvider);
    socialShareService.shareTradeOutcome(
      context, 
      widget.tradeOutcome, 
      template: template,
    );
    widget.onDismiss?.call();
  }

  void _showTemplateCustomization() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TemplateCustomizationSheet(
        tradeOutcome: widget.tradeOutcome,
        onShare: () => widget.onDismiss?.call(),
      ),
    );
  }
}

class _TemplateCustomizationSheet extends ConsumerWidget {
  final TradeOutcome tradeOutcome;
  final VoidCallback onShare;

  const _TemplateCustomizationSheet({
    required this.tradeOutcome,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedTemplates = ref.watch(suggestedMemeTemplatesProvider(tradeOutcome));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: StreetCredTheme.darkGrey,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'CUSTOMIZE YOUR MEME',
              style: StreetCredDesignSystem.subtitleStyle(
                StreetCredTheme.neonPink,
              ).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Template grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: MemeTemplate.values.length,
              itemBuilder: (context, index) {
                final template = MemeTemplate.values[index];
                final config = MemeConfig.forTemplate(template, tradeOutcome);
                final isRecommended = suggestedTemplates.contains(template);

                return _buildFullTemplateOption(template, config, isRecommended);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullTemplateOption(MemeTemplate template, MemeConfig config, bool isRecommended) {
    return GestureDetector(
      onTap: () {
        // Handle template selection and share
        onShare();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              config.primaryColor.withValues(alpha: 0.4),
              config.accentColor.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? StreetCredTheme.neonYellow : config.primaryColor,
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: StreetCredDesignSystem.subtitleStyle(config.primaryColor).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config.subtitle,
                    style: StreetCredDesignSystem.captionStyle().copyWith(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    config.captions.first,
                    style: StreetCredDesignSystem.captionStyle().copyWith(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.white60,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isRecommended)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: StreetCredTheme.neonYellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'HOT',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}