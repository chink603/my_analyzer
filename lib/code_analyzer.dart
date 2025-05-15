// lib/code_analyzer.dart
import 'dart:io';
import 'dart:math'; // For min/max

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:my_analyzer/visitors/visitors.dart';

import 'models.dart';

class CodeAnalyzer {
  static const int maxCyclomaticComplexity = 10;
  static const int maxFunctionLoc = 50;
  static const int maxParameters = 4;
  static const int maxNestingDepth = 3;

  static String _getCodeSnippet(List<String> lines, int lineNumber, {int contextLines = 1}) {
    if (lines.isEmpty || lineNumber <= 0 || lineNumber > lines.length) {
      return "// Snippet not available (invalid line or empty file)";
    }
    final targetLineIndex = lineNumber - 1;
    final start = max(0, targetLineIndex - contextLines);
    final end = min(lines.length - 1, targetLineIndex + contextLines);

    StringBuffer snippet = StringBuffer();
    for (int i = start; i <= end; i++) {
      String lineNumStr = (i + 1).toString().padLeft(lines.length.toString().length);
      String lineContent = lines[i];
      snippet.writeln("$lineNumStr | $lineContent");
    }
    return snippet.toString().trimRight();
  }

  Future<FileAnalysisResult> analyzeFile(String filePath) async {
    final result = FileAnalysisResult(filePath: filePath);
    List<String> fileLines = [];

    try {
      final content = await File(filePath).readAsString();
      fileLines = content.split('\n');
      final parseResult = parseString(
        content: content,
        featureSet: FeatureSet.latestLanguageVersion(),
        throwIfDiagnostics: false,
      );
      final compilationUnit = parseResult.unit;
      final complexityVisitor = _ComplexityVisitor(compilationUnit, result, fileLines, filePath);
      compilationUnit.accept(complexityVisitor);

      Token? token = compilationUnit.beginToken;
      while (token != null && token.type != TokenType.EOF) {
        Token? commentToken = token.precedingComments;
        while (commentToken != null) {
          final commentText = commentToken.lexeme;
          final lineNumber = compilationUnit.lineInfo.getLocation(commentToken.offset).lineNumber;
          if (commentText.contains('TODO') || commentText.contains('FIXME')) {
            result.addFileLevelIssue(Issue(
              message: 'Found global TODO/FIXME: "${commentText.trim()}"',
              suggestion: 'Address the pending task or issue.',
              lineNumber: lineNumber, type: 'Pending Task',
              codeSnippet:_getCodeSnippet(fileLines, lineNumber, contextLines: 2),
            ));
          }
          commentToken = commentToken.next;
        }
        if (token == token.next) break;
        token = token.next;
      }
    } catch (e, stackTrace) {
      print("Error analyzing file $filePath: $e\n$stackTrace");
      result.addFileLevelIssue(Issue(
        message: "Could not analyze file: $e",
        suggestion: "Check console for details.",
        lineNumber: 0, type: "Analysis Error",
        codeSnippet: "// Error during analysis.",
      ));
    }
    return result;
  }
}

class _ComplexityVisitor extends RecursiveAstVisitor<void> {
  final CompilationUnit compilationUnit;
  final FileAnalysisResult fileResult;
  final List<String> fileLines;
  final String filePath;
  ClassMetric? _currentClass;

  _ComplexityVisitor(this.compilationUnit, this.fileResult, this.fileLines, this.filePath);

  int _getLineNumber(AstNode node) => compilationUnit.lineInfo.getLocation(node.offset).lineNumber;
  int _getEndLineNumber(AstNode node) => compilationUnit.lineInfo.getLocation(node.endToken.offset).lineNumber;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _currentClass = ClassMetric(
      name: node.name.lexeme,
      startLine: _getLineNumber(node), endLine: _getEndLineNumber(node),
    );
    super.visitClassDeclaration(node);
    if (_currentClass != null) fileResult.addClassMetric(_currentClass!);
    _currentClass = null;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) => _analyzeFunctionOrMethod(
      node, node.name.lexeme, node.functionExpression.parameters, node.functionExpression.body);

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _analyzeFunctionOrMethod(
      node, node.name.lexeme, node.parameters, node.body);

  void _analyzeFunctionOrMethod(
      Declaration nodeWithBody, String name, FormalParameterList? parameters, FunctionBody body) {
    final startLine = _getLineNumber(nodeWithBody);
    final endLine = _getEndLineNumber(nodeWithBody);
    final loc = endLine - startLine + 1;
    final parameterCount = parameters?.parameters.length ?? 0;

    final ccVisitor = CyclomaticComplexityVisitor();
    body.accept(ccVisitor);
    final cyclomaticComplexity = ccVisitor.complexity;

    final nestingVisitor = NestingDepthVisitor();
    body.accept(nestingVisitor);
    final maxNestingDepthInFunction = nestingVisitor.maxDepth;
    final cogCVisitor = SonarCognitiveComplexityVisitor();
    body.accept(cogCVisitor); // Visit the function/method body
    final cognitiveComplexity = cogCVisitor.complexity;
    final metric = FunctionMetric(
      name: name, startLine: startLine, endLine: endLine, loc: loc,
      cyclomaticComplexity: cyclomaticComplexity, parameterCount: parameterCount,
      cognitiveComplexity: cognitiveComplexity,
      maxNestingDepth: maxNestingDepthInFunction,
    );
    const int maxCognitiveComplexityThreshold = 15; // ตัวอย่าง Threshold
    if (cognitiveComplexity > maxCognitiveComplexityThreshold) {
      metric.addIssue(Issue(
        message: 'High Cognitive Complexity: $cognitiveComplexity (Threshold: $maxCognitiveComplexityThreshold)',
        suggestion: 'This code might be hard to understand. Consider refactoring to simplify logic or reduce nesting.',
        lineNumber: startLine,
        type: 'High Cognitive Complexity', // อาจจะใช้ type เดียวกับ CC หรือแยก
        codeSnippet: CodeAnalyzer._getCodeSnippet(fileLines, startLine, contextLines: 2),
      ));
    }
    if (cyclomaticComplexity > CodeAnalyzer.maxCyclomaticComplexity) {
      metric.addIssue(Issue(
          message: 'High CC: $cyclomaticComplexity (Max: ${CodeAnalyzer.maxCyclomaticComplexity})',
          suggestion: 'Refactor to reduce branches or extract methods.',
          lineNumber: startLine, type: 'High Cyclomatic Complexity',
          codeSnippet: CodeAnalyzer._getCodeSnippet(fileLines, startLine, contextLines: 3)));
    }
    if (loc > CodeAnalyzer.maxFunctionLoc) {
      metric.addIssue(Issue(
          message: 'Long Function: $loc lines (Max: ${CodeAnalyzer.maxFunctionLoc})',
          suggestion: 'Break into smaller functions.',
          lineNumber: startLine, type: 'Long Function',
          codeSnippet: CodeAnalyzer._getCodeSnippet(fileLines, startLine, contextLines: 1)));
    }
    if (parameterCount > CodeAnalyzer.maxParameters) {
      metric.addIssue(Issue(
          message: 'Many Params: $parameterCount (Max: ${CodeAnalyzer.maxParameters})',
          suggestion: 'Use an object or reduce params.',
          lineNumber: startLine, type: 'Many Parameters',
          codeSnippet: CodeAnalyzer._getCodeSnippet(fileLines, startLine, contextLines: 1)));
    }
    if (maxNestingDepthInFunction > CodeAnalyzer.maxNestingDepth) {
      metric.addIssue(Issue(
          message: 'Deep Nesting: $maxNestingDepthInFunction (Max: ${CodeAnalyzer.maxNestingDepth})',
          suggestion: 'Use guard clauses or extract methods.',
          lineNumber: startLine, type: 'Deep Nesting', // Ideally line of max depth
          codeSnippet: CodeAnalyzer._getCodeSnippet(fileLines, startLine, contextLines: 3)));
    }

    Token? currentToken = body.beginToken;
    final bodyEndOffset = body.endToken.end;
    while (currentToken != null && currentToken.offset < bodyEndOffset && currentToken.type != TokenType.EOF) {
      Token? commentToken = currentToken.precedingComments;
      while (commentToken != null) {
        final commentText = commentToken.lexeme;
        final commentLineNumber = compilationUnit.lineInfo.getLocation(commentToken.offset).lineNumber;
        if (commentText.contains('TODO') || commentText.contains('FIXME')) {
          metric.addIssue(Issue(
              message: 'TODO/FIXME: "${commentText.trim()}"',
              suggestion: 'Address the task/issue.',
              lineNumber: commentLineNumber, type: 'Pending Task',
              codeSnippet: CodeAnalyzer._getCodeSnippet(fileLines, commentLineNumber, contextLines: 2)));
        }
        commentToken = commentToken.next;
      }
      if (currentToken == currentToken.next) break;
      currentToken = currentToken.next;
    }

    if (_currentClass != null) _currentClass!.addMethodMetric(metric);
    else fileResult.addFunctionMetric(metric);
  }
}

