import 'package:flutter/material.dart';
import 'package:smart_trainner_core_designsystem/smart_trainner_core_designsystem.dart';
import 'package:smart_trainner_feature_training_entry/smart_trainner_feature_training_entry.dart';

void main() {
  runApp(const SmartTrainnerApp());
}

class SmartTrainnerApp extends StatefulWidget {
  const SmartTrainnerApp({super.key});

  @override
  State<SmartTrainnerApp> createState() => _SmartTrainnerAppState();
}

class _SmartTrainnerAppState extends State<SmartTrainnerApp> {
  late final trainingFeatureEntry = createTrainingFeatureEntry();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Trainner',
      debugShowCheckedModeBanner: false,
      theme: smartTrainnerTheme(),
      home: Builder(builder: trainingFeatureEntry.build),
    );
  }
}
