import 'dart:io';

/// 고정 SDK의 공식 dart doc을 실행하고 경고도 실패로 전달한다.
Future<void> verifyApiDocumentation({
  required String dart,
  required Directory root,
  required Map<String, String> environment,
}) async {
  final result = await Process.run(
    dart,
    ['doc', '--dry-run'],
    workingDirectory: root.absolute.path,
    environment: environment,
  );
  final output = '${result.stdout}\n${result.stderr}';
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  // 이 SDK의 dry-run은 일부 경고에도 exit 0이다. 공식 진단 행을 실패로 승격한다.
  if (result.exitCode != 0 ||
      RegExp(r'^\s*(warning|error):', multiLine: true).hasMatch(output)) {
    throw StateError('dart doc 문서 검증 실패: 오류 또는 경고를 해결하세요.');
  }
}

/// 격리된 문서 fixture도 같은 검사 경계로 검증할 수 있다.
Future<void> main(List<String> arguments) => verifyApiDocumentation(
  dart: Platform.resolvedExecutable,
  root: Directory(arguments.isEmpty ? '.' : arguments.single),
  environment: Platform.environment,
);
