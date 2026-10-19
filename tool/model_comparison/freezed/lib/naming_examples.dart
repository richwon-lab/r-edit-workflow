import 'model.dart';

// 네이밍 검토 전용 별칭이다. 운영 API를 바꾸지 않는다.
typedef TextAreaInput = TrialArea;
typedef AreaText = TrialArea;
typedef TextAreaContent = TrialArea;
typedef LineBreakSpec = TrialBreak;
typedef LineBreakInput = TrialBreak;
typedef LineBreakChoice = TrialBreak;

Map<String, String> namingExamples() {
  final input = TextAreaInput(
    areaId: 'a',
    sourceText: 'PUMP',
    lineBreak: LineBreakSpec.manual(['PUMP']),
  );
  final changedInput = input.copyWith(
    sourceText: 'VALVE',
    lineBreak: LineBreakSpec.manual(['VALVE']),
  );
  final text = AreaText(
    areaId: 'a',
    sourceText: 'PUMP',
    lineBreak: LineBreakInput.manual(['PUMP']),
  );
  final changedText = text.copyWith(
    sourceText: 'VALVE',
    lineBreak: LineBreakInput.manual(['VALVE']),
  );
  final content = TextAreaContent(
    areaId: 'a',
    sourceText: 'PUMP',
    lineBreak: LineBreakChoice.manual(['PUMP']),
  );
  final changedContent = content.copyWith(
    sourceText: 'VALVE',
    lineBreak: LineBreakChoice.manual(['VALVE']),
  );
  return {
    'TextAreaInput': changedInput.sourceText,
    'AreaText': changedText.sourceText,
    'TextAreaContent': changedContent.sourceText,
  };
}
