import 'package:flutter_test/flutter_test.dart';
import 'package:my_analyzer/loop/src/handlers/recursive_nested_data_handler.dart';
import 'package:my_analyzer/loop/src/interfaces/data_transformer.dart';
import 'package:my_analyzer/loop/src/models/loop_result.dart';
import 'package:my_analyzer/loop/src/utils/loop_util.dart';

void main() {
  group('RecursiveNestedDataHandler Tests', () {
    final testData = {
      'items': [
        {
          'id': 1,
          'name': 'Item 1',
          'items': [
            {
              'id': 2,
              'name': 'Item 1.1',
              'items': [
                {'id': 3, 'name': 'Item 1.1.1'},
                {'id': 4, 'name': 'Item 1.1.2'}
              ]
            }
          ]
        },
        {
          'id': 5,
          'name': 'Item 2',
          'items': [
            {'id': 6, 'name': 'Item 2.1'}
          ]
        }
      ]
    };

    test('should return items when key exists and items found', () {
      final handler = RecursiveNestedDataHandler<Map<String, dynamic>>();
      final result = handler.getItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 2);
      expect(result.value?[0]['name'], 'Item 1.1.1');
      expect(result.value?[1]['name'], 'Item 1.1.2');
    });

    test('should return error when key not found', () {
      final handler = RecursiveNestedDataHandler<Map<String, dynamic>>();
      final result = handler.getItems(
        data: testData,
        listKey: 'invalid_key',
        conditionKey: 'id',
        conditionValue: 1,
      );

      expect(result.isError, true);
      expect(result.error?.message, 'ไม่พบ key: invalid_key');
      expect(result.error?.code, 'KEY_NOT_FOUND');
    });

    test('should return error when no items found and allowEmpty is false', () {
      final handler = RecursiveNestedDataHandler<Map<String, dynamic>>(allowEmpty: false);
      final result = handler.getItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 999,
      );

      expect(result.isError, true);
      expect(result.error?.message, 'ไม่พบข้อมูลที่ตรงกับเงื่อนไข');
      expect(result.error?.code, 'EMPTY_RESULT');
    });

    test('should return empty list when no items found and allowEmpty is true', () {
      final handler = RecursiveNestedDataHandler<Map<String, dynamic>>(allowEmpty: true);
      final result = handler.getItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 999,
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 0);
    });

    test('should transform items when transformer is provided', () {
      final handler = RecursiveNestedDataHandler<String>(
        transformer: MapTransformer<String>((data) => data['name']),
      );
      final result = handler.getItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 2);
      expect(result.value?[0], 'Item 1.1.1');
      expect(result.value?[1], 'Item 1.1.2');
    });

    test('should handle transform errors', () {
      final handler = RecursiveNestedDataHandler<String>(
        transformer: MapTransformer<String>((data) => throw Exception('Transform error')),
      );
      final result = handler.getItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
      );

      expect(result.isError, true);
      expect(result.error?.code, 'TRANSFORM_ERROR');
    });

    test('should handle unexpected errors', () {
      final handler = RecursiveNestedDataHandler<Map<String, dynamic>>();
      final result = handler.getItems(
        data: <String, dynamic>{},
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
      );

      expect(result.isError, true);
      expect(result.error?.code, 'UNEXPECTED_ERROR');
    });
  });
} 