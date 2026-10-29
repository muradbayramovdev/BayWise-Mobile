import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegister = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = context.read<AppAuthProvider>();
      if (_isRegister) {
        await auth.registerWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        await auth.loginWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await context.read<AppAuthProvider>().loginWithGoogle();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subTextColor = isDark ? AppColors.dark400 : AppColors.light400;
    final borderColor = isDark ? AppColors.dark600 : AppColors.light600;
    final dividerColor = isDark ? AppColors.dark700 : AppColors.light600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Özel İkon / Gösterge (Yükselen Ok Banner)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accentPurple, AppColors.accentTeal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentPurple.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Logo / Başlık
                  Text(
                    'Baywise',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Özel Karşılama Sözü (Slogan - Vurgulu & Büyük)
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: textColor,
                      ),
                      children: [
                        const TextSpan(text: '"Paranı '),
                        TextSpan(
                          text: 'anla',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 23,
                            color: isDark ? AppColors.accentTeal : AppColors.accentPurple,
                            decoration: TextDecoration.underline,
                            decorationColor: (isDark ? AppColors.accentTeal : AppColors.accentPurple).withOpacity(0.5),
                          ),
                        ),
                        const TextSpan(text: ',\ngeleceğini '),
                        TextSpan(
                          text: 'planla',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 23,
                            color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9),
                            decoration: TextDecoration.underline,
                            decorationColor: (isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9)).withOpacity(0.5),
                          ),
                        ),
                        const TextSpan(text: '"'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  Text(
                    _isRegister ? 'Yeni bir finansal başlangıç için kayıt ol' : 'Gelişmiş varlık ve bütçe takibi için giriş yap',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Google ile giriş/kayıt
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _googleSignIn,
                    icon: Icon(Icons.g_mobiledata, size: 28, color: textColor),
                    label: Text(
                      'Google ile Devam Et',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('veya e-posta ile', style: TextStyle(color: subTextColor, fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: dividerColor)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // E-posta / Şifre Formu
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'E-posta Adresi',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          validator: (v) =>
                              (v == null || !v.contains('@')) ? 'Geçerli bir e-posta adresi giriniz' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Şifre',
                            prefixIcon: Icon(Icons.lock_outline, size: 20),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 6) ? 'En az 6 karakter olmalıdır' : null,
                        ),
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.accentRed, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            _isRegister ? 'Kayıt Ol ve Başla' : 'Giriş Yap',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister ? 'Zaten hesabınız var mı? Giriş Yapın' : 'Henüz hesabınız yok mu? Kayıt Olun',
                      style: TextStyle(
                        color: isDark ? AppColors.dark200 : AppColors.light200,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
