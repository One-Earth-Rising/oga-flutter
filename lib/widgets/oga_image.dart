// ═══════════════════════════════════════════════════════════════════
// OGA IMAGE WIDGET
// Reusable network image with Heimdal-themed loading/error states.
// Resolves relative Storage paths via OgaStorage.resolve().
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../config/oga_storage.dart';

class OgaImage extends StatelessWidget {
  /// Image path — either relative storage path or full URL.
  final String path;

  /// How to inscribe the image into the space.
  final BoxFit fit;

  /// Border radius for clipping.
  final BorderRadius? borderRadius;

  /// Fixed width (optional).
  final double? width;

  /// Fixed height (optional).
  final double? height;

  /// Fallback icon shown on error.
  final IconData fallbackIcon;

  /// Fallback icon size.
  final double fallbackIconSize;

  /// Optional color tint for the loading/error gradient.
  final Color? accentColor;

  const OgaImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackIconSize = 32,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final url = OgaStorage.resolve(path);
    final radius = borderRadius ?? BorderRadius.zero;
    final tint = accentColor ?? const Color(0xFF39FF14);

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final progress = loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
              : null;
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tint.withValues(alpha: 0.1), const Color(0xFF121212)],
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: progress,
                  color: tint.withValues(alpha: 0.5),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tint.withValues(alpha: 0.15), const Color(0xFF121212)],
              ),
            ),
            child: Center(
              child: Icon(
                fallbackIcon,
                color: Colors.white.withValues(alpha: 0.2),
                size: fallbackIconSize,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Circular avatar variant for ownership history etc.
class OgaAvatarImage extends StatelessWidget {
  final String? url;
  final double size;
  final String fallbackLetter;
  final Color borderColor;
  final double borderWidth;

  const OgaAvatarImage({
    super.key,
    this.url,
    this.size = 32,
    this.fallbackLetter = '?',
    this.borderColor = const Color(0xFF2C2C2C),
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2C2C2C),
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? Image.network(
                OgaStorage.resolve(url!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        fallbackLetter.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
