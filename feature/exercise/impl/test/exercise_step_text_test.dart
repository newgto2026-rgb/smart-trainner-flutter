import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trainner_feature_exercise_impl/smart_trainner_feature_exercise_impl.dart';

void main() {
  test('instructionWithoutRepeatedStepTitle removes matching title prefix', () {
    expect(
      instructionWithoutRepeatedStepTitle('시작 자세', '시작 자세: 등을 바닥에 붙이고 준비합니다.'),
      '등을 바닥에 붙이고 준비합니다.',
    );

    expect(
      instructionWithoutRepeatedStepTitle(
        '발·코어 정렬',
        ' 발·코어 정렬 ： 장비와 몸의 기준점을 맞춥니다.',
      ),
      '장비와 몸의 기준점을 맞춥니다.',
    );
  });

  test('instructionWithoutRepeatedStepTitle keeps different leading text', () {
    expect(
      instructionWithoutRepeatedStepTitle('시작 자세', '등을 바닥에 붙이고 준비합니다.'),
      '등을 바닥에 붙이고 준비합니다.',
    );
  });

  test('instructionWithoutRepeatedStepTitle ignores prefix case', () {
    expect(
      instructionWithoutRepeatedStepTitle(
        'Start Position',
        'start position: Brace the ribs before moving.',
      ),
      'Brace the ribs before moving.',
    );
  });
}
