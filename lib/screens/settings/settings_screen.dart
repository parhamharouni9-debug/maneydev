import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/app_state.dart';
import '../auth/login_screen.dart';
import '../goals/goals_screen.dart';
import '../home/history_screen.dart';
import '../../theme/theme_controller.dart';
import '../../utils/friendly_error.dart';
import '../../widgets/theme_rebuilder.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _logout(BuildContext context) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('حذف حساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'همه اطلاعات مالی شما برای همیشه پاک می‌شود. رمز عبور را برای تایید وارد کن.',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'رمز عبور'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف برای همیشه',
                style: TextStyle(color: AppColors.magenta)),
          ),
        ],
      ),
    );
    final password = controller.text;
    controller.dispose();
    if (confirmed != true || password.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.deleteAccount(password);
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetMonth(BuildContext context) async {
    final app = AppState.instance;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('پاک‌سازی این ماه؟'),
        content: Text('همه تراکنش‌های ${app.monthLabel} حذف می‌شوند.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('پاک‌سازی', style: TextStyle(color: AppColors.magenta)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        await app.resetCurrentMonth();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تراکنش‌های ${app.monthLabel} پاک شد')),
          );
        }
      } catch (error) {
        if (mounted) setState(() => _error = friendlyError(error));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return ThemeRebuilder(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.bg,
              appBar: AppBar(title: const Text('تنظیمات')),
              body: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  if (_busy) LinearProgressIndicator(color: AppColors.cyan),
                  if (_error != null)
                    Card(
                      color: AppColors.magenta.withValues(alpha: 0.08),
                      child: ListTile(
                        leading:
                            Icon(Icons.error_outline, color: AppColors.magenta),
                        title: Text(_error!),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _error = null),
                        ),
                      ),
                    ),
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(user.email,
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  _themeTile(),
                  _tile(
                    icon: Icons.flag_outlined,
                    label: 'هدف مالی این ماه',
                    onTap: _busy
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const GoalsScreen()),
                            ),
                  ),
                  _tile(
                    icon: Icons.history_rounded,
                    label: 'تاریخچه ماه‌ها',
                    onTap: _busy
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const HistoryScreen()),
                            ),
                  ),
                  _tile(
                    icon: Icons.restart_alt_rounded,
                    label: 'پاک‌سازی تراکنش‌های این ماه',
                    onTap: _busy ? null : () => _resetMonth(context),
                  ),
                  _tile(
                    icon: Icons.logout_rounded,
                    label: 'خروج از حساب',
                    onTap: _busy ? null : () => _logout(context),
                  ),
                  const SizedBox(height: 18),
                  Text('منطقه خطر',
                      style: TextStyle(
                          color: AppColors.magenta,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _tile(
                    icon: Icons.delete_forever_outlined,
                    label: 'حذف حساب کاربری',
                    color: AppColors.magenta,
                    onTap: _busy ? null : () => _confirmDeleteAccount(context),
                  ),
                ],
              ),
            ));
  }

  Widget _themeTile() {
    final isDark = ThemeController.instance.isDark;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        secondary: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
          color: isDark ? AppColors.cyan : AppColors.warning,
        ),
        title: const Text('تم تاریک'),
        subtitle: Text(
          isDark ? 'روشن کن تا تم تبدیل به روشن بشه' : 'الان تم روشنه',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        value: isDark,
        activeThumbColor: AppColors.cyan,
        onChanged: _busy ? null : (_) => ThemeController.instance.toggle(),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? color,
  }) {
    final resolvedColor = color ?? AppColors.text;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: resolvedColor),
        title: Text(label, style: TextStyle(color: resolvedColor)),
        trailing: Icon(Icons.chevron_left_rounded, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}
