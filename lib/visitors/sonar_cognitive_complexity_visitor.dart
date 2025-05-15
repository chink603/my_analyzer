import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
enum NestingType { IF, ELSE, LOOP, SWITCH, CATCH, LAMBDA, TRY /* Try itself also nests finally */ }

class NestingContext {
  final NestingType type;
  final int depth; // The depth at which this context was created
  NestingContext(this.type, this.depth);
}
class SonarCognitiveComplexityVisitor extends RecursiveAstVisitor<void> {
  int _complexity = 0;
  // Stack to keep track of nesting levels for different types of structures.
  // Each element could be an object/map storing the type of structure and its contribution.
  final List<NestingContext> _nestingContextStack = [];
  final List<TokenType> _logicalOperatorSequence =
      []; // Tracks sequence of && or ||

  int get complexity => _complexity;

  SonarCognitiveComplexityVisitor();

  // --- Nesting Context Management ---
  void _enterNestable(NestingType type, {bool incrementsComplexity = true}) {
    if (incrementsComplexity) {
      _complexity += (1 + _currentNestingPenalty()); // B1 + B2
    }
    _nestingContextStack.add(NestingContext(type, _nestingContextStack.length));
  }

  void _exitNestable() {
    if (_nestingContextStack.isNotEmpty) {
      _nestingContextStack.removeLast();
    }
  }

  int _currentNestingPenalty() {
    // Sonar's rule: each structure in _nestingContextStack adds +1 to the penalty
    // for structures nested inside it.
    return _nestingContextStack.length;
  }

  // --- Logical Operator Sequence Management ---
  void _addLogicalOperator(TokenType operatorType) {
    if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
        operatorType == TokenType.BAR_BAR) {
      if (_logicalOperatorSequence.isNotEmpty &&
          _logicalOperatorSequence.last != operatorType) {
        _complexity++; // B4: Different logical operator in sequence
      }
      _complexity++; // B1: Each logical operator in a sequence
      _logicalOperatorSequence.add(operatorType);
    } else {
      // Non-logical operator breaks the sequence
      _clearLogicalOperatorSequence();
    }
  }

  void _clearLogicalOperatorSequence() {
    _logicalOperatorSequence.clear();
  }

  // --- AST Node Visiting Methods (Illustrative examples, needs significant expansion) ---

  @override
  void visitIfStatement(IfStatement node) {
    _enterNestable(NestingType.IF); // This will handle B1 + B2 for the 'if'
    _clearLogicalOperatorSequence(); // Condition starts a new sequence
    node.condition.accept(this);
    _clearLogicalOperatorSequence(); // Sequence ends after condition

    node.thenStatement.accept(this);
    _exitNestable(); // Exit 'if' nesting context

    AstNode? elseNode = node.elseStatement;
    if (elseNode != null) {
      // 'else if' (IfStatement) or 'else' (Block, etc.)
      // 'else' or 'else if' itself is a B1 increment
      _complexity++; // +1 for the 'else' or 'else if' branch
      if (elseNode is IfStatement) {
        // 'else if' is another IfStatement, it will handle its own nesting when visited
        elseNode.accept(this);
      } else {
        // Plain 'else'
        _enterNestable(NestingType.ELSE,
            incrementsComplexity: false); // 'else' nests but B1 already counted
        elseNode.accept(this);
        _exitNestable();
      }
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    _enterNestable(NestingType.LOOP);
    _clearLogicalOperatorSequence();
    node.forLoopParts.accept(this); // Visit conditions/initializers/updaters
    _clearLogicalOperatorSequence();
    node.body.accept(this);
    _exitNestable();
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _enterNestable(NestingType.LOOP);
    _clearLogicalOperatorSequence();
    node.condition.accept(this);
    _clearLogicalOperatorSequence();
    node.body.accept(this);
    _exitNestable();
  }

  @override
  void visitDoStatement(DoStatement node) {
    _enterNestable(NestingType.LOOP); // The loop structure
    node.body.accept(this); // Body is part of the loop's nesting
    _exitNestable(); // Exit body nesting before condition for CogC if condition is outside
    _clearLogicalOperatorSequence();
    node.condition.accept(this); // Condition adds complexity
    _clearLogicalOperatorSequence();
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _enterNestable(NestingType.SWITCH); // 'switch' itself +1 and nests
    _clearLogicalOperatorSequence();
    node.expression.accept(this);
    _clearLogicalOperatorSequence();
    node.members.forEach((member) => member.accept(this));
    _exitNestable();
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    // Sonar: "No increment for case/default in a switch (the switch gets one)"
    // However, SonarLint for Java DOES seem to increment for non-empty cases.
    // Let's follow the more common interpretation: cases add complexity if not empty.
    if (node.statements.isNotEmpty) {
      _complexity++; // +1 for each non-empty case
    }
    // Statements within a case are at the switch's nesting level
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    if (node.statements.isNotEmpty) {
      _complexity++;
    }
    super.visitSwitchDefault(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _enterNestable(NestingType.CATCH); // 'catch' +1 and nests
    node.body.accept(this);
    _exitNestable();
  }

  // B3: Flow-breaking structures (increment raw complexity, no nesting effect from themselves)
  @override
  void visitBreakStatement(BreakStatement node) {
    // Sonar: "Increments for each break or continue TO A LABEL,
    // or a break or continue that is not the last statement in a switch or loop"
    // This is hard to determine statically without full control flow graph.
    // Simplified: Add +1 if it breaks out of more than the innermost applicable scope.
    // For now, a simpler +1 if it exists within a nestable structure.
    if (_nestingContextStack.any((ctx) =>
        ctx.type == NestingType.LOOP || ctx.type == NestingType.SWITCH)) {
      if (node.label == null) {
        // Unlabeled break/continue
        // A more precise check would be to see if this 'break' targets
        // a loop/switch that is NOT the most immediate one in the stack.
        // For simplicity, any break/continue in a nested context gets +1.
        _complexity++;
      } else {
        _complexity++; // Labeled break/continue always adds.
      }
    }
    super.visitBreakStatement(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    if (_nestingContextStack.any((ctx) => ctx.type == NestingType.LOOP)) {
      if (node.label == null) {
        _complexity++;
      } else {
        _complexity++;
      }
    }
    super.visitContinueStatement(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    // ?:
    // Ternary operator itself adds +1, and it's affected by current nesting.
    _complexity += (1 + _currentNestingPenalty());
    _clearLogicalOperatorSequence();
    node.condition.accept(this);
    _clearLogicalOperatorSequence();
    // The then/else expressions are subject to the current nesting level for their content
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operatorType = node.operator.type;
    bool isCurrentLogical = operatorType == TokenType.AMPERSAND_AMPERSAND ||
        operatorType == TokenType.BAR_BAR;

    // Sonar: "No increment for the first operand in a sequence of binary logical operators."
    // This is implicitly handled because we increment *for the operator*.

    // Visit left operand first. It might contain its own logical sequences.
    // We need to isolate the logical sequence handling for this binary expression's level.
    List<TokenType> outerLogicalSequence = List.from(_logicalOperatorSequence);
    _clearLogicalOperatorSequence(); // Start fresh for left operand's potential sequence

    node.leftOperand.accept(this);

    // Restore sequence state from before visiting left, then add current operator
    _logicalOperatorSequence.clear();
    _logicalOperatorSequence.addAll(outerLogicalSequence);
    if (isCurrentLogical) {
      _addLogicalOperator(operatorType);
    } else {
      _clearLogicalOperatorSequence(); // Non-logical breaks sequence
    }

    node.rightOperand.accept(this);

    // After visiting both operands, restore the sequence state to what it was
    // before this binary expression, unless this expression itself was the start
    // of a new sequence (e.g., inside parentheses or after a non-logical op).
    // This is complex. For now, after a binary op, the sequence related to it ends.
    if (!isCurrentLogical || _logicalOperatorSequence.isEmpty) {
      // If not logical, or if stack was cleared by a deeper non-logical, restore outer.
      _logicalOperatorSequence.clear();
      _logicalOperatorSequence.addAll(outerLogicalSequence);
    } else {
      // If it was logical, the _addLogicalOperator and recursive calls should have handled it.
      // The sequence might continue or end based on what rightOperand was.
      // For simplicity after this binary expression, we might clear or restore.
      // Let's assume it potentially continues, so outer state might still be relevant.
      // This needs a very robust stack management like a parser.
    }
    if (!isCurrentLogical) {
      super.visitBinaryExpression(
          node); // Only visit children if not handling logical ops
    }
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    // Parentheses reset the logical operator sequence for the inner expression
    List<TokenType> outerSequence = List.from(_logicalOperatorSequence);
    _clearLogicalOperatorSequence();
    super.visitParenthesizedExpression(node);
    // After visiting inner, restore the outer sequence context
    _logicalOperatorSequence.clear();
    _logicalOperatorSequence.addAll(outerSequence);
  }

  // --- Entry points for analysis ---
  // These methods are called when this visitor is accepted by a FunctionDeclaration or MethodDeclaration.
  void _resetStateAndAnalyzeBody(AstNode bodyNode) {
    _complexity = 0;
    _nestingContextStack.clear();
    _clearLogicalOperatorSequence();
    bodyNode.accept(this); // Analyze the body
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _resetStateAndAnalyzeBody(node.functionExpression.body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.body != null) {
      _resetStateAndAnalyzeBody(node.body!);
    } else {
      _complexity = 0; // Abstract method or getter/setter without body
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Sonar: Lambdas/Nested functions get +1 and a nesting increment.
    // Their bodies are then analyzed with their own CogC (which this simplified visitor doesn't do separately).
    // For this visitor, we'll add to the parent's CogC.
    bool isTopLevelEquivalent =
        node.parent is FunctionDeclaration || node.parent is MethodDeclaration;

    if (!isTopLevelEquivalent) {
      // This is a lambda or true nested function.
      _complexity += (1 +
          _currentNestingPenalty()); // Increment for the lambda declaration itself + nesting.

      // Analyze its body within a new nesting context.
      _enterNestable(NestingType.LAMBDA,
          incrementsComplexity:
              false); // Lambda itself doesn't add to its own body's base
      node.body.accept(this);
      _exitNestable();
    } else {
      // This FunctionExpression is the body of a FunctionDeclaration or MethodDeclaration.
      // The complexity count for its content will be handled by the body.accept(this)
      // called from visitFunctionDeclaration/visitMethodDeclaration.
      // No _complexity increment for the FunctionExpression node itself in this case.
      // Just visit the body.
      node.body.accept(this);
    }
  }
}
