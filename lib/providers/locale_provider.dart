import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  String _currentLang = 'az'; // Varsayılan AZ / TR tercihine uygun
  String _currentCurrency = 'AZN'; // Varsayılan AZN / TL tercihine uygun

  String get currentLang => _currentLang;
  String get currentCurrency => _currentCurrency;

  LocaleProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLang = prefs.getString('app_lang') ?? 'az';
      _currentCurrency = prefs.getString('app_currency') ?? 'AZN';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLanguage(String langCode) async {
    if (_currentLang == langCode) return;
    _currentLang = langCode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_lang', langCode);
    } catch (_) {}
  }

  Future<void> setCurrency(String currencyCode) async {
    if (_currentCurrency == currencyCode) return;
    _currentCurrency = currencyCode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_currency', currencyCode);
    } catch (_) {}
  }

  String get currencySymbol {
    switch (_currentCurrency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'TL':
        return '₺';
      case 'AZN':
      default:
        return '₼';
    }
  }

  String formatCurrency(double amount, {bool showCode = false}) {
    final formatted = amount.toStringAsFixed(2);
    if (showCode) {
      return '$currencySymbol $formatted ($currentCurrency)';
    }
    return '$currencySymbol $formatted';
  }

  // ─── 4 Dilli Çeviri Sözlüğü (AZ, TR, EN, RU) ──────────────────────────────
  static const Map<String, Map<String, String>> _translations = {
    // Ana Menü ve Başlıklar
    'home': {'az': 'Ana Səhifə', 'tr': 'Ana Sayfa', 'en': 'Home', 'ru': 'Главная'},
    'wealth': {'az': 'Sərvət', 'tr': 'Servet', 'en': 'Wealth', 'ru': 'Капитал'},
    'transactions': {'az': 'Əməliyyatlar', 'tr': 'İşlemler', 'en': 'Transactions', 'ru': 'Транзакции'},
    'budget': {'az': 'Büdcə', 'tr': 'Bütçe', 'en': 'Budget', 'ru': 'Бюджет'},
    'goals': {'az': 'Hədəflər', 'tr': 'Hedefler', 'en': 'Goals', 'ru': 'Цели'},
    'recurring': {'az': 'Daimi', 'tr': 'Düzenli', 'en': 'Recurring', 'ru': 'Постоянные'},
    'ai_insights': {'az': 'Süni İntellekt', 'tr': 'Yapay Zeka', 'en': 'AI Insights', 'ru': 'ИИ Советник'},

    // Kasa ve Çalışma Alanı
    'workspace': {'az': 'İş Sahəsi', 'tr': 'Çalışma Alanı', 'en': 'Workspace', 'ru': 'Рабочее пространство'},
    'switch_workspace': {'az': 'İş Sahəsini Dəyiş / Əlavə Et', 'tr': 'Çalışma Alanını Değiştir / Ekle', 'en': 'Switch / Add Workspace', 'ru': 'Сменить / Добавить пространство'},
    'select_workspace': {'az': 'İş Sahəsi Seçin', 'tr': 'Çalışma Alanı Seçin', 'en': 'Select Workspace', 'ru': 'Выберите пространство'},
    'personal_ws': {'az': 'Şəxsi Kassa', 'tr': 'Kişisel Kasa', 'en': 'Personal Wallet', 'ru': 'Личный кошелек'},
    'business_ws': {'az': 'Biznes Kassası', 'tr': 'Kurumsal Kasa', 'en': 'Business Wallet', 'ru': 'Бизнес кошелек'},
    'active_wallet': {'az': 'Aktiv Kassa', 'tr': 'Aktif Kasa', 'en': 'Active Wallet', 'ru': 'Активный кошелек'},
    'isolate_workspaces_sub': {'az': 'Şəxsi, şirkət və ya xüsusi layihələrinizi bir-birindən təcrid edin.', 'tr': 'Kişisel, şirket veya özel projelerinizi birbirinden izole edin.', 'en': 'Isolate personal, company or special projects.', 'ru': 'Изолируйте личные, компании и спец. проекты.'},
    'personal_ws_sub': {'az': 'Gündəlik xərclər, maaş, ev və şəxsi büdcə', 'tr': 'Günlük harcamalar, maaş, ev ve kişisel bütçe', 'en': 'Daily expenses, salary, home & personal budget', 'ru': 'Ежедневные расходы, зарплата, дом и личный бюджет'},
    'business_ws_sub': {'az': 'Qaimə, vergi, heyət və korporativ nağd pul', 'tr': 'Fatura, vergi, personel ve kurumsal nakit', 'en': 'Bills, taxes, staff & corporate cash', 'ru': 'Счета, налоги, персонал и корпоративные средства'},
    'custom_ws_sub': {'az': 'Xüsusi təcrid olunmuş büdcə və xərc izlənməsi', 'tr': 'Özel izole bütçe ve harcama takibi', 'en': 'Custom isolated budget & expense tracking', 'ru': 'Специальный изолированный бюджет'},
    'add_new_workspace': {'az': 'Yeni İş Sahəsi Əlavə Et', 'tr': 'Yeni Çalışma Alanı Ekle', 'en': 'Add New Workspace', 'ru': 'Добавить пространство'},
    'wallet_project_name': {'az': 'Kassa / Layihə Adı', 'tr': 'Kasa / Proje Adı', 'en': 'Wallet / Project Name', 'ru': 'Название кошелька / проекта'},
    'icon_emoji': {'az': 'İkon / Emoci', 'tr': 'İkon / Emoji', 'en': 'Icon / Emoji', 'ru': 'Иконка / Эмодзи'},
    'create_and_switch': {'az': 'Yarat və Keç', 'tr': 'Oluştur & Geç', 'en': 'Create & Switch', 'ru': 'Создать и перейти'},
    'edit_workspace': {'az': 'İş Sahəsinə Düzəliş Et', 'tr': 'Çalışma Alanını Düzenle', 'en': 'Edit Workspace', 'ru': 'Редактировать пространство'},
    'delete_workspace': {'az': 'İş Sahəsini Sil', 'tr': 'Çalışma Alanını Sil', 'en': 'Delete Workspace', 'ru': 'Удалить пространство'},

    // İşlemler & Butonlar
    'add_transaction': {'az': 'Yeni Əməliyyat Əlavə Et', 'tr': 'Yeni İşlem Ekle', 'en': 'Add Transaction', 'ru': 'Добавить операцию'},
    'income': {'az': 'Mədaxil (+)', 'tr': 'Gelir (+)', 'en': 'Income (+)', 'ru': 'Доход (+)'},
    'expense': {'az': 'Məxaric (-)', 'tr': 'Gider (-)', 'en': 'Expense (-)', 'ru': 'Расход (-)'},
    'all': {'az': 'Bütün', 'tr': 'Tümü', 'en': 'All', 'ru': 'Все'},
    'save': {'az': 'Yadda Saxla', 'tr': 'Kaydet', 'en': 'Save', 'ru': 'Сохранить'},
    'cancel': {'az': 'Ləğv Et', 'tr': 'İptal', 'en': 'Cancel', 'ru': 'Отмена'},
    'delete': {'az': 'Sil', 'tr': 'Sil', 'en': 'Delete', 'ru': 'Удалить'},
    'edit': {'az': 'Düzəliş Et', 'tr': 'Düzenle', 'en': 'Edit', 'ru': 'Редактировать'},
    'active': {'az': 'Aktiv ✓', 'tr': 'Aktif ✓', 'en': 'Active ✓', 'ru': 'Активно ✓'},
    'passive': {'az': 'Qeyri-aktiv', 'tr': 'Pasif', 'en': 'Inactive', 'ru': 'Неактивно'},

    // Ayarlar & Diğer
    'settings': {'az': 'Tənzimləmələr', 'tr': 'Ayarlar', 'en': 'Settings', 'ru': 'Настройки'},
    'lang_currency_settings': {'az': 'Dil və Valyuta Ayarları', 'tr': 'Dil ve Kur (Döviz) Ayarları', 'en': 'Language & Currency Settings', 'ru': 'Настройки языка и валюты'},
    'select_lang': {'az': 'Dil Seçin (Language)', 'tr': 'Dil Seçin (Language)', 'en': 'Select Language', 'ru': 'Выберите язык'},
    'select_currency': {'az': 'Valyuta və Kur Seçin', 'tr': 'Para Birimi & Kur Seçin', 'en': 'Select Currency & Rate', 'ru': 'Выберите валюту'},
    'logout': {'az': 'Çıxış', 'tr': 'Çıkış Yap', 'en': 'Log Out', 'ru': 'Выйти'},
    'summary': {'az': 'Günün Maliyyə Xülasəsi', 'tr': 'Günün Finansal Özeti', 'en': 'Daily Financial Summary', 'ru': 'Финансовая сводка за день'},
    'total_balance': {'az': 'Ümumi Balans (Xalis Sərvət Xülasəsi)', 'tr': 'Toplam Bakiye (Net Servet Özeti)', 'en': 'Total Balance (Net Worth Summary)', 'ru': 'Общий баланс (Чистый капитал)'},
    'monthly_income': {'az': 'Aylıq Gəlir', 'tr': 'Aylık Gelir', 'en': 'Monthly Income', 'ru': 'Ежемесячный доход'},
    'monthly_expense': {'az': 'Aylıq Xərc', 'tr': 'Aylık Gider', 'en': 'Monthly Expense', 'ru': 'Ежемесячный расход'},
    'net_worth': {'az': 'Xalis Sərvət', 'tr': 'Net Servet', 'en': 'Net Worth', 'ru': 'Чистый капитал'},
    'categories': {'az': 'Kateqoriyalar', 'tr': 'Kategoriler', 'en': 'Categories', 'ru': 'Категории'},
    'daily_summary': {'az': 'Günün Maliyyə Xülasəsi', 'tr': 'Günün Finansal Özeti', 'en': 'Daily Financial Summary', 'ru': 'Финансовая сводка дня'},
    'my_assets': {'az': 'Varlıqlarım & Sərvət Cədvəlim', 'tr': 'Varlıklarım & Servet Tablom', 'en': 'My Assets & Wealth Table', 'ru': 'Мои активы и таблица капитала'},
    
    // Alt Ekran Başlıkları (Kategoriler, Düzenli vb.)
    'category_details': {'az': 'Kateqoriya Detayları', 'tr': 'Kategori Detayları', 'en': 'Category Details', 'ru': 'Детали категории'},
    'recurring_payments': {'az': 'Daimi Ödənişlər', 'tr': 'Düzenli Ödemeler', 'en': 'Recurring Payments', 'ru': 'Регулярные платежи'},
    'ai_assistant': {'az': 'Süni İntellekt Köməkçisi', 'tr': 'Yapay Zeka Asistanı', 'en': 'AI Assistant', 'ru': 'ИИ Ассистент'},
    'ai_suggestions': {'az': '✦ Süni İntellekt Təklifləri', 'tr': '✦ Yapay Zeka Finansal Önerileri', 'en': '✦ AI Financial Suggestions', 'ru': '✦ Финансовые советы ИИ'},
    'ask_financial_advisor': {'az': 'Finansal Məsləhətçiyə Soruş', 'tr': 'Finansal Danışmana Sor', 'en': 'Ask Financial Advisor', 'ru': 'Спросить консультанта'},
    'empty_goals': {'az': 'Hələ bir hədəfiniz yoxdur', 'tr': 'Henüz bir hedefiniz yok', 'en': 'No goals yet', 'ru': 'Целей пока нет'},
    'empty_goals_sub': {'az': 'Avtomobil, Tətil kimi hədəfləriniz üçün pul yığın', 'tr': 'Araba, Tatil, Bilgisayar gibi hedeflerinize birikim yapın', 'en': 'Save for goals like Car, Vacation, Computer', 'ru': 'Копите на машину, отпуск и другие цели'},
    'goal_details': {'az': 'Hədəf Detayları', 'tr': 'Hedef Detayları', 'en': 'Goal Details', 'ru': 'Детали цели'},
    'delete_tx': {'az': 'Əməliyyatı Sil', 'tr': 'İşlemi Sil', 'en': 'Delete Transaction', 'ru': 'Удалить транзакцию'},
    'delete_recurring': {'az': 'Daimi İşləmi Sil', 'tr': 'Tekrarlayan İşlemi Sil', 'en': 'Delete Recurring', 'ru': 'Удалить регулярный'},

    // Eksik Çeviriler (Nakit Akışı, Varlıklar vb.)
    'cash_flow': {'az': 'Nağd Axını', 'tr': 'Nakit Akışı', 'en': 'Cash Flow', 'ru': 'Денежный поток'},
    'new_transaction': {'az': 'Yeni İşlem', 'tr': 'Yeni İşlem', 'en': 'New Tx', 'ru': 'Новая операция'},
    'add_new_transaction': {'az': 'Yeni İşlem Əlavə Et', 'tr': 'Yeni İşlem Ekle', 'en': 'Add New Tx', 'ru': 'Добавить операцию'},
    'edit_transaction': {'az': 'İşləmə Düzəliş Et', 'tr': 'İşlemi Düzenle', 'en': 'Edit Tx', 'ru': 'Изменить операцию'},
    'select_workspace_title': {'az': 'İş Sahəsi Seçin', 'tr': 'Çalışma Alanı Seçin', 'en': 'Select Workspace', 'ru': 'Выберите пространство'},
    'assets_real_estate': {'az': 'Daşınmaz Əmlak / Torpaq', 'tr': 'Gayrimenkul / Arsa', 'en': 'Real Estate / Land', 'ru': 'Недвижимость / Земля'},
    'assets_vehicle': {'az': 'Avtomobil / Nəqliyyat', 'tr': 'Araç / Taşıt', 'en': 'Vehicle / Transport', 'ru': 'Транспорт'},
    'assets_investment': {'az': 'Qızıl / Valyuta / İnvestisiya', 'tr': 'Altın / Döviz / Yatırım', 'en': 'Gold / Forex / Invest', 'ru': 'Золото / Валюта / Инвестиции'},
    'assets_debt': {'az': 'Borç / Kredit (-)', 'tr': 'Borç / Kredi (-)', 'en': 'Debt / Loan (-)', 'ru': 'Долг / Кредит (-)'},
    'assets_crypto': {'az': 'Kripto Varlıqlar', 'tr': 'Kripto Varlıklar', 'en': 'Crypto Assets', 'ru': 'Криптоактивы'},
    'assets_title': {'az': 'Varlıqlar (Torpaq, Avto və s.)', 'tr': 'Varlıklar (Arsa, Araç vb.)', 'en': 'Assets (Land, Car etc.)', 'ru': 'Активы (Земля, Авто и т.д.)'},
    'assets_empty_msg': {'az': 'Torpaq, ev, avto, qızıl, valyuta və investisiyalarınızı əlavə edərək xalis sərvətinizi anlıq izləyin.', 'tr': 'Arsa, ev, araba, altın, döviz ve yatırımlarınızı ekleyerek net servetinizi anlık takip edin.', 'en': 'Track your net worth by adding land, home, car, gold, forex and investments.', 'ru': 'Следите за чистым капиталом, добавляя недвижимость, авто, золото, валюту и инвестиции.'},
    'assets_hint': {'az': 'Nümunə: Silivri Torpaq, 2020 BMW, 50 Qr Qızıl...', 'tr': 'Örn: Silivri Arsa, 2020 BMW, 50 Gr Altın...', 'en': 'Ex: Silivri Land, 2020 BMW, 50g Gold...', 'ru': 'Напр: Земля в Силиври, 2020 BMW, 50г Золото...'},
    'recurring_income': {'az': 'Daimi Gəlirlər (+)', 'tr': 'Düzenli Gelirler (+)', 'en': 'Recurring Income (+)', 'ru': 'Регулярные доходы (+)'},
    'recurring_expense': {'az': 'Daimi Xərclər (-)', 'tr': 'Düzenli Giderler (-)', 'en': 'Recurring Expenses (-)', 'ru': 'Регулярные расходы (-)'},

    // Hedefler / Goals
    'add_new_goal': {'az': 'Yeni Maliyyə Hədəfi Əlavə Et', 'tr': 'Yeni Finansal Hedef Ekle', 'en': 'Add New Financial Goal', 'ru': 'Добавить новую финансовую цель'},
    'add_savings': {'az': 'Qənaət Əlavə Et', 'tr': 'Birikim Ekle', 'en': 'Add Savings', 'ru': 'Добавить сбережения'},
    'create_goal': {'az': 'Hədəfi Yarat', 'tr': 'Hedefi Oluştur', 'en': 'Create Goal', 'ru': 'Создать цель'},
    'save_savings': {'az': 'Qənaəti Yadda Saxla', 'tr': 'Birikimi Kaydet', 'en': 'Save Savings', 'ru': 'Сохранить сбережения'},
    'new_goal_title': {'az': 'Yeni Maliyyə Hədəfi', 'tr': 'Yeni Finansal Hedef', 'en': 'New Financial Goal', 'ru': 'Новая финансовая цель'},
    'days_left': {'az': 'gün qaldı', 'tr': 'gün kaldı', 'en': 'days left', 'ru': 'дней осталось'},
    'time_is_up': {'az': 'Tamamlanma vaxtı gəldi!', 'tr': 'Tamamlanma zamanı geldi!', 'en': 'Time is up!', 'ru': 'Время вышло!'},

    // Kısa etiketler & Arama
    'income_short': {'az': 'Gəlir', 'tr': 'Gelir', 'en': 'Income', 'ru': 'Доход'},
    'expense_short': {'az': 'Xərc', 'tr': 'Gider', 'en': 'Expense', 'ru': 'Расход'},
    'net_short': {'az': 'Xalis', 'tr': 'Net', 'en': 'Net', 'ru': 'Итого'},
    'search_tx': {'az': 'Əməliyyat axtar...', 'tr': 'İşlem ara...', 'en': 'Search transactions...', 'ru': 'Поиск операций...'},
    'no_tx_month': {'az': 'Bu ay üçün əməliyyat tapılmadı', 'tr': 'Bu ay için işlem bulunamadı', 'en': 'No transactions for this month', 'ru': 'За этот месяц операций нет'},
    'no_tx_filter': {'az': 'Axtarılan meyarda nəticə yoxdur', 'tr': 'Aradığınız kriterde sonuç yok', 'en': 'No results for selected filter', 'ru': 'Нет результатов по фильтру'},

    // Büdcə & Kateqoriya Etiketləri
    'monthly_category_budgets': {'az': 'Aylıq Kateqoriya Büdcələri', 'tr': 'Aylık Kategori Bütçeleri', 'en': 'Monthly Category Budgets', 'ru': 'Ежемесячные бюджеты категорий'},
    'add_budget': {'az': 'Büdcə Əlavə Et', 'tr': 'Bütçe Ekle', 'en': 'Add Budget', 'ru': 'Добавить бюджет'},
    'no_budget_set': {'az': 'Hələ büdcə təyin edilməyib', 'tr': 'Henüz bütçe tanımlanmadı', 'en': 'No budget set yet', 'ru': 'Бюджет еще не задан'},
    'add_budget_hint': {'az': 'Yuxarıdan "Büdcə Əlavə Et" ilə kateqoriyalara limit təyin edin.', 'tr': 'Yukarıdan "Bütçe Ekle" ile kategorilere üst limit belirleyin.', 'en': 'Set limits for categories via "Add Budget" above.', 'ru': 'Установите лимиты по категориям через "Добавить бюджет".'},
    'no_expense_in_category': {'az': 'Bu kateqoriyada hələ xərc yoxdur', 'tr': 'Bu kategoride henüz harcama bulunmuyor', 'en': 'No expenses in this category yet', 'ru': 'В этой категории пока нет расходов'},
    'select_category': {'az': 'Kateqoriya Seçin', 'tr': 'Kategori Seçin', 'en': 'Select Category', 'ru': 'Выберите категорию'},
    'new_category': {'az': 'Yeni Kateqoriya', 'tr': 'Yeni Kategori', 'en': 'New Category', 'ru': 'Новая категория'},
    'category_name': {'az': 'Kateqoriya adı...', 'tr': 'Kategori adı...', 'en': 'Category name...', 'ru': 'Название категории...'},
    'please_select_category': {'az': 'Zəhmət olmasa kateqoriya seçin', 'tr': 'Lütfen bir kategori seçin', 'en': 'Please select a category', 'ru': 'Пожалуйста, выберите категорию'},
    'add_income_btn': {'az': 'Mədaxil Əlavə Et (+)', 'tr': 'Gelir Ekle (+)', 'en': 'Add Income (+)', 'ru': 'Добавить доход (+)'},
    'add_expense_btn': {'az': 'Məxaric Əlavə Et (-)', 'tr': 'Gider Ekle (-)', 'en': 'Add Expense (-)', 'ru': 'Добавить расход (-)'},
    'enter_description_optional': {'az': 'Təsvir yazın (istəyə bağlı)', 'tr': 'Açıklama girin (isteğe bağlı)', 'en': 'Enter description (optional)', 'ru': 'Введите описание (опционально)'},
    'no_description': {'az': 'Təsvir yazılmayıb', 'tr': 'Açıklama girilmedi', 'en': 'No description', 'ru': 'Без описания'},

    // Daimi İşləmlər
    'monthly_recurring_income': {'az': 'Aylıq Daimi Gəlir', 'tr': 'Aylık Düzenli Gelir', 'en': 'Monthly Recurring Income', 'ru': 'Ежемесячный постоянный доход'},
    'monthly_recurring_expense': {'az': 'Aylıq Daimi Xərc', 'tr': 'Aylık Düzenli Gider', 'en': 'Monthly Recurring Expense', 'ru': 'Ежемесячный постоянный расход'},
    'income_confirmation': {'az': 'Gəlir Mədaxili Təsdiqi', 'tr': 'Gelir Tahsilatı Onayı', 'en': 'Income Collection Confirmation', 'ru': 'Подтверждение получения дохода'},
    'expense_confirmation': {'az': 'Xərc Ödənişi Təsdiqi', 'tr': 'Gider Ödemesi Onayı', 'en': 'Expense Payment Confirmation', 'ru': 'Подтверждение оплаты расхода'},
    'no_recurring_msg': {'az': 'Hələ daimi gəlir və ya xərciniz yoxdur', 'tr': 'Henüz tekrarlayan gelir veya gideriniz yok', 'en': 'No recurring income or expense yet', 'ru': 'Постоянных доходов и расходов пока нет'},

    // Sərvət & Ana Ekran
    'toplam_net_servet': {'az': 'ÜMUMİ XALİS SƏRVƏT DƏYƏRİM', 'tr': 'TOPLAM NET SERVET DEĞERİM', 'en': 'TOTAL NET WORTH VALUE', 'ru': 'ОБЩАЯ ЧИСТАЯ СТОИМОСТЬ'},
    'borclar_krediler': {'az': 'Borclar və Kreditlər', 'tr': 'Borçlar & Krediler', 'en': 'Debts & Loans', 'ru': 'Долги и кредиты'},
    'category_type': {'az': 'Kateqoriya Növü', 'tr': 'Kategori Türü', 'en': 'Category Type', 'ru': 'Тип категории'},
    'net_worth_summary': {'az': 'Xalis Sərvət Xülasəsi', 'tr': 'Net Servet Özeti', 'en': 'Net Worth Summary', 'ru': 'Сводка чистого капитала'},
    'category_expenses': {'az': 'Kateqoriyaya Görə Xərclər', 'tr': 'Kategoriye Göre Harcamalar', 'en': 'Expenses by Category', 'ru': 'Расходы по категориям'},
    'view_all': {'az': 'Hamısını gör →', 'tr': 'Tümünü gör →', 'en': 'View all →', 'ru': 'Смотреть все →'},

    // Daimi Sıklık & Detaylar
    'add_recurring_tx': {'az': 'Yeni Daimi Əməliyyat Əlavə Et', 'tr': 'Yeni Tekrarlayan İşlem Ekle', 'en': 'Add New Recurring Tx', 'ru': 'Добавить регулярную операцию'},
    'recurring_name_hint': {'az': 'Əməliyyat adı (Nüm: Kirayə, Maaş, Kommunal)', 'tr': 'İşlem adı (Örn: Netflix, Kira, Maaş, Kira Geliri)', 'en': 'Tx name (e.g. Netflix, Rent, Salary)', 'ru': 'Название (напр: Аренда, Зарплата)'},
    'recurrence_frequency': {'az': 'Təkrarlanma Tezliyi', 'tr': 'Tekrarlanma Sıklığı', 'en': 'Recurrence Frequency', 'ru': 'Частота повторения'},
    'daily': {'az': 'Hər gün', 'tr': 'Günlük', 'en': 'Daily', 'ru': 'Ежедневно'},
    'weekly': {'az': 'Həftəlik', 'tr': 'Haftalık', 'en': 'Weekly', 'ru': 'Еженедельно'},
    'monthly': {'az': 'Aylıq', 'tr': 'Aylık', 'en': 'Monthly', 'ru': 'Ежемесячно'},
    'yearly': {'az': 'İllik', 'tr': 'Yıllık', 'en': 'Yearly', 'ru': 'Ежегодно'},
    'every_month_day': {'az': 'Hər ayın {day}-ci günü ({date})', 'tr': 'Her ayın {day}. günü ({date})', 'en': 'Every month on day {day} ({date})', 'ru': 'Каждый месяц {day}-го числа ({date})'},
    'due_today': {'az': '🔥 Bu gün icra olunacaq!', 'tr': '🔥 Bugün gerçekleşecek!', 'en': '🔥 Due today!', 'ru': '🔥 Наступает сегодня!'},
    'days_left_fmt': {'az': '⏳ {days} gün sonra ({date})', 'tr': '⏳ {days} gün sonra ({date})', 'en': '⏳ In {days} days ({date})', 'ru': '⏳ Через {days} дн. ({date})'},
    'delete_confirm': {'az': 'Silmək istədiyinizə əminsiniz:', 'tr': 'Silmek istediğinize emin misiniz:', 'en': 'Are you sure you want to delete:', 'ru': 'Вы уверены, что хотите удалить:'},
    'recurring_empty_sub': {'az': 'Kirayə, Maaş, Kommunal kimi daimi əməliyyatları bura əlavə edin', 'tr': 'Kira, Maaş, Fatura gibi düzenli işlemleri buraya ekleyin', 'en': 'Add recurring transactions like Rent, Salary, Bills here', 'ru': 'Добавляйте регулярные операции (Аренда, Зарплата, Счета) сюда'},
    'deleted_toast': {'az': 'Daimi əməliyyat silindi', 'tr': 'Tekrarlayan işlem silindi', 'en': 'Recurring transaction deleted', 'ru': 'Регулярная операция удалена'},
    'active_yes': {'az': 'Aktiv ✓', 'tr': 'Aktif ✓', 'en': 'Active ✓', 'ru': 'Активно ✓'},
    'process_income_btn': {'az': '⚡ Gəliri daxil et & aya keç', 'tr': '⚡ Geliri tahsil et & aya atla', 'en': '⚡ Collect income & skip to next month', 'ru': '⚡ Получить доход и перейти на месяц'},
    'process_expense_btn': {'az': '⚡ Ödənişi et & aya keç', 'tr': '⚡ Ödemeyi yap & aya atla', 'en': '⚡ Pay & skip to next month', 'ru': '⚡ Оплатить и перейти на месяц'},
    'collect_income': {'az': 'Mədaxil Et (+)', 'tr': 'Tahsil Et (+)', 'en': 'Collect (+)', 'ru': 'Получить (+)'},
    'pay_from_safe': {'az': 'Kassadan Ödə (-)', 'tr': 'Kasadan Öde (-)', 'en': 'Pay from Safe (-)', 'ru': 'Оплатить кассой (-)'},
    'recurring_history': {'az': 'Qeydə Alınmış Daimi Əməliyyat Tarixçəsi', 'tr': 'Kaydedilen Düzenli İşlem Geçmişi', 'en': 'Recorded Recurring History', 'ru': 'История регулярных операций'},
    'recurring_history_sub': {'az': 'Daimi ödənişlərdən kassaya köçürülmüş qeydlər. Keçmiş ayın məbləğini doğrudan dəyişə bilərsiniz:', 'tr': 'Tekrarlayan ödemelerden kasaya işlenmiş/gerçekleşen kayıtlar. Buradan herhangi bir geçmiş ayın tutarını veya tarihini doğrudan değiştirebilirsiniz:', 'en': 'History of recurring payments posted to safe. Edit any past record directly:', 'ru': 'Проведенные регулярные операции. Вы можете изменить сумму любого месяца:'},
    'no_recurring_tx_found': {'az': 'Hələ bu şablonlardan kassaya yazılmış bir əməliyyat qeydi yoxdur.', 'tr': 'Henüz bu şablonlardan kasaya işlenmiş bir işlem kaydı yok.', 'en': 'No safe entries generated from these templates yet.', 'ru': 'Записей в кассе по этим шаблонам еще нет.'},
    'add_recurring': {'az': 'Daimi Əlavə Et', 'tr': 'Tekrarlayan Ekle', 'en': 'Add Recurring', 'ru': 'Добавить регулярный'},
    'error_empty_title': {'az': 'Zəhmət olmasa əməliyyat başlığını yazın', 'tr': 'Lütfen işlem başlığını girin', 'en': 'Please enter a transaction title', 'ru': 'Введите название операции'},
    'error_valid_amount': {'az': 'Zəhmət olmasa düzgün məbləğ daxil edin', 'tr': 'Lütfen geçerli bir tutar girin', 'en': 'Please enter a valid amount', 'ru': 'Введите корректную сумму'},
    'updated_past_future': {'az': 'Keçmiş və gələcək bütün qeydlər yeniləndi ✓', 'tr': 'Geçmiş ve gelecek tüm kayıtlar güncellendi ✓', 'en': 'All past and future entries updated ✓', 'ru': 'Все прошлые и будущие записи обновлены ✓'},
    'updated_future_only': {'az': 'Növbəti və gələcək dövrlər yeniləndi ✓', 'tr': 'Sıradaki ve gelecek dönemler güncellendi ✓', 'en': 'Next and future periods updated ✓', 'ru': 'Следующий и будущие периоды обновлены ✓'},
    'updated_local': {'az': 'Yenilənmə yerli yaddaşa yazıldı ✓', 'tr': 'Güncelleme yerel önbelleğe kaydedildi ✓', 'en': 'Update saved to local cache ✓', 'ru': 'Обновление сохранено локально ✓'},
    'update_recurring': {'az': 'Daimi Əməliyyatı Yenilə', 'tr': 'Düzenli İşlemi Güncelle', 'en': 'Update Recurring Tx', 'ru': 'Обновить регулярную операцию'},
    'update_recurring_sub': {'az': 'Aylıq kirayə artımı və ya səhv girilən məbləğləri buradan düzəldə bilərsiniz.', 'tr': 'Aylık kira artışı veya yanlış girilen tutarları buradan düzenleyebilirsiniz.', 'en': 'Adjust monthly rent increases or incorrectly entered amounts here.', 'ru': 'Измените плату за аренду или суммы здесь.'},
    'expense_minus': {'az': 'Xərc (-)', 'tr': 'Gider (-)', 'en': 'Expense (-)', 'ru': 'Расход (-)'},
    'income_plus': {'az': 'Gəlir (+)', 'tr': 'Gelir (+)', 'en': 'Income (+)', 'ru': 'Доход (+)'},
    'transaction_title': {'az': 'Əməliyyat Başlığı', 'tr': 'İşlem Başlığı', 'en': 'Transaction Title', 'ru': 'Заголовок операции'},
    'new_amount': {'az': 'Yeni Məbləğ', 'tr': 'Yeni Tutar', 'en': 'New Amount', 'ru': 'Новая сумма'},
    'category': {'az': 'Kateqoriya', 'tr': 'Kategori', 'en': 'Category', 'ru': 'Категория'},
    'monthly_day_info': {'az': 'Hər Ayın Hangi Günü Təkrarlanacağı:', 'tr': 'Her Ayın Hangi Günü Tekrarlandığı:', 'en': 'Day of Month to Repeat:', 'ru': 'День месяца для повтора:'},
    'day': {'az': 'Gün', 'tr': 'Gün', 'en': 'Day', 'ru': 'День'},
    'next_occurrence': {'az': 'Növbəti İcra Tarixi:', 'tr': 'Sıradaki Gerçekleşme Tarihi:', 'en': 'Next Occurrence Date:', 'ru': 'Следующая дата:'},
    'first_occurrence_date': {'az': 'İlk İcra Tarixi:', 'tr': 'İlk Gerçekleşme Tarihi:', 'en': 'First Occurrence Date:', 'ru': 'Первая дата:'},
    'save_future_only': {'az': 'Gələcək Dövrlərə Tətbiq Et (Keçmiş Sabit)', 'tr': 'Gelecek Dönemlere Uygula (Geçmiş Sabit)', 'en': 'Apply to Future (Past Fixed)', 'ru': 'Применить к будущим (Прошлые фиксированы)'},
    'income_collect_confirm': {'az': 'Gəlir Mədaxili Təsdiqi', 'tr': 'Gelir Tahsilatı Onayı', 'en': 'Income Collection Confirmation', 'ru': 'Подтверждение получения дохода'},
    'expense_pay_confirm': {'az': 'Xərc Ödənişi Təsdiqi', 'tr': 'Gider Ödemesi Onayı', 'en': 'Expense Payment Confirmation', 'ru': 'Подтверждение оплаты расхода'},
    'process_confirm_body': {
      'az': '"{name}" ({amount} {sym}) əməliyyatını bu gün ({date}) icra olunmuş olaraq kassanıza daxil etmək istəyirsiniz?\n\nƏməliyyat əlavə olunduqdan sonra növbəti tarix gələcək dövrə keçəcək.',
      'tr': '"{name}" ({amount} {sym}) işlemini bugün ({date}) gerçekleşti olarak kasanıza işlemek istiyor musunuz?\n\nİşlem eklendikten sonra sıradaki tarih bir sonraki döneme kaydırılacaktır.',
      'en': 'Do you want to record "{name}" ({amount} {sym}) into your safe today ({date})?\n\nAfter adding, the next date will advance to the next period.',
      'ru': 'Хотите провести "{name}" ({amount} {sym}) в кассу сегодня ({date})?\n\nСледующая дата сдвинется на следующий период.'
    },
    'processed_to_safe_toast': {
      'az': '⚡ "{name}" kassaya işləndi! Növbəti tarix: {date}',
      'tr': '⚡ "{name}" kasaya işlendi! Sıradaki tarih: {date}',
      'en': '⚡ "{name}" recorded to safe! Next date: {date}',
      'ru': '⚡ "{name}" проведено в кассу! Следующая дата: {date}'
    },
    'select_account': {'az': 'Hesab seçin', 'tr': 'Hesap seçin', 'en': 'Select account', 'ru': 'Выберите счет'},
    'saving': {'az': 'Yadda saxlanılır...', 'tr': 'Kaydediliyor...', 'en': 'Saving...', 'ru': 'Сохранение...'},
    'save_changes': {'az': 'Dəyişiklikləri Yadda Saxla', 'tr': 'Değişiklikleri Kaydet', 'en': 'Save Changes', 'ru': 'Сохранить изменения'},
    'save_transaction': {'az': 'Əməliyyatı Yadda Saxla', 'tr': 'İşlemi Kaydet', 'en': 'Save Transaction', 'ru': 'Сохранить операцию'},
    'category_name_hint': {'az': 'Kateqoriya adı...', 'tr': 'Kategori adı...', 'en': 'Category name...', 'ru': 'Название категории...'},
    'tx_saved': {'az': 'Əməliyyat yadda saxlanıldı ✓', 'tr': 'İşlem kaydedildi ✓', 'en': 'Transaction saved ✓', 'ru': 'Операция сохранена ✓'},
    'tx_updated': {'az': 'Əməliyyat yeniləndi ✓', 'tr': 'İşlem güncellendi ✓', 'en': 'Transaction updated ✓', 'ru': 'Операция обновлена ✓'},
    'valid_amount_error': {'az': 'Zəhmət olmasa düzgün məbləğ daxil edin', 'tr': 'Lütfen geçerli bir tutar girin', 'en': 'Please enter a valid amount', 'ru': 'Введите корректную сумму'},
    'select_cat_error': {'az': 'Zəhmət olmasa kateqoriya seçin', 'tr': 'Lütfen bir kategori seçin', 'en': 'Please select a category', 'ru': 'Выберите категорию'},
    'save_all_including_past': {'az': 'Əski Əməliyyatlar Daxil Hamısını Dəyiş', 'tr': 'Eski İşlemler Dahil Tümünü Değiştir', 'en': 'Update All (Including Past)', 'ru': 'Обновить все (включая прошлые)'},
    'regular': {'az': 'Daimi', 'tr': 'Düzenli', 'en': 'Recurring', 'ru': 'Регулярный'},
    'processed_note': {'az': 'Daimi əməliyyat əlavə edildikdə kassaya köçürüldü', 'tr': 'Tekrarlayan işlem eklendiğinde kasaya işlendi', 'en': 'Processed to safe upon adding recurring tx', 'ru': 'Проведено в кассу при добавлении'},
    'saved_successfully': {'az': 'Daimi əməliyyat uğurla yadda saxlanıldı ✓', 'tr': 'Tekrarlayan işlem başarıyla kaydedildi ✓', 'en': 'Recurring tx saved successfully ✓', 'ru': 'Регулярная операция успешно сохранена ✓'},
    'saved_local': {'az': 'Əməliyyat yerli yaddaşa yazıldı ✓', 'tr': 'İşlem yerel önbelleğe kaydedildi ✓', 'en': 'Saved to local cache ✓', 'ru': 'Сохранено локально ✓'},
    'amount': {'az': 'Məbləğ', 'tr': 'Tutar', 'en': 'Amount', 'ru': 'Сумма'},
    'no_asset_name': {'az': 'Varlıq Adı Yoxdur', 'tr': 'Varlık Adı Yok', 'en': 'No Asset Name', 'ru': 'Без названия актива'},

    // Kategoriler
    'Gıda': {'az': 'Qida', 'tr': 'Gıda', 'en': 'Food', 'ru': 'Еда'},
    'Yemek': {'az': 'Qida', 'tr': 'Yemek', 'en': 'Food', 'ru': 'Еда'},
    'Food': {'az': 'Qida', 'tr': 'Gıda', 'en': 'Food', 'ru': 'Еда'},
    'Ulaşım': {'az': 'Nəqliyyat', 'tr': 'Ulaşım', 'en': 'Transport', 'ru': 'Транспорт'},
    'Transport': {'az': 'Nəqliyyat', 'tr': 'Ulaşım', 'en': 'Transport', 'ru': 'Транспорт'},
    'Kira': {'az': 'Kirayə', 'tr': 'Kira', 'en': 'Rent', 'ru': 'Аренда'},
    'Rent': {'az': 'Kirayə', 'tr': 'Kira', 'en': 'Rent', 'ru': 'Аренда'},
    'Alışveriş': {'az': 'Alış-veriş', 'tr': 'Alışveriş', 'en': 'Shopping', 'ru': 'Покупки'},
    'Shopping': {'az': 'Alış-veriş', 'tr': 'Alışveriş', 'en': 'Shopping', 'ru': 'Покупки'},
    'Market': {'az': 'Market / Alış-veriş', 'tr': 'Market / Alışveriş', 'en': 'Groceries & Shopping', 'ru': 'Магазины / Покупки'},
    'Sağlık': {'az': 'Səhiyyə', 'tr': 'Sağlık', 'en': 'Health', 'ru': 'Здоровье'},
    'Health': {'az': 'Səhiyyə', 'tr': 'Sağlık', 'en': 'Health', 'ru': 'Здоровье'},
    'Faturalar': {'az': 'Kommunal / Fakturalar', 'tr': 'Faturalar', 'en': 'Bills & Utilities', 'ru': 'Счета и коммуналка'},
    'Bills': {'az': 'Kommunal / Fakturalar', 'tr': 'Faturalar', 'en': 'Bills & Utilities', 'ru': 'Счета и коммуналка'},
    'Utilities': {'az': 'Kommunal / Fakturalar', 'tr': 'Faturalar', 'en': 'Bills & Utilities', 'ru': 'Счета и коммуналка'},
    'Eğlence': {'az': 'Əyləncə', 'tr': 'Eğlence', 'en': 'Entertainment', 'ru': 'Развлечения'},
    'Entertainment': {'az': 'Əyləncə', 'tr': 'Eğlence', 'en': 'Entertainment', 'ru': 'Развлечения'},
    'Giyim': {'az': 'Geyim', 'tr': 'Giyim', 'en': 'Clothing', 'ru': 'Одежда'},
    'Clothing': {'az': 'Geyim', 'tr': 'Giyim', 'en': 'Clothing', 'ru': 'Одежда'},
    'Eğitim': {'az': 'Təhsil', 'tr': 'Eğitim', 'en': 'Education', 'ru': 'Образование'},
    'Education': {'az': 'Təhsil', 'tr': 'Eğitim', 'en': 'Education', 'ru': 'Образование'},
    'Maaş': {'az': 'Maaş / Əməkhaqqı', 'tr': 'Maaş', 'en': 'Salary', 'ru': 'Зарплата'},
    'Salary': {'az': 'Maaş / Əməkhaqqı', 'tr': 'Maaş', 'en': 'Salary', 'ru': 'Зарплата'},
    'Freelance': {'az': 'Frilans / Sərbəst İş', 'tr': 'Freelance', 'en': 'Freelance', 'ru': 'Фриланс'},
    'Yatırım': {'az': 'İnvestisiya', 'tr': 'Yatırım', 'en': 'Investment', 'ru': 'Инвестиции'},
    'Investment': {'az': 'İnvestisiya', 'tr': 'Yatırım', 'en': 'Investment', 'ru': 'Инвестиции'},
    'Kira Geliri': {'az': 'Kirayə Gəliri', 'tr': 'Kira Geliri', 'en': 'Rental Income', 'ru': 'Доход от аренды'},
    'Hediye': {'az': 'Hədiyyə', 'tr': 'Hediye', 'en': 'Gift', 'ru': 'Подарок'},
    'Gift': {'az': 'Hədiyyə', 'tr': 'Hediye', 'en': 'Gift', 'ru': 'Подарок'},
    'Diğer Gelir': {'az': 'Digər Gəlir', 'tr': 'Diğer Gelir', 'en': 'Other Income', 'ru': 'Другой доход'},
    'Tasarruf': {'az': 'Qənaət', 'tr': 'Tasarruf', 'en': 'Savings', 'ru': 'Сбережения'},
    'Savings': {'az': 'Qənaət', 'tr': 'Tasarruf', 'en': 'Savings', 'ru': 'Сбережения'},
    'Birikim': {'az': 'Yığım / İnvestisiya', 'tr': 'Birikim', 'en': 'Accumulation', 'ru': 'Накопления'},
    'Varlık / Servet': {'az': 'Aktiv / Sərvət', 'tr': 'Varlık / Servet', 'en': 'Asset / Wealth', 'ru': 'Активы / Капитал'},
    'Diğer': {'az': 'Digər', 'tr': 'Diğer', 'en': 'Other', 'ru': 'Другое'},
    'Other': {'az': 'Digər', 'tr': 'Diğer', 'en': 'Other', 'ru': 'Другое'},

    // Daily Summary Card
    'summary_empty_msg': {'az': 'Bu gün hələ kassaya hərəkət yansımayıb. Pulqabın hüzurludur 🧘‍♂️', 'tr': 'Bugün henüz kasaya bir hareket yansımadı. Cüzdanın huzurlu 🧘‍♂️', 'en': 'No transactions recorded today. Your wallet is peaceful 🧘‍♂️', 'ru': 'Сегодня транзакций не было. Ваш кошелек спокоен 🧘‍♂️'},
    'summary_great_title': {'az': '🔥 Əla Gedirsən!', 'tr': '🔥 Harika Gidiyorsun!', 'en': '🔥 Doing Great!', 'ru': '🔥 Отлично справляетесь!'},
    'summary_great_msg': {'az': 'Bu gün kassaya pozitiv nağd axını etdin. Gələcəyini inşa edirsən!', 'tr': 'Bugün kasaya pozitif nakit akışı girdin. Geleceğini inşa ediyorsun!', 'en': 'You had positive cash flow today. Building your future!', 'ru': 'Сегодня у вас положительный денежный поток. Строите свое будущее!'},
    'summary_invest_title': {'az': '⚡ İnvestisiya və Ödəniş Günü', 'tr': '⚡ Yatırım ve Ödeme Günü', 'en': '⚡ Investment & Payment Day', 'ru': '⚡ День инвестиций и платежей'},
    'summary_invest_msg': {'az': 'Bu gün çıxışlar çoxluq təşkil edir. Hədəflərini planla, büdcəni nəzarətdə saxla.', 'tr': 'Bugün çıkışlar ağırlıklı. Hedeflerini planla, bütçeni kontrol altında tut.', 'en': 'Outflows are dominant today. Plan your goals, keep budget under control.', 'ru': 'Сегодня преобладают расходы. Планируйте свои цели, контролируйте бюджет.'},
    'summary_balance_title': {'az': '⚖️ Balanslı Gün', 'tr': '⚖️ Dengeli Gün', 'en': '⚖️ Balanced Day', 'ru': '⚖️ Сбалансированный день'},
    'summary_balance_msg': {'az': 'Bugünkü gəlir və xərc tam balansdadır.', 'tr': 'Bugünkü gelir ve gider tam dengede seyrediyor.', 'en': 'Today\'s income and expense are perfectly balanced.', 'ru': 'Сегодняшние доходы и расходы идеально сбалансированы.'},
    'today_income': {'az': 'Bu Gün Gəlir', 'tr': 'Bugün Gelir', 'en': 'Income Today', 'ru': 'Доход за сегодня'},
    'today_expense': {'az': 'Bu Gün Xərc', 'tr': 'Bugün Gider', 'en': 'Expense Today', 'ru': 'Расход за сегодня'},
    'net_status': {'az': 'Xalis Vəziyyət', 'tr': 'Net Durum', 'en': 'Net Status', 'ru': 'Чистый статус'},
    'slogan': {'az': 'Pulunu Anla · Gələcəyi Planla', 'tr': 'Paranı Anla · Geleceği Planla', 'en': 'Understand Money · Plan Future', 'ru': 'Пойми деньги · Планируй будущее'},
    'share': {'az': 'Paylaş', 'tr': 'Paylaş', 'en': 'Share', 'ru': 'Поделиться'},
    'share_ready': {'az': 'Günün xülasəsi paylaşıma hazırdır! 🚀', 'tr': 'Günün özeti paylaşıma hazır! 🚀', 'en': 'Daily summary ready to share! 🚀', 'ru': 'Сводка дня готова к отправке! 🚀'},
  };

  String t(String key) {
    if (!_translations.containsKey(key)) return key;
    return _translations[key]![_currentLang] ?? _translations[key]!['az'] ?? key;
  }

  String translateCategory(String cat) {
    if (cat.isEmpty) return cat;
    final parts = cat.trim().split(' ');
    if (parts.length > 1) {
      final possibleEmoji = parts.first;
      final rest = parts.sublist(1).join(' ');
      if (_translations.containsKey(rest)) {
        return '$possibleEmoji ${t(rest)}';
      }
    }
    return t(cat);
  }
}
