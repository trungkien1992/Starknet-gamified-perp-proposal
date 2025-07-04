import 'package:flutter/material.dart';
import '../theme/street_cred_design_system.dart';
import '../../features/trade/widgets/brand_symbol.dart';

class StreetCredHeader extends StatelessWidget {
  final String title;
  final Color themeColor;
  final Widget? leadingIcon;
  final List<Widget>? actions;
  final bool showBrandSymbol;
  final String? subtitle;

  const StreetCredHeader({
    Key? key,
    required this.title,
    required this.themeColor,
    this.leadingIcon,
    this.actions,
    this.showBrandSymbol = true,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(StreetCredDesignSystem.spacingXL),
      decoration: StreetCredDesignSystem.headerDecoration(themeColor),
      child: Column(
        children: [
          if (showBrandSymbol) ...[
            BrandSymbol(size: 60, animated: true),
            const SizedBox(height: StreetCredDesignSystem.spacingL),
          ],

          Row(
            children: [
              if (leadingIcon != null) ...[
                leadingIcon!,
                const SizedBox(width: StreetCredDesignSystem.spacingM),
              ],

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: StreetCredDesignSystem.titleStyle(themeColor),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: StreetCredDesignSystem.spacingXS),
                      Text(
                        subtitle!,
                        style: StreetCredDesignSystem.captionStyle(),
                      ),
                    ],
                  ],
                ),
              ),

              if (actions != null) ...actions!,
            ],
          ),
        ],
      ),
    );
  }
}

class StreetCredAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color themeColor;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBrandSymbol;

  const StreetCredAppBar({
    Key? key,
    required this.title,
    required this.themeColor,
    this.actions,
    this.leading,
    this.showBrandSymbol = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: StreetCredDesignSystem.headerDecoration(themeColor),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: leading,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                style: StreetCredDesignSystem.titleStyle(
                  themeColor,
                ).copyWith(fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
