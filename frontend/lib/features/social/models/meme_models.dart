import 'package:flutter/material.dart';

enum MemeTemplate {
  bigWin,
  bigLoss,
  streak,
  firstTrade,
  territoryConquest,
  diamondHands,
  paperHands,
}

enum SharePlatform {
  twitter,
  telegram,
  discord,
  instagram,
  tiktok,
  copy,
}

class TradeOutcome {
  final String direction; // 'LONG' or 'SHORT'
  final double leverage;
  final double pnl;
  final String asset;
  final DateTime timestamp;
  final String? territoryName;
  final bool isWin;
  final double? streakDays;
  final int? consecutiveWins;

  TradeOutcome({
    required this.direction,
    required this.leverage,
    required this.pnl,
    required this.asset,
    required this.timestamp,
    this.territoryName,
    required this.isWin,
    this.streakDays,
    this.consecutiveWins,
  });

  MemeTemplate get suggestedTemplate {
    if (streakDays != null && streakDays! >= 5) return MemeTemplate.streak;
    if (consecutiveWins != null && consecutiveWins! >= 3) return MemeTemplate.diamondHands;
    if (territoryName != null) return MemeTemplate.territoryConquest;
    if (pnl.abs() > 1000) {
      return isWin ? MemeTemplate.bigWin : MemeTemplate.bigLoss;
    }
    if (!isWin && pnl < -100) return MemeTemplate.paperHands;
    return MemeTemplate.firstTrade;
  }
}

class MemeConfig {
  final MemeTemplate template;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color accentColor;
  final String backgroundAsset;
  final List<String> captions;

  MemeConfig({
    required this.template,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundAsset,
    required this.captions,
  });

  static MemeConfig forTemplate(MemeTemplate template, TradeOutcome outcome) {
    switch (template) {
      case MemeTemplate.bigWin:
        return MemeConfig(
          template: template,
          title: '🚀 MOON SHOT',
          subtitle: '+${outcome.pnl.toStringAsFixed(0)}% ${outcome.direction}',
          primaryColor: const Color(0xFF00FF41), // Neon green
          accentColor: const Color(0xFFFFD700), // Gold
          backgroundAsset: 'moon_bg',
          captions: [
            'Diamond hands paying off 💎',
            'To the moon! 🚀',
            'Street cred through the roof',
            'This is the way',
          ],
        );

      case MemeTemplate.bigLoss:
        return MemeConfig(
          template: template,
          title: '💀 RIP PORTFOLIO',
          subtitle: '${outcome.pnl.toStringAsFixed(0)}% ${outcome.direction}',
          primaryColor: const Color(0xFFFF0080), // Neon pink
          accentColor: const Color(0xFFFF4444), // Red
          backgroundAsset: 'rip_bg',
          captions: [
            'Paper hands strike again 🧻',
            'Buy high, sell low 📉',
            'It was a calculated risk...',
            'Back to the streets',
          ],
        );

      case MemeTemplate.streak:
        return MemeConfig(
          template: template,
          title: '🔥 ON FIRE',
          subtitle: '${outcome.streakDays?.toInt() ?? 0} day streak',
          primaryColor: const Color(0xFFFF4500), // Orange
          accentColor: const Color(0xFFFFD700), // Gold
          backgroundAsset: 'fire_bg',
          captions: [
            'Unstoppable force 🔥',
            'Street legend in the making',
            'Can\'t touch this',
            'Fire emoji chain',
          ],
        );

      case MemeTemplate.territoryConquest:
        return MemeConfig(
          template: template,
          title: '🏆 TERRITORY OWNED',
          subtitle: outcome.territoryName ?? 'Hong Kong District',
          primaryColor: const Color(0xFF8A2BE2), // Purple
          accentColor: const Color(0xFFFFD700), // Gold
          backgroundAsset: 'conquest_bg',
          captions: [
            'New territory unlocked 🗺️',
            'Street art master',
            'Hong Kong is mine',
            'Legendary status achieved',
          ],
        );

      case MemeTemplate.diamondHands:
        return MemeConfig(
          template: template,
          title: '💎 DIAMOND HANDS',
          subtitle: '${outcome.consecutiveWins ?? 0} wins in a row',
          primaryColor: const Color(0xFF00FFFF), // Cyan
          accentColor: const Color(0xFFFFFFFF), // White
          backgroundAsset: 'diamond_bg',
          captions: [
            'Pressure makes diamonds 💎',
            'Steady hands, steady gains',
            'Built different',
            'Diamond status unlocked',
          ],
        );

      case MemeTemplate.paperHands:
        return MemeConfig(
          template: template,
          title: '🧻 PAPER HANDS',
          subtitle: 'Sold too early',
          primaryColor: const Color(0xFF888888), // Gray
          accentColor: const Color(0xFFFFFFFF), // White
          backgroundAsset: 'paper_bg',
          captions: [
            'Weak hands, weak gains 🧻',
            'Shoulda held longer',
            'Lesson learned',
            'Back to practice mode',
          ],
        );

      case MemeTemplate.firstTrade:
        return MemeConfig(
          template: template,
          title: '🎯 FIRST BLOOD',
          subtitle: 'Welcome to the streets',
          primaryColor: const Color(0xFF00FF41), // Neon green
          accentColor: const Color(0xFFFF0080), // Neon pink
          backgroundAsset: 'welcome_bg',
          captions: [
            'Fresh meat on the streets 🥩',
            'Journey begins now',
            'Tag your first trade',
            'Street cred: initiated',
          ],
        );
    }
  }
}

class ShareableContent {
  final String imageData; // Base64 encoded image
  final String text;
  final List<String> hashtags;
  final String? url;

  ShareableContent({
    required this.imageData,
    required this.text,
    required this.hashtags,
    this.url,
  });

  String get formattedText {
    final hashtagString = hashtags.map((tag) => '#$tag').join(' ');
    return '$text\n\n$hashtagString${url != null ? '\n\n$url' : ''}';
  }

  static ShareableContent fromTradeOutcome(TradeOutcome outcome, MemeConfig config) {
    final hashtags = [
      'StreetCredClash',
      'DeFiArt',
      'HongKongTrading',
      'StreetCred',
      outcome.direction.toLowerCase(),
      if (outcome.isWin) 'win' else 'loss',
      if (outcome.territoryName != null) 'territory',
    ];

    final text = _generateShareText(outcome, config);

    return ShareableContent(
      imageData: '', // Will be populated by meme generator
      text: text,
      hashtags: hashtags,
      url: 'https://streetcredclash.app', // App store link
    );
  }

  static String _generateShareText(TradeOutcome outcome, MemeConfig config) {
    final emojis = {
      MemeTemplate.bigWin: '🚀💎🌙',
      MemeTemplate.bigLoss: '💀📉🧻',
      MemeTemplate.streak: '🔥⚡️🎯',
      MemeTemplate.territoryConquest: '🏆🗺️👑',
      MemeTemplate.diamondHands: '💎🙌✨',
      MemeTemplate.paperHands: '🧻😅📚',
      MemeTemplate.firstTrade: '🎯🔥💫',
    };

    final emoji = emojis[config.template] ?? '🎮';
    final pnlText = outcome.isWin ? '+${outcome.pnl.toStringAsFixed(1)}%' : '${outcome.pnl.toStringAsFixed(1)}%';
    
    return '$emoji ${config.title}\n\n'
           '${outcome.asset} ${outcome.direction} x${outcome.leverage.toStringAsFixed(1)}\n'
           'P&L: $pnlText\n\n'
           '${config.captions.first}\n\n'
           'Join the street art revolution!';
  }
}