import 'package:flutter/material.dart';
import 'package:smart_trainner_core_designsystem/smart_trainner_core_designsystem.dart';
import 'package:smart_trainner_feature_training_entry/smart_trainner_feature_training_entry.dart';

void main() {
  runApp(const SmartTrainnerApp());
}

class SmartTrainnerApp extends StatelessWidget {
  const SmartTrainnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final trainingFeatureEntry = createTrainingFeatureEntry();
    return MaterialApp(
      title: 'Smart Trainner',
      debugShowCheckedModeBanner: false,
      theme: smartTrainnerTheme(),
      home: Builder(
        builder: trainingFeatureEntry.build,
      ),
    );
  }
}
