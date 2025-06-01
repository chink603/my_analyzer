import '../interfaces/nested_data_handler.dart';
import '../interfaces/data_transformer.dart';
import '../models/loop_result.dart';

class RecursiveNestedDataHandler<T> implements INestedDataHandler<T> {
  final IDataTransformer<T>? transformer;
  final bool allowEmpty;

  RecursiveNestedDataHandler({
    this.transformer,
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

      List<T> result = [];
      String? transformError;
      
      void processItem(dynamic item) {
        if (item is Map<String, dynamic>) {
          if (item[conditionKey] == conditionValue) {
            final list = item[listKey] as List?;
            if (list != null) {
              for (var element in list) {
                if (element is List) {
                  for (var subElement in element) {
                    processItem(subElement);
                  }
                } else if (element is Map<String, dynamic>) {
                  try {
                    if (transformer != null) {
                      result.add(transformer!.transform(element));
                    } else {
                      result.add(element as T);
                    }
                  } catch (e) {
                    transformError = 'ไม่สามารถแปลงข้อมูล: $e';
                  }
                }
              }
            }
          }
        }
      }

      processItem(data);
      
      if (transformError != null) {
        return LoopResult.error(transformError!, code: 'TRANSFORM_ERROR');
      }
      
      if (result.isEmpty && !allowEmpty) {
        return LoopResult.error(
          'ไม่พบข้อมูลที่ตรงกับเงื่อนไข',
          code: 'EMPTY_RESULT',
          details: {'conditionKey': conditionKey, 'conditionValue': conditionValue}
        );
      }
      return LoopResult.success(result);
    } catch (e) {
      return LoopResult.error('เกิดข้อผิดพลาด: $e', code: 'UNEXPECTED_ERROR');
    }
  }
} 