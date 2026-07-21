import 'package:flutter/material.dart';

/// Design tokens for FNDTV app color palette
/// 
/// Supports multiple theme variants (blue, dark) with future extensibility.
/// The blue theme is the initial default.
/// 
/// Usage:
/// ```dart
/// // Access colors via context extension
/// Container(
///   color: context.uiKitColors.bgCard,
///   child: Text(
///     'Hello',
///     style: TextStyle(color: context.uiKitColors.textPrimary),
///   ),
/// )
/// ```
/// 
/// Future theme switching:
/// To implement live theme switching, update the UiKitColors value in 
/// ThemeColorListener state and call setState. The InheritedWidget will
/// automatically notify all dependent widgets to rebuild.
class UiKitColors {
  final Color bgPrimary;
  final Color bgSurface;
  final Color bgCard;
  final Color bgCardHover;
  final Color bgHero;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textMuted;
  final Color textHint;
  final Color accent;
  final Color accentDim;
  final Color accentHover;
  final Color badgeNowBg;
  final Color badgeNowText;

  const UiKitColors({
    required this.bgPrimary,
    required this.bgSurface,
    required this.bgCard,
    required this.bgCardHover,
    required this.bgHero,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textMuted,
    required this.textHint,
    required this.accent,
    required this.accentDim,
    required this.accentHover,
    required this.badgeNowBg,
    required this.badgeNowText,
  });

  /// FNDTV brand theme - Initial default theme (light background + red accent)
  ///
  /// Background  : white / light grey — backgrounds, surfaces, cards
  /// Accent      : #A83734 (brick red) — accent, CTAs, highlights, badges
  /// Secondary   : #FFE088 (gold)      — kept for occasional secondary highlights
  ///
  /// (Enum value is still named `blue` for backwards compatibility, but the
  /// palette is the FNDTV light/red brand.)
  static const blue = UiKitColors(
    // TV-style scheme: dark navy backgrounds + red accents (blue + red).
    bgPrimary: Color(0xFF0E0F13),     // TV dark navy background
    bgSurface: Color(0xFF191B22),     // TV dark surface (nav bar / tabs)
    bgCard: Color(0xFF191B22),        // Dark card background
    bgCardHover: Color(0xFF23262F),   // Hovered/active card
    bgHero: Color(0xFF14161C),        // Hero area background
    border: Color(0xFF2A2D36),        // Subtle border
    borderStrong: Color(0xFF3B3F4A),  // Stronger border
    textPrimary: Color(0xFFF1F2F5),   // Light primary text
    textMuted: Color(0xFF9AA0AB),     // Muted light-grey text
    textHint: Color(0xFF6B7280),      // Hint text
    accent: Color(0xFFC7443F),        // Brand red (brightened for dark bg)
    accentDim: Color(0xFF4A211F),     // Dim red
    accentHover: Color(0xFFD9564F),   // Brighter red (hover/focus)
    badgeNowBg: Color(0xFFC7443F),    // Red badge background
    badgeNowText: Color(0xFFC7443F),  // Red (active nav / badge text)
  );

  /// Dark theme - Alternative theme for future use
  static const dark = UiKitColors(
    bgPrimary: Color(0xFF0A0A0A),
    bgSurface: Color(0xFF141414),
    bgCard: Color(0xFF1C1C1C),
    bgCardHover: Color(0xFF242424),
    bgHero: Color(0xFF111827),
    border: Color(0xFF2A2A2A),
    borderStrong: Color(0xFF3A3A3A),
    textPrimary: Color(0xFFF0F0F0),
    textMuted: Color(0xFF888888),
    textHint: Color(0xFF555555),
    accent: Color(0xFFFFE088),        // Gold accent (FNDTV secondary)
    accentDim: Color(0xFFC9A94E),     // Dimmed gold
    accentHover: Color(0xFFFFEBAA),   // Bright gold
    badgeNowBg: Color(0xFF2A1A1A),    // Dark badge background
    badgeNowText: Color(0xFFFFE088),  // Gold text (matches accent)
  );

  /// Copy with method for partial updates
  UiKitColors copyWith({
    Color? bgPrimary,
    Color? bgSurface,
    Color? bgCard,
    Color? bgCardHover,
    Color? bgHero,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textMuted,
    Color? textHint,
    Color? accent,
    Color? accentDim,
    Color? accentHover,
    Color? badgeNowBg,
    Color? badgeNowText,
  }) {
    return UiKitColors(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSurface: bgSurface ?? this.bgSurface,
      bgCard: bgCard ?? this.bgCard,
      bgCardHover: bgCardHover ?? this.bgCardHover,
      bgHero: bgHero ?? this.bgHero,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textHint: textHint ?? this.textHint,
      accent: accent ?? this.accent,
      accentDim: accentDim ?? this.accentDim,
      accentHover: accentHover ?? this.accentHover,
      badgeNowBg: badgeNowBg ?? this.badgeNowBg,
      badgeNowText: badgeNowText ?? this.badgeNowText,
    );
  }
}
