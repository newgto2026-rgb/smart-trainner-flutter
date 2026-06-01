import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_trainner_core_designsystem/smart_trainner_core_designsystem.dart';
import 'package:smart_trainner_feature_training_entry/smart_trainner_feature_training_entry.dart';

void main() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: SmartTrainnerColors.paper,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SmartTrainnerApp());
}

class SmartTrainnerApp extends StatefulWidget {
  const SmartTrainnerApp({super.key});

  @override
  State<SmartTrainnerApp> createState() => _SmartTrainnerAppState();
}

class _SmartTrainnerAppState extends State<SmartTrainnerApp> {
  late final trainingFeatureEntry = createTrainingFeatureEntry();
  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 1650), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Trainer',
      debugShowCheckedModeBanner: false,
      theme: smartTrainnerTheme(),
      home: _showSplash
          ? const _BrandSplashScreen()
          : Builder(builder: trainingFeatureEntry.build),
    );
  }
}

class _BrandSplashScreen extends StatelessWidget {
  const _BrandSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartTrainnerColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 780),
              curve: Curves.fastOutSlowIn,
              builder: (context, value, child) {
                final scale = 0.88 + (0.12 * value);
                return Opacity(
                  opacity: value.clamp(0, 1),
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: FractionallySizedBox(
                widthFactor: 0.9,
                heightFactor: 0.82,
                child: Image.asset(
                  'assets/brand/brand_ai_trainer_splash_transparent.webp',
                  key: const Key('brand_splash'),
                  fit: BoxFit.contain,
                  semanticLabel: 'Smart Trainer',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
