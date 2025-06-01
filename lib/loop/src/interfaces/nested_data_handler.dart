import '../models/loop_result.dart';

abstract class INestedDataHandler<T> {
  LoopResult<List<T>> getItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
  });
} 