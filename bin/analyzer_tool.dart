// bin/analyzer_tool.dart
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

// Adjust these imports based on your package name in pubspec.yaml
import 'package:my_analyzer/my_analyzer.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('directory',
        abbr: 'd', help: 'Path to the Dart project directory to analyze.')
    ..addOption('output-dir', // <--- ยืนยันว่าใช้ชื่อนี้
        abbr: 'o',
        help: 'Directory where the HTML report files will be generated.', // <--- คำอธิบายชัดเจน
        defaultsTo: 'complexity_report_output') // <--- Default เป็นชื่อไดเรกทอรี
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help message.');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print('Error parsing arguments: ${e.toString()}');
   
    exit(1);
  }

  if (argResults['help'] as bool || argResults['directory'] == null) {
   
    exit(0);
  }

  final directoryPath = argResults['directory'] as String;
  final outputBaseDirectoryPath = argResults['output-dir'] as String; // <--- ใช้ชื่อตัวแปรที่สื่อ

  final directoryToAnalyze = Directory(directoryPath);
  if (!await directoryToAnalyze.exists()) {
    print('Error: Input directory not found at $directoryPath');
    exit(1);
  }

  // --- ส่วนนี้สำคัญ: สร้าง Base Output Directory ---
  final baseOutputDir = Directory(outputBaseDirectoryPath);
  try {
    if (!await baseOutputDir.exists()) {
      await baseOutputDir.create(recursive: true);
      print('Created output directory: ${baseOutputDir.path}');
    } else {
      // ถ้าไดเรกทอรีมีอยู่แล้ว อาจจะไม่ต้องทำอะไร หรือจะล้างข้อมูลเก่าก็ได้
      // ใน HtmlReporter.generateReportForProject มีการลบ individualReportsDir อยู่แล้ว
      print('Output directory already exists: ${baseOutputDir.path}');
    }
  } catch (e) {
    print('Error creating output directory ${baseOutputDir.path}: $e');
    exit(1);
  }
  // --- สิ้นสุดส่วนสำคัญ ---


  print('Analyzing directory: $directoryPath...');
  final analyzer = CodeAnalyzer();
  final projectResult = ProjectAnalysisResult(directoryPath: directoryPath);

  final filesToAnalyze = await _findDartFiles(directoryToAnalyze);

  if (filesToAnalyze.isEmpty) {
    print('No .dart files found in the specified directory.');
    // ยังคงสร้าง report เปล่าๆ ได้
    final reporter = HtmlReporter();
    // ส่ง path ของ base output directory ที่สร้าง (หรือมีอยู่แล้ว) ไปให้
    await reporter.generateReportForProject(projectResult, baseOutputDir.path);
    exit(0);
  }

  for (final file in filesToAnalyze) {
    print('Analyzing ${p.relative(file.path, from: directoryToAnalyze.path)}...');
    final fileAnalysisResult = await analyzer.analyzeFile(file.path);
    projectResult.addFileResult(fileAnalysisResult);
  }

  print('\nGenerating report into directory: ${baseOutputDir.path}');
  final reporter = HtmlReporter();
  // ส่ง path ของ base output directory ที่สร้าง (หรือมีอยู่แล้ว) ไปให้
  await reporter.generateReportForProject(projectResult, baseOutputDir.path);
}

// ... (_findDartFiles, printUsage as before) ...
// ตรวจสอบ _findDartFiles ให้แน่ใจว่า excludedPaths ถูก join กับ dir.path อย่างถูกต้อง
Future<List<File>> _findDartFiles(Directory dir) async {
  final files = <File>[];
  // สร้าง list ของ absolute paths ที่จะ exclude
  final List<String> excludedAbsolutePaths = [
    p.join(dir.absolute.path, '.dart_tool'),
    p.join(dir.absolute.path, 'build'),
    p.join(dir.absolute.path, '.symlinks'),
    p.join(dir.absolute.path, 'ios'),
    p.join(dir.absolute.path, 'android'),
    p.join(dir.absolute.path, 'web'),
    p.join(dir.absolute.path, 'linux'),
    p.join(dir.absolute.path, 'macos'),
    p.join(dir.absolute.path, 'windows'),
  ];

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      bool isExcluded = false;
      for (String excludedPath in excludedAbsolutePaths) {
        // ตรวจสอบว่า path ของ entity เริ่มต้นด้วย excludedPath หรือไม่
        if (entity.absolute.path.startsWith(excludedPath + p.separator) || entity.absolute.path == excludedPath) {
          isExcluded = true;
          break;
        }
      }
      if (entity.path.endsWith('.g.dart') || entity.path.endsWith('.freezed.dart')) {
          isExcluded = true;
      }
      if (!isExcluded) {
        files.add(entity);
      }
    }
  }
  return files;
}