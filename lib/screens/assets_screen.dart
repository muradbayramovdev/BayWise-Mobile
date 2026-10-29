import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_toast.dart';
import '../widgets/unified_add_button.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _firestore = FirestoreService();
  String _filter = 'Tümü';

  String get _uid => context.read<AppAuthProvider>().user!.uid;

  void _openModal({AssetModel? existingAsset}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssetModal(
        uid: _uid,
        firestore: _firestore,
        existingAsset: existingAsset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final locale = context.watch<LocaleProvider>();
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final iconBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text('${locale.t('my_assets')} & ${locale.t('net_worth')}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: scaffoldBg,
        elevation: 0,
      ),
      body: StreamBuilder<List<AssetModel>>(
        stream: _firestore.streamAssets(_uid),
        builder: (context, snap) {
          final assets = snap.data ?? [];

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalPositive = assets.where((a) => a.category != 'Borç / Kredi (-)').fold(0.0, (sum, a) => sum + a.totalTlValue);
          final totalNegative = assets.where((a) => a.category == 'Borç / Kredi (-)').fold(0.0, (sum, a) => sum + a.totalTlValue); // bu eksi döner veya mutlak alınabilir
          final netWorth = totalPositive + totalNegative;

          final filteredAssets = assets.where((a) {
            if (_filter == locale.t('assets_real_estate')) return a.category == 'Gayrimenkul / Arsa';
            if (_filter == locale.t('assets_vehicle')) return a.category == 'Araç / Taşıt';
            if (_filter == locale.t('assets_investment')) {
              return a.category == 'Altın / Döviz / Yatırım' ||
                  a.category == 'Hisse Senedi / Fon' ||
                  a.category == 'Mevduat / Nakit' ||
                  a.category == 'Kripto Varlıklar';
            }
            if (_filter == locale.t('assets_debt')) return a.category == 'Borç / Kredi (-)';
            return true;
          }).toList();

          return Column(
            children: [
              // Net Servet Özeti Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x330F766E), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(locale.t('toplam_net_servet'), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    Text(
                      '${locale.currencySymbol} ${netWorth.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(locale.t('assets_title'), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text('+ ${locale.currencySymbol} ${totalPositive.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(height: 28, width: 1, color: Colors.white24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(locale.t('borclar_krediler'), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text('- ${locale.currencySymbol} ${totalNegative.abs().toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filtre Chip'leri
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [locale.t('all'), locale.t('assets_real_estate'), locale.t('assets_vehicle'), locale.t('assets_investment'), locale.t('assets_debt')].map((f) {
                    final isActive = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.accentTeal : cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: isActive ? null : Border.all(color: subColor.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? Colors.white : textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Varlık Listesi
              Expanded(
                child: filteredAssets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏡🚗🥇', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              assets.isEmpty ? 'Henüz varlık veya borç kaydetmediniz' : 'Bu filtrede varlık bulunamadı',
                              style: TextStyle(color: subColor, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            if (assets.isEmpty) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  locale.t('assets_empty_msg'),
                                  style: TextStyle(color: subColor.withOpacity(0.8), fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => _openModal(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Yeni Varlık Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredAssets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final a = filteredAssets[i];
                          final isDebt = a.category == 'Borç / Kredi (-)';
                          final emoji = kAssetEmojis[a.category] ?? '💎';
                          final amountColor = isDebt ? AppColors.accentRed : AppColors.accentGreen;
                          final sign = isDebt ? '-' : '+';

                          return Dismissible(
                            key: ValueKey(a.id),
                            direction: DismissDirection.horizontal,
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              decoration: BoxDecoration(
                                color: AppColors.accentTeal,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 26),
                            ),
                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.accentRed,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                            ),
                            confirmDismiss: (dir) async {
                              if (dir == DismissDirection.startToEnd) {
                                _openModal(existingAsset: a);
                                return false;
                              } else {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: cardBg,
                                    title: Text('Varlığı Sil', style: TextStyle(color: textColor)),
                                    content: Text('"${a.name}" kaydını silmek istediğinize emin misiniz?', style: TextStyle(color: subColor)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
                                        child: const Text('Sil'),
                                      ),
                                    ],
                                  ),
                                ) ?? false;
                              }
                            },
                            onDismissed: (dir) async {
                              if (dir == DismissDirection.endToStart) {
                                await _firestore.deleteAsset(_uid, a.id);
                                if (mounted) AppToast.show(context, 'Varlık kaydı silindi');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: !isDark ? Border.all(color: AppColors.light600) : null,
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Center(
                                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.name.isEmpty ? locale.t('no_asset_name') : a.name,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${locale.translateCategory(a.category)}${a.note.isNotEmpty ? ' · ${a.note}' : ''}',
                                          style: TextStyle(fontSize: 12, color: subColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$sign ${locale.currencySymbol} ${a.totalTlValue.abs().toStringAsFixed(2)}',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: amountColor),
                                      ),
                                      if (a.currency != '₺' && a.amount != 1.0)
                                        Text(
                                          '(${a.amount} ${a.currency})',
                                          style: TextStyle(fontSize: 11, color: subColor),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: UnifiedAddButton(
        label: '+ ${locale.t('my_assets')}',
        onPressed: () => _openModal(),
      ),
    );
  }
}

class _AssetModal extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;
  final AssetModel? existingAsset;

  const _AssetModal({
    required this.uid,
    required this.firestore,
    this.existingAsset,
  });

  @override
  State<_AssetModal> createState() => _AssetModalState();
}

class _AssetModalState extends State<_AssetModal> {
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '1.0');
  final _rateCtrl = TextEditingController(text: '1.0');
  final _noteCtrl = TextEditingController();

  String _category = kAssetCategories.first;
  String _currency = '₺';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAsset != null) {
      final a = widget.existingAsset!;
      _nameCtrl.text = a.name;
      _valueCtrl.text = a.value.toString();
      _amountCtrl.text = a.amount.toString();
      _rateCtrl.text = a.exchangeRate.toString();
      _noteCtrl.text = a.note;
      _category = a.category;
      _currency = a.currency;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppToast.show(context, 'Lütfen varlık adı girin (Örn: Silivri Arsa)', isError: true);
      return;
    }
    final value = double.tryParse(_valueCtrl.text.trim()) ?? 0.0;
    if (value <= 0) {
      AppToast.show(context, 'Lütfen tahmini değeri girin', isError: true);
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 1.0;
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 1.0;

    setState(() => _isLoading = true);

    try {
      final payload = {
        'uid': widget.uid,
        'name': name,
        'category': _category,
        'value': value,
        'currency': _currency,
        'amount': amount,
        'exchangeRate': _currency == '₺' ? 1.0 : rate,
        'note': _noteCtrl.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (widget.existingAsset != null) {
        widget.firestore.updateAsset(widget.uid, widget.existingAsset!.id, payload);
      } else {
        widget.firestore.addAsset(widget.uid, payload);
      }
      if (mounted) {
        AppToast.show(context, widget.existingAsset != null ? 'Varlık güncellendi ✓' : 'Varlık eklendi ✓');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Hata oluştu: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final inputBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: subColor.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existingAsset != null ? 'Varlığı / Serveti Düzenle' : 'Yeni Varlık / Borç Ekle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 16),

            // Kategori Seçimi
            Text('Kategori Türü', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subColor)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  dropdownColor: cardBg,
                  isExpanded: true,
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                  items: kAssetCategories.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Text(kAssetEmojis[c] ?? '💎', style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(c),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Varlık Adı
            Text('Varlık Adı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: locale.t('assets_hint'),
                hintStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Tahmini Değer & Para Birimi
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tahmini Değer (TL / Döviz / Birim)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _valueCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: subColor),
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Para Birimi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subColor)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _currency,
                            dropdownColor: cardBg,
                            isExpanded: true,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                            items: ['₺', '\$ (USD)', '€ (EUR)', 'Gr Altın', 'Adet'].map((cur) {
                              return DropdownMenuItem(value: cur, child: Text(cur));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _currency = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_currency != '₺') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Miktar (Adet / Gr / \$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subColor)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TL Kuru / Değeri', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subColor)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _rateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // Not / Detay
            Text('Not / Açıklama (Opsiyonel)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Örn: Kazasız 2023 model, Silivri sahile 2 km',
                hintStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      widget.existingAsset != null ? 'Değişiklikleri Kaydet' : 'Varlığı Kaydet',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
