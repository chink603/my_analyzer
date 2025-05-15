import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class CyclomaticComplexityVisitor extends RecursiveAstVisitor<void> {
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