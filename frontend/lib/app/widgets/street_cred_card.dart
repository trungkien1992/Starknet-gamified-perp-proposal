import 'package:flutter/material.dart';
import '../theme/street_cred_design_system.dart';

enum CardSize { small, medium, large }

class StreetCredCard extends StatefulWidget {
  final Widget child;
  final Color themeColor;
  final CardSize size;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool enablePressEffect;
  final EdgeInsets? padding;
  final bool isSecondary;

  const StreetCredCard({
    Key? key,
    required this.child,
    required this.themeColor,
    this.size = CardSize.medium,
    this.isSelected = false,
    this.onTap,
    this.enablePressEffect = true,
    this.padding,
    this.isSecondary = false,
  }) : super(key: key);

  @override
  State<StreetCredCard> createState() => _StreetCredCardState();
}

class _StreetCredCardState extends State<StreetCredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      duration: StreetCredDesignSystem.animationFast,
      vsync: this,
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  double _getCardScale() {
    switch (widget.size) {
      case CardSize.small:
        return 0.8;
      case CardSize.medium:
        return widget.isSelected ? 1.0 : 0.9;
      case CardSize.large:
        return widget.isSelected ? 1.0 : 0.85;
    }
  }

  EdgeInsets _getDefaultPadding() {
    switch (widget.size) {
      case CardSize.small:
        return const EdgeInsets.all(StreetCredDesignSystem.spacingL);
      case CardSize.medium:
        return const EdgeInsets.all(StreetCredDesignSystem.spacingXL);
      case CardSize.large:
        return const EdgeInsets.all(StreetCredDesignSystem.spacingXXL);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pressAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _getCardScale() * _pressAnimation.value,
          child: GestureDetector(
            onTapDown: widget.enablePressEffect
                ? (_) {
                    setState(() => _isPressed = true);
                    _pressController.forward();
                  }
                : null,
            onTapUp: widget.enablePressEffect
                ? (_) {
                    setState(() => _isPressed = false);
                    _pressController.reverse();
                    widget.onTap?.call();
                  }
                : null,
            onTapCancel: widget.enablePressEffect
                ? () {
                    setState(() => _isPressed = false);
                    _pressController.reverse();
                  }
                : null,
            onTap: widget.enablePressEffect ? null : widget.onTap,
            child: AnimatedContainer(
              duration: StreetCredDesignSystem.animationMedium,
              padding: widget.padding ?? _getDefaultPadding(),
              decoration: widget.isSecondary
                  ? StreetCredDesignSystem.secondaryCardDecoration(
                      widget.themeColor,
                    )
                  : StreetCredDesignSystem.cardDecoration(
                      themeColor: widget.themeColor,
                      isSelected: widget.isSelected,
                      isPressed: _isPressed,
                    ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
