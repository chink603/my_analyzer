// lib/code_analyzer.dart
import 'dart:io';
import 'dart:math'; // For min/max

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

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

    final ccVisitor = _CyclomaticComplexityVisitor();
    body.accept(ccVisitor);
    final cyclomaticComplexity = ccVisitor.complexity;

    final nestingVisitor = _NestingDepthVisitor();
    body.accept(nestingVisitor);
    final maxNestingDepthInFunction = nestingVisitor.maxDepth;
    final cogCVisitor = CognitiveComplexityVisitor();
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

class _CyclomaticComplexityVisitor extends RecursiveAstVisitor<void> {
  int complexity = 1;
  @override void visitIfStatement(IfStatement node) { complexity++; super.visitIfStatement(node); }
  @override void visitForStatement(ForStatement node) { complexity++; super.visitForStatement(node); }
  @override void visitForElement(ForElement node){ complexity++; super.visitForElement(node); }
  @override void visitWhileStatement(WhileStatement node) { complexity++; super.visitWhileStatement(node); }
  @override void visitDoStatement(DoStatement node) { complexity++; super.visitDoStatement(node); }
  @override void visitSwitchCase(SwitchCase node) { if (node.statements.isNotEmpty) complexity++; super.visitSwitchCase(node); }
  @override void visitSwitchDefault(SwitchDefault node) { if (node.statements.isNotEmpty) complexity++; super.visitSwitchDefault(node); }
  @override void visitConditionalExpression(ConditionalExpression node) { complexity++; super.visitConditionalExpression(node); }
  @override void visitBinaryExpression(BinaryExpression node) { if (node.operator.type == TokenType.AMPERSAND_AMPERSAND || node.operator.type == TokenType.BAR_BAR) complexity++; super.visitBinaryExpression(node); }
  @override void visitTryStatement(TryStatement node) { if (node.catchClauses.isNotEmpty) complexity += node.catchClauses.length; super.visitTryStatement(node); }
}

class _NestingDepthVisitor extends RecursiveAstVisitor<void> {
  int currentDepth = 0;
  int maxDepth = 0;
  void _enter() { currentDepth++; if (currentDepth > maxDepth) maxDepth = currentDepth; }
  void _exit() { currentDepth--; }
  @override void visitBlockFunctionBody(BlockFunctionBody node) { super.visitBlockFunctionBody(node); }
  @override void visitIfStatement(IfStatement node) { _enter(); node.thenStatement.accept(this); node.elseStatement?.accept(this); _exit(); }
  @override void visitForStatement(ForStatement node) { _enter(); node.body.accept(this); _exit(); }
  @override void visitForElement(ForElement node) { _enter(); node.body.accept(this); _exit(); }
  @override void visitWhileStatement(WhileStatement node) { _enter(); node.body.accept(this); _exit(); }
  @override void visitDoStatement(DoStatement node) { _enter(); node.body.accept(this); _exit(); }
  @override void visitSwitchStatement(SwitchStatement node) { _enter(); super.visitSwitchStatement(node); _exit(); }
  @override void visitTryStatement(TryStatement node) { _enter(); node.body.accept(this); for (var clause in node.catchClauses) { _enter(); clause.body.accept(this); _exit(); } node.finallyBlock?.accept(this); _exit(); }
}

class CognitiveComplexityVisitor extends RecursiveAstVisitor<void> {
  int _complexity = 0;
  int _currentNestingLevel = 0;
  TokenType? _lastLogicalOperator;

  int get complexity => _complexity;

  // --- Helper methods ---
  void _incrementComplexity({int penalty = 1}) {
    _complexity += penalty;
  }

  void _incrementComplexityWithNesting({int penalty = 1}) {
    _complexity += (penalty + _currentNestingLevel);
  }

  void _enterNestableStructure() {
    _currentNestingLevel++;
  }

  void _exitNestableStructure() {
    _currentNestingLevel--;
  }

  // --- Visitor Methods (ตัวอย่าง) ---

  // Structures that increase nesting level and add complexity
  @override
  void visitIfStatement(IfStatement node) {
    _incrementComplexityWithNesting(); // For the 'if' itself
    _enterNestableStructure();
    node.thenStatement.accept(this);
    _exitNestableStructure();

    if (node.elseStatement != null) {
      // 'else' or 'else if' increases complexity, but only 'else' contributes to nesting here
      // 'else if' is another IfStatement which will be handled
      if (node.elseStatement is! IfStatement) { // It's a plain 'else'
         _incrementComplexity(); // Penalty for 'else'
        _enterNestableStructure(); // 'else' block also nests
        node.elseStatement!.accept(this);
        _exitNestableStructure();
      } else { // It's an 'else if'
        node.elseStatement!.accept(this); // Let the next IfStatement handle its own complexity and nesting
      }
    }
    _lastLogicalOperator = null; // Reset for conditions inside if
  }

  @override
  void visitForStatement(ForStatement node) {
    _incrementComplexityWithNesting();
    _enterNestableStructure();
    node.body.accept(this);
    _exitNestableStructure();
    _lastLogicalOperator = null;
  }

  @override
  void visitForElement(ForElement node) { // For collection_for
    _incrementComplexityWithNesting();
    _enterNestableStructure();
    node.body.accept(this);
    _exitNestableStructure();
    _lastLogicalOperator = null;
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _incrementComplexityWithNesting();
    _enterNestableStructure();
    node.body.accept(this);
    _exitNestableStructure();
    _lastLogicalOperator = null;
  }

  @override
  void visitDoStatement(DoStatement node) {
    _incrementComplexityWithNesting();
    _enterNestableStructure();
    node.body.accept(this);
    _exitNestableStructure();
    _lastLogicalOperator = null;
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _incrementComplexityWithNesting(); // For the switch itself
    // Each case is not inherently nesting for its content, but switch nests its cases
    _enterNestableStructure();
    super.visitSwitchStatement(node); // Visit cases
    _exitNestableStructure();
    _lastLogicalOperator = null;
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    // Cases themselves (except default if empty) add to complexity, but not fundamental nesting
    if (node.statements.isNotEmpty) {
      _incrementComplexity(); // Penalty for each case with code
    }
    super.visitSwitchCase(node);
  }
   @override
  void visitSwitchDefault(SwitchDefault node) {
    if (node.statements.isNotEmpty) {
      _incrementComplexity();
    }
    super.visitSwitchDefault(node);
  }


  @override
  void visitTryStatement(TryStatement node) {
    // Try block itself doesn't add complexity but adds nesting
    _enterNestableStructure();
    node.body.accept(this);
    _exitNestableStructure();

    for (final clause in node.catchClauses) {
      _incrementComplexityWithNesting(); // Each catch clause is a decision point and nests
      _enterNestableStructure();
      clause.body.accept(this);
      _exitNestableStructure();
    }
    if (node.finallyBlock != null) {
      // Finally block doesn't typically add to cognitive complexity directly
      // unless it contains complex logic itself, which will be visited.
      // It is a structural element.
      _enterNestableStructure();
      node.finallyBlock!.accept(this);
      _exitNestableStructure();
    }
    _lastLogicalOperator = null;
  }

  // Flow-breaking statements
  @override
  void visitBreakStatement(BreakStatement node) {
    if (_currentNestingLevel > 0) { // Only penalize if breaking out of something
      _incrementComplexity(penalty: 1); // Penalty for break
    }
    super.visitBreakStatement(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    if (_currentNestingLevel > 0) { // Only penalize if continuing something
      _incrementComplexity(penalty: 1); // Penalty for continue
    }
    super.visitContinueStatement(node);
  }

  // Logical operators in conditions
  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operatorType = node.operator.type;
    if (operatorType == TokenType.AMPERSAND_AMPERSAND || operatorType == TokenType.BAR_BAR) {
      // Increment for the operator itself if it's part of a sequence
      // Sonar's rule: "Increments for a sequence of binary logical operators"
      // And "Increments when a logical operator is not the same as the one before it in a sequence"
      if (_lastLogicalOperator != null && _lastLogicalOperator != operatorType) {
         _incrementComplexity(penalty: 1); // Penalty for switching operator type (e.g. && then ||)
      }
      _incrementComplexity(penalty: 1); // Base penalty for each logical operator
      _lastLogicalOperator = operatorType;
    }
    super.visitBinaryExpression(node); // Visit operands
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) { // ternary operator
    _incrementComplexityWithNesting(); // Ternary operators add complexity and a conceptual nesting
    // We don't strictly _enterNestableStructure here as it's an expression,
    // but its presence increases cognitive load.
    super.visitConditionalExpression(node);
    _lastLogicalOperator = null;
  }


  // Reset logical operator tracking when entering a new expression context
  // where a sequence of logical operators might start.
  // This is a simplification; Sonar's rules are more nuanced about sequences.
  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    TokenType? outerLastOperator = _lastLogicalOperator;
    _lastLogicalOperator = null;
    super.visitParenthesizedExpression(node);
    _lastLogicalOperator = outerLastOperator; // Restore for outer context if any
  }

  // Functions/Methods: The body itself doesn't start with complexity 1 like CC.
  // The complexity comes from its content.
  @override
  void visitFunctionExpression(FunctionExpression node) {
    // If this function is nested inside another, the declaration itself adds to parent's complexity
    // For now, we are calculating complexity OF this function, not its impact on parent.
    // Sonar rules might add +1 for nested functions to the parent.
    
    // Reset nesting for the new function scope.
    // The _complexity variable is for the current function being analyzed.
    // If we were to support nested functions properly, each would need its own CogC score.
    // This simple visitor calculates for one top-level function body at a time.
    super.visitFunctionExpression(node);
  }
}

