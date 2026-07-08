import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'routes/router.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded successfully.");
  } catch (e) {
    print("Warning: Could not load .env file: $e");
  }

  // Initialize Firebase Messaging
  try {
    // Import package:firebase_core/firebase_core.dart internally or at top
    // Note: since Firebase is loaded, we can initialize it safely.
    // In local development, if configuration files are missing, it throws.
    // We catch the error to prevent crash.
    await Firebase.initializeApp();
    await FCMService.initialize();
  } catch (e) {
    print("Warning: Firebase initialization skipped: $e");
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tinder Spark',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Default dark mode as requested
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
