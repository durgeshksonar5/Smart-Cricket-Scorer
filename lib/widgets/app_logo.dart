import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool compact;
  final Color? textColor;

  const AppLogo({
    super.key,
    this.size = 40.0,
    this.showText = true,
    this.compact = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: Image.asset(
          'assets/branding/app-icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppTheme.cardBg,
              child: Icon(Icons.sports_cricket, size: size * 0.6, color: AppTheme.primaryEmerald),
            );
          },
        ),
      ),
    );

    if (!showText) return iconWidget;

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 6),
          Text(
            'Cricket Scorer',
            style: GoogleFonts.poppins(
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        SizedBox(width: size * 0.28),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Cricket ',
                style: GoogleFonts.poppins(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w900,
                  color: textColor ?? Colors.white,
                  letterSpacing: 0.5,
                ),
                children: const [
                  TextSpan(
                    text: 'Scorer',
                    style: TextStyle(
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'PRO SCORING',
              style: GoogleFonts.poppins(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w700,
                color: AppTheme.coinGold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
