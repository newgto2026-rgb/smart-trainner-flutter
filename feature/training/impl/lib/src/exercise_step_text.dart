String instructionWithoutRepeatedStepTitle(String label, String instruction) {
  final trimmedLabel = label.trim();
  if (trimmedLabel.isEmpty) {
    return instruction.trim();
  }
  return instruction
      .replaceFirst(RegExp('^\\s*${RegExp.escape(trimmedLabel)}\\s*[:：]\\s*'), '')
      .trim();
}
