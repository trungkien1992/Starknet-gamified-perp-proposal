import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meme_models.dart';
import 'meme_generator_service.dart';

class SocialShareService {
  final MemeGeneratorService _memeGenerator = MemeGeneratorService();

  Future<void> shareTradeOutcome(
    BuildContext context, 
    TradeOutcome outcome, {
    SharePlatform? platform,
    MemeTemplate? template,
  }) async {
    try {
      // Generate shareable content
      final content = await _memeGenerator.createShareableContent(outcome, template: template);
      
      if (platform == null) {
        // Show platform selection
        _showSharePlatformSelection(context, content);
      } else {
        // Share to specific platform
        await _shareToplatform(platform, content);
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to generate meme: $e');
    }
  }

  void _showSharePlatformSelection(BuildContext context, ShareableContent content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SharePlatformSheet(
        content: content,
        onPlatformSelected: (platform) async {
          Navigator.pop(context);
          await _shareToplatform(platform, content);
        },
      ),
    );
  }

  Future<void> _shareToplatform(SharePlatform platform, ShareableContent content) async {
    try {
      switch (platform) {
        case SharePlatform.twitter:
          await _shareToTwitter(content);
          break;
        case SharePlatform.telegram:
          await _shareToTelegram(content);
          break;
        case SharePlatform.discord:
          await _shareToDiscord(content);
          break;
        case SharePlatform.instagram:
          await _shareToInstagram(content);
          break;
        case SharePlatform.tiktok:
          await _shareToTikTok(content);
          break;
        case SharePlatform.copy:
          await _copyToClipboard(content);
          break;
      }
    } catch (e) {
      print('Share failed: $e');
    }
  }

  Future<void> _shareToTwitter(ShareableContent content) async {
    final encodedText = Uri.encodeComponent(content.formattedText);
    final twitterUrl = 'https://twitter.com/intent/tweet?text=$encodedText';
    
    await _launchUrl(twitterUrl);
    await _saveAndShareImage(content);
  }

  Future<void> _shareToTelegram(ShareableContent content) async {
    final encodedText = Uri.encodeComponent(content.text);
    final telegramUrl = 'https://t.me/share/url?text=$encodedText';
    
    await _launchUrl(telegramUrl);
    await _saveAndShareImage(content);
  }

  Future<void> _shareToDiscord(ShareableContent content) async {
    // Discord doesn't have direct sharing URL, so we use generic share
    await _saveAndShareImage(content);
  }

  Future<void> _shareToInstagram(ShareableContent content) async {
    // Instagram requires saving image to gallery first
    await _saveImageToGallery(content);
    
    // Try to open Instagram
    const instagramUrl = 'instagram://';
    if (await canLaunchUrl(Uri.parse(instagramUrl))) {
      await _launchUrl(instagramUrl);
    }
  }

  Future<void> _shareToTikTok(ShareableContent content) async {
    // TikTok doesn't have direct sharing, save image for manual upload
    await _saveImageToGallery(content);
    
    // Try to open TikTok
    const tiktokUrl = 'tiktok://';
    if (await canLaunchUrl(Uri.parse(tiktokUrl))) {
      await _launchUrl(tiktokUrl);
    }
  }

  Future<void> _copyToClipboard(ShareableContent content) async {
    await Clipboard.setData(ClipboardData(text: content.formattedText));
    await _saveImageToGallery(content);
  }

  Future<void> _saveAndShareImage(ShareableContent content) async {
    try {
      final imageBytes = base64Decode(content.imageData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/streetcred_meme_${DateTime.now().millisecondsSinceEpoch}.png');
      
      await file.writeAsBytes(imageBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: content.formattedText,
        subject: 'StreetCred Trade Result',
      );
    } catch (e) {
      print('Failed to save and share image: $e');
    }
  }

  Future<void> _saveImageToGallery(ShareableContent content) async {
    try {
      final imageBytes = base64Decode(content.imageData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/streetcred_meme_${DateTime.now().millisecondsSinceEpoch}.png');
      
      await file.writeAsBytes(imageBytes);
      
      // Note: For production, you'd want to use image_gallery_saver or similar
      // to actually save to the device gallery
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      print('Failed to save image: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _SharePlatformSheet extends StatelessWidget {
  final ShareableContent content;
  final Function(SharePlatform) onPlatformSelected;

  const _SharePlatformSheet({
    required this.content,
    required this.onPlatformSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
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
            child: Row(
              children: [
                const Icon(
                  Icons.share,
                  color: Color(0xFF00FFFF),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'SHARE YOUR TRADE',
                  style: TextStyle(
                    color: Color(0xFF00FFFF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Platform grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildPlatformButton(
                  'Twitter',
                  Icons.alternate_email,
                  const Color(0xFF1DA1F2),
                  () => onPlatformSelected(SharePlatform.twitter),
                ),
                _buildPlatformButton(
                  'Telegram',
                  Icons.send,
                  const Color(0xFF0088CC),
                  () => onPlatformSelected(SharePlatform.telegram),
                ),
                _buildPlatformButton(
                  'Discord',
                  Icons.chat,
                  const Color(0xFF5865F2),
                  () => onPlatformSelected(SharePlatform.discord),
                ),
                _buildPlatformButton(
                  'Instagram',
                  Icons.camera_alt,
                  const Color(0xFFE4405F),
                  () => onPlatformSelected(SharePlatform.instagram),
                ),
                _buildPlatformButton(
                  'TikTok',
                  Icons.music_note,
                  const Color(0xFF000000),
                  () => onPlatformSelected(SharePlatform.tiktok),
                ),
                _buildPlatformButton(
                  'Copy',
                  Icons.copy,
                  const Color(0xFF888888),
                  () => onPlatformSelected(SharePlatform.copy),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlatformButton(
    String name,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}