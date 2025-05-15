import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class NestingDepthVisitor extends RecursiveAstVisitor<void> {
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