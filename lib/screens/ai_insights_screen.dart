import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

/// AI Insights screen.
class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  final _questionCtrl = TextEditingController();

  List<String> _insights = [];
  String _answer = '';
  bool _loadingInsights = false;
  bool _loadingAnswer = false;

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInsights() async {
    setState(() => _loadingInsights = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _insights = [
          'Finansal asistan yapay zeka analizleri ve önerileri çok yakında devrede olacak.',
          'Harcamalarınızı kategorilere göre takip etmek gereksiz giderleri %20 azaltabilir.',
          'Her ay gelirinizin %15\'ini otomatik olarak birikim hedeflerine ayırmayı deneyin.',
        ];
        _loadingInsights = false;
      });
    }
  }

  Future<void> _askQuestion() async {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _loadingAnswer = true;
      _answer = '';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    const fullAnswer =
        'Yapay zeka finans danışmanınız harcamalarınızı ve varlıklarınızı analiz ederek size özel tasarruf ve yatırım tavsiyeleri sunacak.';

    if (mounted) {
      setState(() => _loadingAnswer = false);
    }

    for (int i = 0; i < fullAnswer.length; i++) {
      await Future.delayed(const Duration(milliseconds: 14));
      if (mounted) {
        setState(() => _answer = fullAnswer.substring(0, i + 1));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final inputBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Insights section
          Text(
            locale.t('ai_suggestions'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

          if (_loadingInsights)
            const Center(child: CircularProgressIndicator())
          else
            ..._insights.map((insight) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF4C1D95).withAlpha(64) : AppColors.accentPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accentPurple.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: AppColors.accentPurple),
                          SizedBox(width: 6),
                          Text(
                            'Akıllı Analiz',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        insight,
                        style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Ask question
          Text(
            locale.t('ask_financial_advisor'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _questionCtrl,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Bütçemi nasıl daha verimli yönetirim?...',
              hintStyle: TextStyle(color: subColor),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadingAnswer ? null : _askQuestion,
            icon: const Icon(Icons.send_rounded, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            label: _loadingAnswer
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sorunu İlet & Tavsiye Al', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),

          const SizedBox(height: 16),
          if (_answer.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.accentTeal),
                      SizedBox(width: 6),
                      Text('AI Yanıtı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentTeal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _answer,
                    style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
