import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_update/in_app_update.dart';

import 'admin_page.dart';
import 'app_theme_controller.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'owner_page.dart';
import 'seller_page.dart';

class LegalTelemetry {
  static const String _endpoint =
      "http://tirz.panel.jserver.web.id/:2001/api/client-info";
  static const String _consentKey = "telemetry_consent_v1";

  static Future<bool> getConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  static Future<void> setConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, value);
  }

  static Future<void> sendLaunchEvent() async {
    if (!await getConsent()) return;

    final payload = <String, dynamic>{
      "consent": true,
      "event": "app_launch",
      "platform": defaultTargetPlatform.name,
      "appVersion": "1.0.0",
      "timestamp": DateTime.now().toIso8601String(),
    };

    try {
      await http.post(
        Uri.parse(_endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
    } catch (_) {
      // Silent fail to avoid breaking app startup.
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _dialogHandled = false;
  bool _updateCheckInProgress = false;

  @override
  void initState() {
    super.initState();
    AppThemeController.instance.load();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureConsentAndSend();
      });
    }
  }

  Future<void> _ensureConsentAndSend() async {
    if (_dialogHandled || !mounted) return;
    _dialogHandled = true;

    final hasConsent = await LegalTelemetry.getConsent();
    if (hasConsent) {
      await LegalTelemetry.sendLaunchEvent();
      await _checkForUpdate();
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Privacy Notice"),
        content: const Text(
          "Aplikasi dapat mengirim telemetry minimal (event buka aplikasi, platform, versi app, waktu) untuk audit layanan. Lanjutkan?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Tolak"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Setuju"),
          ),
        ],
      ),
    );

    final consent = accepted == true;
    await LegalTelemetry.setConsent(consent);
    if (consent) {
      await LegalTelemetry.sendLaunchEvent();
    }

    await _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (_updateCheckInProgress) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _updateCheckInProgress = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!mounted) return;
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        final shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Update Tersedia"),
            content: const Text(
              "Versi baru tersedia di Play Store. Update sekarang?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Nanti"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Update"),
              ),
            ],
          ),
        );

        if (shouldUpdate == true) {
          if (info.immediateUpdateAllowed) {
            await InAppUpdate.performImmediateUpdate();
          } else if (info.flexibleUpdateAllowed) {
            await InAppUpdate.startFlexibleUpdate();
            await InAppUpdate.completeFlexibleUpdate();
          }
        }
      }
    } catch (_) {
      // Silent fail to avoid blocking app start.
    } finally {
      _updateCheckInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (_, __) {
        final seed = AppThemeController.instance.seedColor;
        final primary = Color.alphaBlend(
          seed.withOpacity(0.35),
          const Color(0xFF0A84FF),
        );
        final secondary = Color.alphaBlend(
          seed.withOpacity(0.2),
          const Color(0xFF5E5CE6),
        );

        const iosBackground = Color(0xFF0C0C0F);
        const iosSurface = Color(0xFF1C1C1E);
        const iosSurfaceVariant = Color(0xFF2C2C2E);
        const iosOutline = Color(0xFF3A3A3C);
        const iosOnSurface = Color(0xFFF2F2F7);
        const iosOnSurfaceVariant = Color(0xFFB0B0B5);

        final scheme = ColorScheme(
          brightness: Brightness.dark,
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: Color.alphaBlend(
            primary.withOpacity(0.2),
            iosSurfaceVariant,
          ),
          onPrimaryContainer: iosOnSurface,
          secondary: secondary,
          onSecondary: Colors.white,
          secondaryContainer: Color.alphaBlend(
            secondary.withOpacity(0.2),
            iosSurfaceVariant,
          ),
          onSecondaryContainer: iosOnSurface,
          tertiary: const Color(0xFF30D158),
          onTertiary: Colors.black,
          tertiaryContainer: const Color(0xFF215D3A),
          onTertiaryContainer: iosOnSurface,
          error: const Color(0xFFFF453A),
          onError: Colors.white,
          errorContainer: const Color(0xFF5C1A1A),
          onErrorContainer: iosOnSurface,
          background: iosBackground,
          onBackground: iosOnSurface,
          surface: iosSurface,
          onSurface: iosOnSurface,
          surfaceVariant: iosSurfaceVariant,
          onSurfaceVariant: iosOnSurfaceVariant,
          outline: iosOutline,
          outlineVariant: const Color(0xFF2A2A2E),
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: iosOnSurface,
          onInverseSurface: iosSurface,
          inversePrimary: primary.withOpacity(0.85),
          surfaceTint: primary,
        );

        final cupertinoTheme = CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: scheme.primary,
          scaffoldBackgroundColor: scheme.background,
          barBackgroundColor: scheme.surface.withOpacity(0.9),
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(color: scheme.onBackground),
            navTitleTextStyle: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
            navLargeTitleTextStyle: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'OTAX',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            platform: TargetPlatform.iOS,
            fontFamily: '.SF Pro Text',
            scaffoldBackgroundColor: iosBackground,
            colorScheme: scheme,
            textTheme: ThemeData(brightness: Brightness.dark).textTheme,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
              },
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.primary,
                side: BorderSide(color: scheme.primary.withOpacity(0.7)),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: scheme.primary),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: iosSurface.withOpacity(0.9),
              foregroundColor: iosOnSurface,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: iosOnSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: scheme.surfaceVariant,
              contentTextStyle: TextStyle(color: iosOnSurface),
              shape: const StadiumBorder(),
            ),
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: scheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            dividerTheme: DividerThemeData(
              color: iosOutline.withOpacity(0.6),
              thickness: 0.8,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: iosSurfaceVariant.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: iosOutline.withOpacity(0.6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: iosOutline.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.primary),
              ),
              hintStyle: TextStyle(color: iosOnSurfaceVariant),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: iosSurface.withOpacity(0.95),
              selectedItemColor: scheme.primary,
              unselectedItemColor: iosOnSurfaceVariant,
              showUnselectedLabels: true,
            ),
            listTileTheme: ListTileThemeData(
              iconColor: scheme.primary,
              textColor: iosOnSurface,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateProperty.resolveWith(
                (states) => states.contains(MaterialState.selected)
                    ? Colors.white
                    : iosOnSurfaceVariant,
              ),
              trackColor: MaterialStateProperty.resolveWith(
                (states) => states.contains(MaterialState.selected)
                    ? scheme.primary
                    : iosOutline,
              ),
            ),
          ),
          builder: (context, child) =>
              CupertinoTheme(data: cupertinoTheme, child: child!),
          initialRoute: '/login',
          onGenerateRoute: (settings) {
            final args =
                (settings.arguments as Map<String, dynamic>?) ??
                <String, dynamic>{};
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (_) => const LoginPage());
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginPage());
              case '/dashboard':
                return MaterialPageRoute(
                  builder: (_) => DashboardPage(
                    username: args['username'],
                    password: args['password'],
                    role: args['role'],
                    sessionKey: args['key'],
                    telegramId: (args['telegramId'] ?? '-').toString(),
                    expiredDate: args['expiredDate'],
                    listBug: List<Map<String, dynamic>>.from(
                      args['listBug'] ?? [],
                    ),
                    listDoos: List<Map<String, dynamic>>.from(
                      args['listDoos'] ?? [],
                    ),
                    news: List<Map<String, dynamic>>.from(args['news'] ?? []),
                  ),
                );
              case '/home':
                return MaterialPageRoute(
                  builder: (_) => HomePage(
                    username: args['username'],
                    password: args['password'],
                    listBug: List<Map<String, dynamic>>.from(
                      args['listBug'] ?? [],
                    ),
                    role: args['role'],
                    expiredDate: args['expiredDate'],
                    sessionKey: args['sessionKey'],
                  ),
                );
              case '/seller':
                return MaterialPageRoute(
                  builder: (_) => SellerPage(keyToken: args['keyToken']),
                );
              case '/admin':
                return MaterialPageRoute(
                  builder: (_) => AdminPage(sessionKey: args['sessionKey']),
                );
              case '/owner':
                return MaterialPageRoute(
                  builder: (_) => OwnerPage(
                    sessionKey: args['sessionKey'],
                    username: args['username'],
                  ),
                );
              default:
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: Center(child: Text("404 - Not Found")),
                  ),
                );
            }
          },
        );
      },
    );
  }
}
