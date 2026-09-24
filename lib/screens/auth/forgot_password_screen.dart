import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/friendly_error.dart';
import '../../widgets/auth_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_text_field.dart';
import '../../widgets/theme_rebuilder.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { email, otp, newPassword, done }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Step _step = _Step.email;
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPass = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _resetToken;

  Future<void> _requestOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.requestResetOtp(_email.text.trim());
      if (mounted) setState(() => _step = _Step.otp);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _resetToken = await AuthService.instance
          .checkResetOtp(email: _email.text.trim(), code: _code.text.trim());
      if (mounted) setState(() => _step = _Step.newPassword);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.resetPassword(
        email: _email.text.trim(),
        resetToken: _resetToken!,
        newPassword: _newPass.text,
      );
      if (mounted) setState(() => _step = _Step.done);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeRebuilder(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.bg,
              body: AuthBackground(
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                        child: Row(children: [
                          IconButton(
                            icon: Icon(Icons.arrow_forward_rounded,
                                color: AppColors.text),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ]),
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 12),
                            child: GlassCard(
                              borderRadius: 26,
                              padding: const EdgeInsets.all(26),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('بازیابی رمز عبور',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      )),
                                  const SizedBox(height: 8),
                                  Text(_subtitle(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 13)),
                                  const SizedBox(height: 26),
                                  _buildStep(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ));
  }

  String _subtitle() {
    switch (_step) {
      case _Step.email:
        return 'ایمیل حسابت رو وارد کن';
      case _Step.otp:
        return 'کد تأیید ارسال شد';
      case _Step.newPassword:
        return 'رمز عبور جدید رو انتخاب کن';
      case _Step.done:
        return 'رمز عبورت آماده‌ست';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.email:
        return _form(
          fields: [
            GlassTextField(
              controller: _email,
              label: 'ایمیل حساب',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
          buttonLabel: 'ارسال کد',
          onSubmit: _requestOtp,
        );
      case _Step.otp:
        return _form(
          fields: [
            Text('کد ۶ رقمی ارسال‌شده به ${_email.text} را وارد کن',
                style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22, letterSpacing: 8, color: AppColors.text),
              decoration: InputDecoration(
                labelText: 'کد تایید',
                filled: true,
                fillColor: AppColors.cardBg.withValues(alpha: 0.6),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
          buttonLabel: 'تایید کد',
          onSubmit: _checkOtp,
        );
      case _Step.newPassword:
        return _form(
          fields: [
            GlassTextField(
              controller: _newPass,
              label: 'رمز عبور جدید (حداقل ۸ کاراکتر)',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
            ),
          ],
          buttonLabel: 'ثبت رمز جدید',
          onSubmit: _resetPassword,
        );
      case _Step.done:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 58),
            const SizedBox(height: 14),
            Text('رمز عبور با موفقیت تغییر کرد',
                style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('بازگشت به صفحه ورود'),
            ),
          ],
        );
    }
  }

  Widget _form({
    required List<Widget> fields,
    required String buttonLabel,
    required VoidCallback onSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...fields,
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary, fontSize: 12.5)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : onSubmit,
          child: _loading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.bg))
              : Text(buttonLabel),
        ),
      ],
    );
  }
}
