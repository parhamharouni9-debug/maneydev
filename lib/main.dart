import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'services/auth_service.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/app_entry_screen.dart';
import 'utils/friendly_error.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF0F1115),
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  ));
  runApp(const PoolManApp());
}

class PoolManApp extends StatefulWidget {
  const PoolManApp({super.key});

  @override
  State<PoolManApp> createState() => _PoolManAppState();
}

class _PoolManAppState extends State<PoolManApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChange);
    ThemeController.instance.load();
  }

  void _onThemeChange() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پول من',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeController.instance.mode,
      locale: const Locale('fa', 'IR'),
      // RTL is forced regardless of device locale, matching the PWA's dir="rtl".
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const _SessionResolver(),
    );
  }
}

/// Decides whether to show the auth flow or drop straight into the app,
/// based on whether a valid session cookie still exists.
class _SessionResolver extends StatefulWidget {
  const _SessionResolver();

  @override
  State<_SessionResolver> createState() => _SessionResolverState();
}

class _SessionResolverState extends State<_SessionResolver> {
  bool _loading = true;
  bool _authed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final user = await AuthService.instance.tryResumeSession();
      if (!mounted) return;
      setState(() {
        _authed = user != null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = friendlyAuthError(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    color: AppColors.magenta, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: _resolve, child: const Text('تلاش مجدد')),
              ],
            ),
          ),
        ),
      );
    }
    return _authed ? const AppEntryScreen() : const RegisterScreen();
  }
}
