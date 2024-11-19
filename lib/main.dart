import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safetynet/providers/auth_provider.dart';
import 'package:safetynet/screens/main/main_app.dart';
import 'package:safetynet/screens/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform, name: "safetynet");

    // Test Firestore connection
    await FirebaseFirestore.instance
        .collection('test')
        .doc('test')
        .set({'test': 'test'});

    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Handle the error appropriately
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color.fromRGBO(25, 118, 210, 1),
  ),
  textTheme: GoogleFonts.poppinsTextTheme(),
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);

    return MaterialApp(
      builder: FToastBuilder(),
      debugShowCheckedModeBanner: false,
      title: 'Safety Net',
      theme: theme,
      //  home: const SafetyNetSplashScreen(),
      home: authService.isLoggedIn() ? const MainScreen() : const SafetyNetSplashScreen(),
    );
  }
}
