import 'package:flutter/material.dart';

class TransactionItemVisual {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String? emoji;

  const TransactionItemVisual({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.emoji,
  });
}

String toTitleCase(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        if (word.length == 1) return word.toUpperCase();
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      })
      .join(' ');
}

TransactionItemVisual visualForTransaction({
  required String titleEnglish,
  required bool isSale,
}) {
  final title = titleEnglish.toLowerCase();

  if (title.contains('atta') || title.contains('flour') || title.contains('maida')) {
    return const TransactionItemVisual(
      emoji: '🌾',
      icon: Icons.grain_rounded,
      backgroundColor: Color(0xFFFFF3E0),
      iconColor: Color(0xFFE65100),
    );
  }
  if (title.contains('chawal') ||
      title.contains('rice') ||
      title.contains('basmati')) {
    return const TransactionItemVisual(
      emoji: '🍚',
      icon: Icons.rice_bowl_rounded,
      backgroundColor: Color(0xFFF3E5F5),
      iconColor: Color(0xFF6A1B9A),
    );
  }
  if (title.contains('cheeni') ||
      title.contains('sugar') ||
      title.contains('gur')) {
    return const TransactionItemVisual(
      emoji: '🧂',
      icon: Icons.cookie_rounded,
      backgroundColor: Color(0xFFE8F5E9),
      iconColor: Color(0xFF2E7D32),
    );
  }
  if (title.contains('doodh') ||
      title.contains('milk') ||
      title.contains('egg') ||
      title.contains('anda')) {
    return const TransactionItemVisual(
      emoji: '🥛',
      icon: Icons.egg_alt_rounded,
      backgroundColor: Color(0xFFE3F2FD),
      iconColor: Color(0xFF1565C0),
    );
  }
  if (title.contains('tel') ||
      title.contains('oil') ||
      title.contains('ghee')) {
    return const TransactionItemVisual(
      emoji: '🛢️',
      icon: Icons.water_drop_rounded,
      backgroundColor: Color(0xFFFFFDE7),
      iconColor: Color(0xFFF9A825),
    );
  }
  if (title.contains('chai') ||
      title.contains('tea') ||
      title.contains('coffee')) {
    return const TransactionItemVisual(
      emoji: '☕',
      icon: Icons.local_cafe_rounded,
      backgroundColor: Color(0xFFEFEBE9),
      iconColor: Color(0xFF4E342E),
    );
  }
  if (title.contains('biscuit') ||
      title.contains('snack') ||
      title.contains('chips')) {
    return const TransactionItemVisual(
      emoji: '🍪',
      icon: Icons.cookie_outlined,
      backgroundColor: Color(0xFFFFEBEE),
      iconColor: Color(0xFFC62828),
    );
  }
  if (title.contains('bill') ||
      title.contains('electric') ||
      title.contains('bijli') ||
      title.contains('water')) {
    return const TransactionItemVisual(
      emoji: '⚡',
      icon: Icons.bolt_rounded,
      backgroundColor: Color(0xFFFFF8E1),
      iconColor: Color(0xFFFF8F00),
    );
  }
  if (title.contains('rent') ||
      title.contains('kiraya') ||
      title.contains('shop')) {
    return const TransactionItemVisual(
      emoji: '🏪',
      icon: Icons.storefront_rounded,
      backgroundColor: Color(0xFFECEFF1),
      iconColor: Color(0xFF455A64),
    );
  }
  if (title.contains('transport') ||
      title.contains('delivery') ||
      title.contains('fuel')) {
    return const TransactionItemVisual(
      emoji: '🚚',
      icon: Icons.local_shipping_rounded,
      backgroundColor: Color(0xFFE0F7FA),
      iconColor: Color(0xFF00838F),
    );
  }

  if (isSale) {
    return const TransactionItemVisual(
      emoji: '🛒',
      icon: Icons.shopping_basket_rounded,
      backgroundColor: Color(0xFFE8F5E9),
      iconColor: Color(0xFF1B6D24),
    );
  }
  return const TransactionItemVisual(
    emoji: '📋',
    icon: Icons.receipt_long_rounded,
    backgroundColor: Color(0xFFFFEBEE),
    iconColor: Color(0xFFC62828),
  );
}
