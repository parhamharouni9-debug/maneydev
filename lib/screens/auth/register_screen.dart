import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/friendly_error.dart';
import '../../widgets/auth_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_text_field.dart';
import '../../widgets/bear_mascot.dart';
import '../../widgets/theme_rebuilder.dart';
import '../home/app_entry_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _bearKey = GlobalKey<BearMascotState>();
  bool _loading = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
      );
      _bearKey.currentState?.playSuccess();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppEntryScreen()),
      );
    } catch (e) {
      _bearKey.currentState?.playFail();
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeRebuilder(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.bg,
              body: AuthBackground(
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 32),
                      child: GlassCard(
                        borderRadius: 26,
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('پول من',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                )),
                            const SizedBox(height: 6),
                            Text('حساب جدید بساز',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 13.5)),
                            const SizedBox(height: 12),
                            Center(
                              child: BearMascot(
                                key: _bearKey,
                                checking: _emailFocused,
                                lookX: _emailFocused ? 0.4 : 0,
                                coverEyes: _passwordFocused,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GlassTextField(
                                controller: _name,
                                label: 'نام',
                                icon: Icons.person_outline_rounded),
                            const SizedBox(height: 14),
                            GlassTextField(
                              controller: _email,
                              label: 'ایمیل',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              onFocusChange: (focused) =>
                                  setState(() => _emailFocused = focused),
                            ),
                            const SizedBox(height: 14),
                            GlassTextField(
                              controller: _pass,
                              label: 'رمز عبور (حداقل ۸ کاراکتر)',
                              icon: Icons.lock_outline_rounded,
                              obscureText: true,
                              onFocusChange: (focused) =>
                                  setState(() => _passwordFocused = focused),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Text(_error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 12.5)),
                            ],
                            const SizedBox(height: 22),
                            ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppColors.bg))
                                  : const Text('ثبت‌نام'),
                            ),
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                      color: AppColors.muted, fontSize: 13),
                                  children: [
                                    const TextSpan(text: 'اکانت داری؟ '),
                                    TextSpan(
                                      text: 'وارد شو',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ));
  }
}
