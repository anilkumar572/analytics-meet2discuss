import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color accent = Color(0xFF8B5CF6);

  // Base surfaces — a touch darker/richer than the old palette for more
  // contrast between page background and cards.
  static const Color background = Color(0xFF0B1120);
  static const Color surface = Color(0xFF141C2F);
  static const Color surfaceElevated = Color(0xFF1D2740);
  static const Color surfaceHover = Color(0xFF232E4A);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color border = Color(0xFF263153);

  /// Subtle brand-tinted radial glows used behind hero/auth surfaces.
  static const List<Color> ambientGlow = [primary, accent];
}

/// Centralized type scale so every widget renders headings/body text with the
/// same weight, size and color instead of redefining `GoogleFonts.xxx` calls
/// inline. Outfit is used for headings/emphasis, Inter for everything else.
class AppTextStyles {
  static TextStyle get pageTitle => GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get sectionTitle => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get cardLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  static TextStyle get statValue => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get tableHeader => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      );
}

class AppConstants {
  static const String supabaseUrl = 'https://yukzrudvvgpqvoqhyktz.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_sPV3YkRpZHVtMfeFpGIH3Q_qBH5L72E';
}
