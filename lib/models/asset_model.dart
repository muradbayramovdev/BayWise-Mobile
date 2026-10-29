import 'package:flutter/material.dart';

class AssetModel {
  final String id;
  final String uid;
  final String name;      // Örn: "Arsa (Silivri)", "BMW 320i", "Altın Birikimi"
  final String category;  // Örn: "Gayrimenkul / Arsa", "Araç / Taşıt", ...
  final double value;     // Birim veya Toplam Değer (Örn: 1.500.000 TL)
  final String currency;  // Örn: "₺", "$", "€", "Gr Altın"
  final double amount;    // Örn: 1.0 (Adet) veya 150 (Gram) veya 3000 (Döviz)
  final double exchangeRate; // TL karşılığı için kur (Örn $ ise 34.5, Gr Altın ise 3050, TL ise 1.0)
  final String note;      // Örn: "Yatırım amaçlı alınan arsa"
  final String updatedAt;

  AssetModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.category,
    required this.value,
    this.currency = '₺',
    this.amount = 1.0,
    this.exchangeRate = 1.0,
    this.note = '',
    required this.updatedAt,
  });

  double get totalTlValue {
    if (category == 'Borç / Kredi (-)') {
      return -(value * exchangeRate);
    }
    return value * exchangeRate;
  }

  factory AssetModel.fromMap(String id, Map<String, dynamic> map) {
    return AssetModel(
      id: id,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'Gayrimenkul / Arsa',
      value: (map['value'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? '₺',
      amount: (map['amount'] ?? 1.0).toDouble(),
      exchangeRate: (map['exchangeRate'] ?? 1.0).toDouble(),
      note: map['note'] ?? '',
      updatedAt: map['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'category': category,
      'value': value,
      'currency': currency,
      'amount': amount,
      'exchangeRate': exchangeRate,
      'note': note,
      'updatedAt': updatedAt,
    };
  }
}

const List<String> kAssetCategories = [
  'Gayrimenkul / Arsa',
  'Araç / Taşıt',
  'Altın / Kıymetli Maden',
  'Döviz (USD / EUR vb.)',
  'Borsa / Yatırım Fonu',
  'Kripto Varlıklar',
  'Diğer Varlık',
  'Borç / Kredi (-)',
];

const Map<String, String> kAssetEmojis = {
  'Gayrimenkul / Arsa': '🏡',
  'Araç / Taşıt': '🚗',
  'Altın / Kıymetli Maden': '🥇',
  'Döviz (USD / EUR vb.)': '💵',
  'Borsa / Yatırım Fonu': '📈',
  'Kripto Varlıklar': '₿',
  'Diğer Varlık': '💎',
  'Borç / Kredi (-)': '⚠️',
};
