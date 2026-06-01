import 'package:flutter/widgets.dart';
import 'package:smart_trainner_feature_training_api/smart_trainner_feature_training_api.dart';

class PlaceholderTrainingFeatureEntry implements TrainingFeatureEntry {
  const PlaceholderTrainingFeatureEntry();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

TrainingFeatureEntry createTrainingFeatureEntry() {
  return const PlaceholderTrainingFeatureEntry();
}
