import 'package:flutter/material.dart';

/// KiryanaAI Brand Color Palette
/// All colors are sourced from the Figma design spec.
/// Never use raw color values in UI — always reference from here.
abstract class AppColors {
  // ── Primary Brand ───────────────────────────────────────────────
  static const Color primary = Color(0xFF00464A);       // Main theme color
  static const Color primaryLight = Color(0xFF00636A);
  static const Color primaryDark = Color(0xFF002E31);

  // ── Action / Button ─────────────────────────────────────────────
  static const Color actionGreen = Color(0xFF1B6D24);   // Button color
  static const Color actionGreenLight = Color(0xFF2A8D35);
  static const Color actionGreenDark = Color(0xFF124D19);

  // ── Secondary ───────────────────────────────────────────────────
  static const Color secondary = Color(0xFFE8EFF2);     // Pagination inactive
  static const Color secondaryDark = Color(0xFFCFD8DC);

  // ── Neutrals ────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8FAFB);
  static const Color surface = Color(0xFFF2F6F8);
  static const Color border = Color(0xFFE0E7EA);

  // ── Text ────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5C6B70);
  static const Color textHint = Color(0xFF9EADB5);

  // ── Semantic ────────────────────────────────────────────────────
  static const Color success = Color(0xFF1B6D24);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF0277BD);

  // ── Dark Theme ──────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A1A1C);
  static const Color darkSurface = Color(0xFF132224);
  static const Color darkCard = Color(0xFF1A2E31);
  static const Color darkBorder = Color(0xFF2A4448);
  static const Color darkTextPrimary = Color(0xFFF0F6F8);
  static const Color darkTextSecondary = Color(0xFF8CADB5);

  // ── Profit/Loss Indicators ──────────────────────────────────────
  static const Color profit = Color(0xFF1B6D24);
  static const Color loss = Color(0xFFD32F2F);
  static const Color neutral = Color(0xFF5C6B70);
}
