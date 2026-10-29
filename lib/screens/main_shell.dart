import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/workspace_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';
import 'ai_insights_screen.dart';
import 'recurring_payments_screen.dart';
import 'assets_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.home_outlined,                 activeIcon: Icons.home,                 labelKey: 'home'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, labelKey: 'wealth'),
    _NavItem(icon: Icons.swap_horiz_outlined,           activeIcon: Icons.swap_horiz,           labelKey: 'transactions'),
    _NavItem(icon: Icons.pie_chart_outline,             activeIcon: Icons.pie_chart,            labelKey: 'budget'),
    _NavItem(icon: Icons.flag_outlined,                 activeIcon: Icons.flag,                 labelKey: 'goals'),
    _NavItem(icon: Icons.repeat_outlined,               activeIcon: Icons.repeat,               labelKey: 'recurring'),
    _NavItem(icon: Icons.auto_awesome_outlined,         activeIcon: Icons.auto_awesome,         labelKey: 'ai_insights'),
  ];

  static const _screens = [
    DashboardScreen(),
    AssetsScreen(),
    TransactionsScreen(),
    BudgetScreen(),
    GoalsScreen(),
    RecurringPaymentsScreen(),
    AIInsightsScreen(),
  ];

  void _showWorkspaceBottomSheet(BuildContext context, WorkspaceProvider workspace, LocaleProvider locale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(locale.t('select_workspace_title'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: subColor)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(locale.t('isolate_workspaces_sub'), style: TextStyle(fontSize: 13, color: subColor)),
                const SizedBox(height: 18),
                ...workspace.workspaces.map((item) {
                  final isSelected = workspace.currentItem.id == item.id;
                  final itemTitle = item.id == 'personal'
                      ? locale.t('personal_ws')
                      : item.id == 'business'
                          ? locale.t('business_ws')
                          : item.name;
                  final itemSub = item.id == 'personal'
                      ? locale.t('personal_ws_sub')
                      : item.id == 'business'
                          ? locale.t('business_ws_sub')
                          : locale.t('custom_ws_sub');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WorkspaceTile(
                      emoji: item.emoji,
                      title: itemTitle,
                      subtitle: itemSub,
                      isSelected: isSelected,
                      color: item.color,
                      onTap: () {
                        workspace.setWorkspaceById(item.id);
                        Navigator.pop(ctx);
                        AppToast.show(context, '${item.name} kasasına geçildi ${item.emoji}');
                      },
                      onEdit: () {
                        Navigator.pop(ctx);
                        _showEditWorkspaceDialog(context, workspace, item);
                      },
                      onDelete: item.id == 'personal'
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _showDeleteWorkspaceDialog(context, workspace, item);
                            },
                    ),
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.accentPurple.withOpacity(0.8), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.accentPurple),
                    label: Text(
                      locale.t('add_new_workspace'),
                      style: const TextStyle(color: AppColors.accentPurple, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddWorkspaceDialog(context, workspace);
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddWorkspaceDialog(BuildContext context, WorkspaceProvider workspace) {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController(text: '🚀');

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.dark800 : AppColors.light800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yeni Çalışma Alanı Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Kasa / Proje Adı',
                    hintText: 'Örn: E-Ticaret Projesi, Tatil Fonu',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emojiCtrl,
                  maxLength: 2,
                  decoration: InputDecoration(
                    labelText: 'İkon / Emoji',
                    hintText: 'Örn: 🛒, 🏖️, 💻',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final emoji = emojiCtrl.text.trim();
                if (name.isNotEmpty) {
                  workspace.addWorkspace(name, emoji);
                  Navigator.pop(ctx);
                  AppToast.show(context, '$name çalışma alanı oluşturuldu $emoji');
                }
              },
              child: const Text('Oluştur & Geç', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditWorkspaceDialog(BuildContext context, WorkspaceProvider workspace, WorkspaceItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final emojiCtrl = TextEditingController(text: item.emoji);

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.dark800 : AppColors.light800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Çalışma Alanını Düzenle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Kasa / Proje Adı',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emojiCtrl,
                  maxLength: 2,
                  decoration: InputDecoration(
                    labelText: 'İkon / Emoji',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final emoji = emojiCtrl.text.trim();
                if (name.isNotEmpty) {
                  workspace.updateWorkspace(item.id, name, emoji);
                  Navigator.pop(ctx);
                  AppToast.show(context, 'Çalışma alanı güncellendi 🚀');
                }
              },
              child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteWorkspaceDialog(BuildContext context, WorkspaceProvider workspace, WorkspaceItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.dark800 : AppColors.light800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.accentRed),
              SizedBox(width: 8),
              Text('Çalışma Alanını Sil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text('${item.emoji} ${item.name} kasasını silmek istediğinize emin misiniz? Bu kasaya ait önceden eklenen veriler izole ön ekte kalır.', style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                Navigator.pop(ctx);
                final deleted = await workspace.deleteWorkspace(item.id);
                if (deleted) {
                  AppToast.show(context, '${item.name} çalışma alanı silindi 🗑️');
                } else {
                  AppToast.show(context, 'Ana cüzdan silinemez!');
                }
              },
              child: const Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showLocaleAndCurrencyModal(BuildContext context, LocaleProvider locale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final inputBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setStateModal) {
            final modalLocale = modalCtx.watch<LocaleProvider>();
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.language_rounded, color: AppColors.accentCyan, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            modalLocale.t('lang_currency_settings'),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.pop(modalCtx), icon: Icon(Icons.close, color: subColor)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      modalLocale.t('select_lang'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subColor),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        _buildLangOption('az', 'Azərbaycan', '🇦🇿', modalLocale, inputBg, textColor, setStateModal),
                        _buildLangOption('tr', 'Türkçe', '🇹🇷', modalLocale, inputBg, textColor, setStateModal),
                        _buildLangOption('en', 'English', '🇬🇧', modalLocale, inputBg, textColor, setStateModal),
                        _buildLangOption('ru', 'Русский', '🇷🇺', modalLocale, inputBg, textColor, setStateModal),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      modalLocale.t('select_currency'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subColor),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        _buildCurrOption('AZN', 'Manat (₼)', modalLocale, inputBg, textColor, setStateModal),
                        _buildCurrOption('TL', 'Türk Lirası (₺)', modalLocale, inputBg, textColor, setStateModal),
                        _buildCurrOption('USD', 'Dolar (\$)', modalLocale, inputBg, textColor, setStateModal),
                        _buildCurrOption('EUR', 'Euro (€)', modalLocale, inputBg, textColor, setStateModal),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          modalLocale.t('save'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLangOption(String code, String name, String flag, LocaleProvider locale, Color bg, Color textColor, StateSetter setStateModal) {
    final isSelected = locale.currentLang == code;
    return GestureDetector(
      onTap: () {
        locale.setLanguage(code);
        setStateModal(() {});
        setState(() {});
        AppToast.show(context, '$flag $name');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPurple.withOpacity(0.18) : bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.accentPurple : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? AppColors.accentPurple : textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrOption(String code, String name, LocaleProvider locale, Color bg, Color textColor, StateSetter setStateModal) {
    final isSelected = locale.currentCurrency == code;
    return GestureDetector(
      onTap: () {
        locale.setCurrency(code);
        setStateModal(() {});
        setState(() {});
        AppToast.show(context, 'Para birimi: $code');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGreen.withOpacity(0.18) : bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.accentGreen : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentGreen : AppColors.accentPurple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                code == 'USD' ? '\$' : code == 'EUR' ? '€' : code == 'TL' ? '₺' : '₼',
                style: TextStyle(color: isSelected ? Colors.white : AppColors.accentPurple, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? AppColors.accentGreen : textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarProfileMenu(BuildContext context, WorkspaceProvider workspace, AppAuthProvider auth, LocaleProvider locale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.accentPurple.withOpacity(0.2),
                  child: const Text('👑', style: TextStyle(fontSize: 30)),
                ),
                const SizedBox(height: 10),
                Text(
                  auth.user?.email ?? 'Baywise Üyesi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                Text(
                  '${locale.t('active_wallet')}: ${workspace.currentItem.id == 'personal' ? locale.t('personal_ws') : workspace.currentItem.id == 'business' ? locale.t('business_ws') : workspace.workspaceName}',
                  style: TextStyle(fontSize: 13, color: workspace.workspaceColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                const Divider(),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.account_balance_wallet, color: AppColors.accentTeal),
                  title: Text(locale.t('my_assets'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentIndex = 1); // Servet ekrani
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.swap_calls_rounded, color: AppColors.accentPurple),
                  title: Text(locale.t('switch_workspace'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: Text(workspace.workspaceEmoji, style: const TextStyle(fontSize: 18)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showWorkspaceBottomSheet(context, workspace, locale);
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.language_rounded, color: AppColors.accentCyan),
                  title: Text(locale.t('lang_currency_settings'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: Text('${locale.currentLang.toUpperCase()} / ${locale.currentCurrency}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentCyan)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showLocaleAndCurrencyModal(context, locale);
                  },
                ),
                const Divider(),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.logout, color: AppColors.accentRed),
                  title: Text(locale.t('logout'), style: const TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    auth.logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final workspace = context.watch<WorkspaceProvider>();
    final locale = context.watch<LocaleProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      color: isDark ? AppColors.dark900 : AppColors.light900,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        titleSpacing: 16,
        title: InkWell(
          onTap: () => _showWorkspaceBottomSheet(context, workspace, locale),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: workspace.workspaceColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: workspace.workspaceColor, width: 1.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${workspace.workspaceEmoji} ${workspace.currentItem.id == 'personal' ? locale.t('personal_ws') : workspace.currentItem.id == 'business' ? locale.t('business_ws') : workspace.workspaceName}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: workspace.workspaceColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: workspace.workspaceColor,
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => _showLocaleAndCurrencyModal(context, locale),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentCyan.withOpacity(0.6), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      locale.currentLang.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      locale.currencySymbol,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? AppColors.accentAmber : AppColors.accentPurple,
              size: 24,
            ),
            onPressed: () => context.read<ThemeProvider>().toggle(),
            tooltip: isDark ? 'Aydınlık Tema' : 'Karanlık Tema',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: GestureDetector(
              onTap: () => _showAvatarProfileMenu(context, workspace, auth, locale),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentPurple, AppColors.accentTeal],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.accentPurple.withOpacity(0.3), blurRadius: 6),
                  ],
                ),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: isDark ? AppColors.dark800 : AppColors.light800,
                  child: const Text('👑', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: KeyedSubtree(
        key: ValueKey(_currentIndex),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark800 : AppColors.light800,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.dark700 : AppColors.light600,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isActive = i == _currentIndex;
                final unselectedColor = isDark ? AppColors.dark400 : AppColors.light400;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive
                              ? AppColors.accentPurple
                              : unselectedColor,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          locale.t(item.labelKey),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive
                                ? AppColors.accentPurple
                                : unselectedColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    ));
  }
}

class _WorkspaceTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _WorkspaceTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return InkWell(
      onTap: this.onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: this.isSelected ? this.color.withOpacity(0.15) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: this.isSelected ? this.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: this.isSelected ? this.color.withOpacity(0.2) : (isDark ? AppColors.dark800 : AppColors.light800),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(this.emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(this.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: this.isSelected ? this.color : textColor)),
                  const SizedBox(height: 2),
                  Text(this.subtitle, style: TextStyle(fontSize: 11, color: subColor)),
                ],
              ),
            ),
            if (this.onEdit != null)
              IconButton(
                onPressed: this.onEdit,
                icon: const Icon(Icons.edit_outlined, size: 19),
                color: subColor,
                tooltip: 'Düzenle',
              ),
            if (this.onDelete != null)
              IconButton(
                onPressed: this.onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                color: AppColors.accentRed,
                tooltip: 'Sil',
              ),
            const SizedBox(width: 4),
            if (this.isSelected)
              Icon(Icons.check_circle, color: this.color, size: 24)
            else
              Icon(Icons.circle_outlined, color: subColor, size: 24),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
  });
}
