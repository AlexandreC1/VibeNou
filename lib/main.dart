import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/firebase_options.dart';
import 'utils/supabase_config.dart';
import 'utils/app_logger.dart';
import 'services/notification_service.dart';

import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_screen.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler for FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Push Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  AppLogger.info('Push notifications initialized');

  // Initialize Supabase (only if configured)
  try {
    if (SupabaseConfig.supabaseUrl != 'YOUR_SUPABASE_URL' &&
        SupabaseConfig.supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY') {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      AppLogger.info('Supabase initialized successfully');
    } else {
      AppLogger.warning('Supabase not configured. Image uploads will use Firebase Storage instead.');
    }
  } catch (e) {
    AppLogger.warning('Supabase initialization failed: $e');
    AppLogger.info('Image uploads will use Firebase Storage instead.');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'VibeNou',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            locale: languageProvider.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('fr', ''), // French
          Locale('ht', ''), // Haitian Creole
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          // If Haitian Creole is selected, fallback to French for Material widgets
          if (locale?.languageCode == 'ht') {
            return const Locale('fr', '');
          }
          // Check if the current locale is supported
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          // Fallback to English
          return const Locale('en', '');
        },
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/main': (context) => const MainScreen(),
            },
          );
        },
      ),
    );
  }
}
