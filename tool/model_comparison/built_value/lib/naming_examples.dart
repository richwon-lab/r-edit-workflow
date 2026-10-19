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
    (b) => b
      ..areaId = 'a'
      ..sourceText = 'PUMP'
      ..lineBreak.replace(LineBreakSpec.manual(['PUMP'])),
  );
  final changedInput = input.rebuild(
    (b) => b
      ..sourceText = 'VALVE'
      ..lineBreak.replace(LineBreakSpec.manual(['VALVE'])),
  );
  final text = AreaText(
    (b) => b
      ..areaId = 'a'
      ..sourceText = 'PUMP'
      ..lineBreak.replace(LineBreakInput.manual(['PUMP'])),
  );
  final changedText = text.rebuild(
    (b) => b
      ..sourceText = 'VALVE'
      ..lineBreak.replace(LineBreakInput.manual(['VALVE'])),
  );
  final content = TextAreaContent(
    (b) => b
      ..areaId = 'a'
      ..sourceText = 'PUMP'
      ..lineBreak.replace(LineBreakChoice.manual(['PUMP'])),
  );
  final changedContent = content.rebuild(
    (b) => b
      ..sourceText = 'VALVE'
      ..lineBreak.replace(LineBreakChoice.manual(['VALVE'])),
  );
  return {
    'TextAreaInput': changedInput.sourceText,
    'AreaText': changedText.sourceText,
    'TextAreaContent': changedContent.sourceText,
  };
}
