// lib/models.dart
class Issue {
  final String message;
  final String suggestion;
  final int lineNumber;
  final String type;
  final String? codeSnippet; // Ensure this field exists

  Issue({
    required this.message,
    required this.suggestion,
    required this.lineNumber,
    required this.type,
    this.codeSnippet, // Ensure this parameter exists
  });
}

class FunctionMetric {
  final String name;
  final int startLine;
  final int endLine;
  final int loc;
  final int cyclomaticComplexity;
  final int parameterCount;
  final int maxNestingDepth;
  final List<Issue> issues = [];
  final int cognitiveComplexity; // เพิ่ม field นี้

  FunctionMetric( {
    required this.name,
    required this.startLine,
    required this.endLine,
    required this.loc,
    required this.cyclomaticComplexity,
    required this.parameterCount,
    required this.maxNestingDepth,
    required this.cognitiveComplexity, // เพิ่ม parameter นี้
  });

  void addIssue(Issue issue) {
    issues.add(issue);
  }
}

class ClassMetric {
  final String name;
  final int startLine;
  final int endLine;
  final List<FunctionMetric> methods = [];
  final List<Issue> issues = [];

  ClassMetric({
    required this.name,
    required this.startLine,
    required this.endLine,
  });

  void addMethodMetric(FunctionMetric metric) {
    methods.add(metric);
  }

  void addIssue(Issue issue) {
    issues.add(issue);
  }
}

class FileAnalysisResult {
  final String filePath;
  final List<FunctionMetric> functions = [];
  final List<ClassMetric> classes = [];
  final List<Issue> fileLevelIssues = [];

  FileAnalysisResult({required this.filePath});

  void addFunctionMetric(FunctionMetric metric) {
    functions.add(metric);
  }

  void addClassMetric(ClassMetric metric) {
    classes.add(metric);
  }

  void addFileLevelIssue(Issue issue) {
    fileLevelIssues.add(issue);
  }
}

class ProjectAnalysisResult {
  final String directoryPath;
  final List<FileAnalysisResult> fileResults = [];

  ProjectAnalysisResult({required this.directoryPath});

  void addFileResult(FileAnalysisResult result) {
    fileResults.add(result);
  }
}
