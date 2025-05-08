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

  // --- NEW GETTERS for Dashboard ---

  // Calculate total issues across all files
  int get totalIssues {
    int count = 0;
    for (final fileResult in fileResults) {
      count += fileResult.fileLevelIssues.length;
      for (final classMetric in fileResult.classes) {
        count += classMetric.issues.length; // Class-level issues (if any)
        for (final methodMetric in classMetric.methods) {
          count += methodMetric.issues.length;
        }
      }
      for (final funcMetric in fileResult.functions) {
        count += funcMetric.issues.length;
      }
    }
    return count;
  }

  // Get a list of FileAnalysisResult sorted by total issue count (descending)
  // We might want to store issue count per file to avoid recalculating
  List<Map<String, dynamic>> get filesSortedByIssues {
      var filesWithCounts = fileResults.map((fileResult) {
          int count = fileResult.fileLevelIssues.length;
          count += fileResult.classes.fold<int>(0, (prevClass, c) =>
              prevClass + c.issues.length + c.methods.fold<int>(0, (prevMethod, m) =>
                  prevMethod + m.issues.length
              )
          );
          count += fileResult.functions.fold<int>(0, (prevFunc, f) => prevFunc + f.issues.length);
          return {'file': fileResult, 'issueCount': count};
      }).toList();

      // Filter out files with 0 issues and sort descending by issue count
      filesWithCounts.removeWhere((item) => item['issueCount'] == 0);
      filesWithCounts.sort((a, b) => (b['issueCount'] as int).compareTo(a['issueCount'] as int));
      
      return filesWithCounts;
  }

}
