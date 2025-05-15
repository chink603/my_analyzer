// lib/models.dart
class Issue {
  final String message;
  final String suggestion;
  final int lineNumber;
  final String type; // e.g., "High Cyclomatic Complexity", "Long Function", "Pending Task"
  final String? codeSnippet; // Stores the relevant code snippet

  Issue({
    required this.message,
    required this.suggestion,
    required this.lineNumber,
    required this.type,
    this.codeSnippet, // Make sure this is included
  });
}

class FunctionMetric {
  final String name;
  final int startLine;
  final int endLine;
  final int loc; // Lines of Code
  final int cyclomaticComplexity; // CC
  final int cognitiveComplexity; // CogC - Added
  final int parameterCount;
  final int maxNestingDepth;
  final List<Issue> issues = [];

  FunctionMetric({
    required this.name,
    required this.startLine,
    required this.endLine,
    required this.loc,
    required this.cyclomaticComplexity,
    required this.cognitiveComplexity, // Added
    required this.parameterCount,
    required this.maxNestingDepth,
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
  final List<Issue> issues = []; // Issues specific to the class definition itself (if any)

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

  // Getter to easily access all issues within this class (including methods)
  List<Issue> get allIssuesInClass {
      List<Issue> allIssues = [...issues]; // Start with class-level issues
      for (var method in methods) {
          allIssues.addAll(method.issues);
      }
      return allIssues;
  }
}

class FileAnalysisResult {
  final String filePath;
  final List<FunctionMetric> functions = []; // Top-level functions
  final List<ClassMetric> classes = [];
  final List<Issue> fileLevelIssues = []; // e.g., Global TODOs, Analysis Errors

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

  // Helper to get all issues within this file
  List<Issue> get allIssuesInFile {
    List<Issue> allIssues = [...fileLevelIssues];
    for (final classMetric in classes) {
      allIssues.addAll(classMetric.allIssuesInClass); // Use getter from ClassMetric
    }
    for (final funcMetric in functions) {
      allIssues.addAll(funcMetric.issues);
    }
    return allIssues;
  }

  // Helper to get the total count of issues in this file
  int get totalIssueCount => allIssuesInFile.length;
}


class ProjectAnalysisResult {
  final String directoryPath;
  final List<FileAnalysisResult> fileResults = [];

  ProjectAnalysisResult({required this.directoryPath});

  void addFileResult(FileAnalysisResult result) {
    fileResults.add(result);
  }

  // --- GETTERS for Dashboard ---

  /// Total number of files analyzed.
  int get totalFilesAnalyzed => fileResults.length;

  /// Calculate total issues across all analyzed files.
  int get totalIssues {
    int count = 0;
    for (final fileResult in fileResults) {
      count += fileResult.totalIssueCount; // Use helper getter from FileAnalysisResult
    }
    return count;
  }

  /// Get issue counts grouped by issue type, sorted by count descending.
  Map<String, int> get issueCountsByType {
    final counts = <String, int>{};
    for (final fileResult in fileResults) {
      for (final issue in fileResult.allIssuesInFile) { // Use helper getter
        counts[issue.type] = (counts[issue.type] ?? 0) + 1;
      }
    }
    // Create a list of map entries, sort by value (count) descending, then create a new map
    var sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // Return a LinkedHashMap to preserve insertion order (which is now sorted order)
    return Map.fromEntries(sortedEntries);
  }

  /// Get a list of files that contain at least one issue of the specified type.
  List<FileAnalysisResult> getFilesWithIssueType(String issueType) {
    return fileResults.where((fileResult) {
      return fileResult.allIssuesInFile.any((issue) => issue.type == issueType); // Use helper getter
    }).toList();
    // Note: Sorting alphabetically can be done here or in the reporter if needed
    // filesWithIssueType.sort((a, b) => a.filePath.compareTo(b.filePath));
    // return filesWithIssueType;
  }

  /// Get a list of files sorted by their total issue count (descending),
  /// excluding files with zero issues.
  List<Map<String, dynamic>> get filesSortedByIssues {
    var filesWithCounts = fileResults.map((fileResult) {
      // Use the totalIssueCount getter from FileAnalysisResult
      return {'file': fileResult, 'issueCount': fileResult.totalIssueCount};
    }).toList();

    // Filter out files with 0 issues
    filesWithCounts.removeWhere((item) => item['issueCount'] == 0);
    // Sort descending by issue count
    filesWithCounts.sort((a, b) => (b['issueCount'] as int).compareTo(a['issueCount'] as int));
    
    return filesWithCounts;
  }

  // --- END GETTERS for Dashboard ---
}