import 'package:flutter/foundation.dart';

/// Represents a single transaction or log entry in the KiryanaAI system.
@immutable
class TransactionModel {
  final String id;
  final String titleUrdu;
  final String titleEnglish;
  final String tag;
  final DateTime date;
  final int amount;
  final bool isSale;
  final String iconType;

  const TransactionModel({
    required this.id,
    required this.titleUrdu,
    required this.titleEnglish,
    required this.tag,
    required this.date,
    required this.amount,
    required this.isSale,
    required this.iconType,
  });

  /// Formatted time for UI display (HH:mm AM/PM)
  String get timeString {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  TransactionModel copyWith({
    String? id,
    String? titleUrdu,
    String? titleEnglish,
    String? tag,
    DateTime? date,
    int? amount,
    bool? isSale,
    String? iconType,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      titleUrdu: titleUrdu ?? this.titleUrdu,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      tag: tag ?? this.tag,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      isSale: isSale ?? this.isSale,
      iconType: iconType ?? this.iconType,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      titleUrdu: json['titleUrdu'] as String,
      titleEnglish: json['titleEnglish'] as String,
      tag: json['tag'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: json['amount'] as int,
      isSale: json['isSale'] as bool,
      iconType: json['iconType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleUrdu': titleUrdu,
      'titleEnglish': titleEnglish,
      'tag': tag,
      'date': date.toIso8601String(),
      'amount': amount,
      'isSale': isSale,
      'iconType': iconType,
    };
  }
}
