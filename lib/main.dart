import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safetynet/screens/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void main() {
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Safety Net',
      theme: theme,
      home: const SafetyNetSplashScreen(),
      // home: const CategoriesScreen(),
    );
  }
}
