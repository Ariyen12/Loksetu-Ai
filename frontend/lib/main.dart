import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LokSetuAI());
}

class LokSetuAI extends StatelessWidget {
  const LokSetuAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LokSetu AI',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}