import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';

class AppFooter extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const AppFooter({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 18, showText: false),
            const SizedBox(width: 8),
            Text(
              'Made with ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
            const Text(
              '❤️',
              style: TextStyle(fontSize: 11),
            ),
            Text(
              ' by ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
            const Text(
              'Durgesh Sonar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.coinGold,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef MadeByFooter = AppFooter;
