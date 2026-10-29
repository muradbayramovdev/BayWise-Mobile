// ─── Türkçe Kategoriler ───────────────────────────────────────────────────────

const List<String> kDefaultIncomeCategories = [
  'Maaş',
  'Freelance',
  'Yatırım',
  'Kira Geliri',
  'Hediye',
  'Diğer Gelir',
];

const List<String> kDefaultExpenseCategories = [
  'Gıda',
  'Ulaşım',
  'Kira',
  'Faturalar',
  'Sağlık',
  'Eğlence',
  'Giyim',
  'Eğitim',
  'Market',
  'Diğer',
];

// Tüm kategoriler (geriye dönük uyumluluk)
const List<String> kCategories = [
  'Gıda',
  'Ulaşım',
  'Kira',
  'Faturalar',
  'Sağlık',
  'Eğlence',
  'Giyim',
  'Eğitim',
  'Market',
  'Maaş',
  'Tasarruf',
  'Diğer',
];

const List<String> kIncomeCategories = [
  'Maaş',
  'Freelance',
  'Yatırım',
  'Kira Geliri',
  'Hediye',
  'Diğer Gelir',
];

const List<String> kExpenseCategories = [
  'Gıda',
  'Ulaşım',
  'Kira',
  'Faturalar',
  'Sağlık',
  'Eğlence',
  'Giyim',
  'Eğitim',
  'Market',
  'Tasarruf',
  'Diğer',
];

const String kCurrency = '₺';

// Emoji haritası
const Map<String, String> kCategoryEmojis = {
  'Gıda': '🍔',
  'Ulaşım': '🚌',
  'Kira': '🏠',
  'Faturalar': '💡',
  'Sağlık': '💊',
  'Eğlence': '🎮',
  'Giyim': '👗',
  'Eğitim': '📚',
  'Market': '🛒',
  'Maaş': '💰',
  'Freelance': '💻',
  'Yatırım': '📈',
  'Kira Geliri': '🏦',
  'Hediye': '🎁',
  'Tasarruf': '🏧',
  'Diğer Gelir': '➕',
  'Alışveriş': '🛍️',
  'Diğer': '📦',
};

// Eski İngilizce / Azerbaycan → Türkçe çevirisi (mevcut Firestore verileri için)
const Map<String, String> kCategoryTranslations = {
  'Food': 'Gıda',
  'Yemek': 'Gıda',
  'Transport': 'Ulaşım',
  'Rent': 'Kira',
  'Shopping': 'Market',
  'Alışveriş': 'Market',
  'Health': 'Sağlık',
  'Utilities': 'Faturalar',
  'Salary': 'Maaş',
  'Savings': 'Tasarruf',
  'Other': 'Diğer',
  'Eğlence': 'Eğlence',
};
