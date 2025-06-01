import 'package:dartz/dartz.dart';

class LoopError {
  final String message;
  final String? code;
  final dynamic details;

  LoopError(this.message, {this.code, this.details});

  @override
  String toString() => 'LoopError: $message${code != null ? ' (Code: $code)' : ''}';
}

class LoopResult<T> {
  final Either<LoopError, T> result;

  LoopResult(this.result);

  factory LoopResult.success(T value) => LoopResult(Right(value));
  factory LoopResult.error(String message, {String? code, dynamic details}) => 
      LoopResult(Left(LoopError(message, code: code, details: details)));

  T? get value => result.fold((_) => null, (value) => value);
  LoopError? get error => result.fold((error) => error, (_) => null);
  bool get isSuccess => result.isRight();
  bool get isError => result.isLeft();

  R fold<R>(R Function(LoopError) onError, R Function(T) onSuccess) =>
      result.fold(onError, onSuccess);
} 