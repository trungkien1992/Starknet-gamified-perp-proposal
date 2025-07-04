import 'package:flutter/material.dart';
import '../theme/street_cred_design_system.dart';

enum ButtonStyle { primary, secondary, navigation }

class StreetCredButton extends StatefulWidget {
  final String text;
  final Color themeColor;
  final VoidCallback? onPressed;
  final ButtonStyle style;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? width;
  final double? height;
  final bool isLoading;

  const StreetCredButton({
    Key? key,
    required this.text,
    required this.themeColor,
    this.onPressed,
    this.style = ButtonStyle.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<StreetCredButton> createState() => _StreetCredButtonState();
}

class _StreetCredButtonState extends State<StreetCredButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: StreetCredDesignSystem.animationGlow,
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.style == ButtonStyle.navigation) {
      return _buildNavigationButton();
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height ?? 60,
          decoration: widget.style == ButtonStyle.primary
              ? StreetCredDesignSystem.buttonDecoration(
                  themeColor: widget.themeColor,
                  glowIntensity: _glowAnimation.value,
                )
              : StreetCredDesignSystem.secondaryCardDecoration(
                  widget.themeColor,
                ),
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  StreetCredDesignSystem.radiusButton,
                ),
              ),
            ),
            child: widget.isLoading
                ? _buildLoadingContent()
                : _buildButtonContent(),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButton() {
    return Container(
      width: 50,
      height: 50,
      decoration: StreetCredDesignSystem.navigationButtonDecoration(
        widget.themeColor,
      ),
      child: IconButton(
        onPressed: widget.onPressed,
        icon: Icon(
          widget.leadingIcon ?? Icons.arrow_forward,
          color: widget.themeColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    final hasIcons = widget.leadingIcon != null || widget.trailingIcon != null;

    if (!hasIcons) {
      return Text(
        widget.text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: widget.style == ButtonStyle.primary
              ? Colors.white
              : widget.themeColor,
          letterSpacing: 1,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(
            widget.leadingIcon,
            color: widget.style == ButtonStyle.primary
                ? Colors.white
                : widget.themeColor,
            size: 20,
          ),
          const SizedBox(width: StreetCredDesignSystem.spacingM),
        ],
        Text(
          widget.text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.style == ButtonStyle.primary
                ? Colors.white
                : widget.themeColor,
            letterSpacing: 1,
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: StreetCredDesignSystem.spacingM),
          Icon(
            widget.trailingIcon,
            color: widget.style == ButtonStyle.primary
                ? Colors.white
                : widget.themeColor,
            size: 20,
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.style == ButtonStyle.primary
                  ? Colors.white
                  : widget.themeColor,
            ),
          ),
        ),
        const SizedBox(width: StreetCredDesignSystem.spacingM),
        Text(
          'Loading...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.style == ButtonStyle.primary
                ? Colors.white
                : widget.themeColor,
          ),
        ),
      ],
    );
  }
}
