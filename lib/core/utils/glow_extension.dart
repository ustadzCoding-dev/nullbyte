import 'package:flutter/material.dart';
import 'package:nullbyte/core/theme/app_theme.dart';

/// Extension on [Widget] untuk efek glow neon green sesuai Terminal Brutalism.
extension GlowExtension on Widget {
  /// Membungkus widget dengan [Container] yang memiliki box shadow neon green.
  /// Gunakan untuk elemen non-text seperti card, button, icon.
  Widget withPrimaryGlow({double blurRadius = 5.0, double spreadRadius = 0.0}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withValues(alpha: 0.4),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: this,
    );
  }

  /// Membungkus [Text] widget dengan text shadow neon green (phosphor bleed).
  /// Hanya efektif jika widget ini adalah [Text] atau [RichText].
  Widget withTextGlow({double blurRadius = 5.0}) {
    if (this is Text) {
      final text = this as Text;
      final existingStyle = text.style ?? const TextStyle();
      return Text(
        text.data ?? '',
        key: text.key,
        style: existingStyle.copyWith(
          shadows: [
            Shadow(
              color: AppTheme.primaryContainer.withValues(alpha: 0.8),
              blurRadius: blurRadius,
            ),
          ],
        ),
        strutStyle: text.strutStyle,
        textAlign: text.textAlign,
        textDirection: text.textDirection,
        locale: text.locale,
        softWrap: text.softWrap,
        overflow: text.overflow,
        maxLines: text.maxLines,
        semanticsLabel: text.semanticsLabel,
        textWidthBasis: text.textWidthBasis,
        textHeightBehavior: text.textHeightBehavior,
      );
    }
    // Fallback: wrap dengan DecoratedBox + ColorFiltered untuk non-Text widget
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withValues(alpha: 0.4),
            blurRadius: blurRadius,
            spreadRadius: 0,
          ),
        ],
      ),
      child: this,
    );
  }
}
