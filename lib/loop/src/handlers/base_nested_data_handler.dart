import '../interfaces/nested_data_handler.dart';
import '../interfaces/data_transformer.dart';
import '../models/loop_result.dart';

class BaseNestedDataHandler<T> implements INestedDataHandler<T> {
  final IDataTransformer<T>? transformer;
  final int depth;
  final bool allowEmpty;

  BaseNestedDataHandler({
    this.transformer,
    this.depth = 2,
    this.allowEmpty = false,
  });

  @override
  LoopResult<List<T>> getItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
  }) {
    try {
      if (!data.containsKey(listKey)) {
        return LoopResult.error('ไม่พบ key: $listKey', code: 'KEY_NOT_FOUND');
      }

      final result = data[listKey]?.where((item) => item[conditionKey] == conditionValue)
          .expand((item) {
            var currentList = item[listKey] as List? ?? [];
            for (var i = 0; i < depth - 1; i++) {
              currentList = currentList.expand((list) => list as List).toList();
            }
            return currentList;
          })
          .whereType<Map<String, dynamic>>()
          .toList() ?? [];

      if (result.isEmpty && !allowEmpty) {
        return LoopResult.error(
          'ไม่พบข้อมูลที่ตรงกับเงื่อนไข',
          code: 'EMPTY_RESULT',
          details: {'conditionKey': conditionKey, 'conditionValue': conditionValue}
        );
      }

      if (transformer != null) {
        return LoopResult.success(result.map((item) => transformer!.transform(item)).toList());
      }
      return LoopResult.success(result as List<T>);
    } catch (e) {
      return LoopResult.error('เกิดข้อผิดพลาด: $e', code: 'UNEXPECTED_ERROR');
    }
  }
} 