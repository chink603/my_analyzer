import 'package:flutter_test/flutter_test.dart';
import 'package:my_analyzer/loop/src/utils/loop_util.dart';

void main() {
  group('LoopUtil Tests', () {
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

    test('getNestedItems should return correct items', () {
      final result = LoopUtil.getNestedItems(
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

    test('getNestedItemsRecursive should return all nested items', () {
      final result = LoopUtil.getNestedItemsRecursive<Map<String, dynamic>>(
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

    test('countNestedItems should return correct count', () {
      final result = LoopUtil.countNestedItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
      );

      expect(result.isSuccess, true);
      expect(result.value, 2);
    });

    test('findNestedItem should return first matching item', () {
      final result = LoopUtil.findNestedItem(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        predicate: (item) => item['name'] == 'Item 1.1.1',
      );

      expect(result.isSuccess, true);
      expect(result.value?['name'], 'Item 1.1.1');
    });

    test('filterNestedItems should return filtered items', () {
      final result = LoopUtil.filterNestedItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        predicate: (item) => item['name'].contains('1.1'),
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 2);
      expect(result.value?[0]['name'], 'Item 1.1.1');
      expect(result.value?[1]['name'], 'Item 1.1.2');
    });

    test('mapNestedItems should transform items', () {
      final result = LoopUtil.mapNestedItems<String>(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        mapper: (item) => item['name'],
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 2);
      expect(result.value?[0], 'Item 1.1.1');
      expect(result.value?[1], 'Item 1.1.2');
    });

    test('groupNestedItems should group items by key', () {
      final result = LoopUtil.groupNestedItems<String>(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        keySelector: (item) => item['name'].split('.')[1],
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 1);
      expect(result.value?['1']?.length, 2);
    });

    test('sortNestedItems should sort items', () {
      final result = LoopUtil.sortNestedItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        compare: (a, b) => a['name'].compareTo(b['name']),
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 2);
      expect(result.value?[0]['name'], 'Item 1.1.1');
      expect(result.value?[1]['name'], 'Item 1.1.2');
    });

    test('aggregateNestedItems should aggregate items', () {
      final result = LoopUtil.aggregateNestedItems<String>(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        initialValue: '',
        aggregator: (acc, item) => acc + item['name'] + ', ',
      );

      expect(result.isSuccess, true);
      expect(result.value, 'Item 1.1.1, Item 1.1.2, ');
    });

    test('distinctNestedItems should remove duplicates', () {
      final result = LoopUtil.distinctNestedItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        keySelector: (item) => item['name'].split('.')[1],
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 1);
    });

    test('takeNestedItems should limit items', () {
      final result = LoopUtil.takeNestedItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        count: 1,
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 1);
      expect(result.value?[0]['name'], 'Item 1.1.1');
    });

    test('skipNestedItems should skip items', () {
      final result = LoopUtil.skipNestedItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        count: 1,
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 1);
      expect(result.value?[0]['name'], 'Item 1.1.2');
    });

    test('chunkNestedItems should split items into chunks', () {
      final result = LoopUtil.chunkNestedItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        chunkSize: 1,
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 2);
      expect(result.value?[0].length, 1);
      expect(result.value?[1].length, 1);
    });

    test('repeatNestedItems should repeat items', () {
      final result = LoopUtil.repeatNestedItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        count: 2,
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 4);
    });

    test('shuffleNestedItems should shuffle items', () {
      final result = LoopUtil.shuffleNestedItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 2);
    });

    test('concatNestedItems should combine items from multiple sources', () {
      final result = LoopUtil.concatNestedItems(
        dataList: [testData, testData],
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 4);
    });

    test('repeatNestedItemsByCondition should repeat items based on condition', () {
      final result = LoopUtil.repeatNestedItemsByCondition(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        repeatCountSelector: (item) => 2,
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 4);
    });

    test('groupByNestedItems should group items by key', () {
      final result = LoopUtil.groupByNestedItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        groupKeySelector: (item) => item['name'].split('.')[1],
      );

      expect(result.isSuccess, true);
      expect(result.value?.length, 1);
      expect(result.value?['1']?.length, 2);
    });

    test('maxNestedItem should return item with maximum value', () {
      final result = LoopUtil.maxNestedItem(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        selector: (item) => item['id'],
      );

      expect(result.isSuccess, true);
      expect(result.value?['id'], 4);
    });

    test('minNestedItem should return item with minimum value', () {
      final result = LoopUtil.minNestedItem(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        selector: (item) => item['id'],
      );

      expect(result.isSuccess, true);
      expect(result.value?['id'], 3);
    });

    test('anyNestedItem should return true if any item matches predicate', () {
      final result = LoopUtil.anyNestedItem(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        predicate: (item) => item['name'] == 'Item 1.1.1',
      );

      expect(result.isSuccess, true);
      expect(result.value, true);
    });

    test('allNestedItems should return true if all items match predicate', () {
      final result = LoopUtil.allNestedItems(
        data: testData,
        listKey: 'items',
        conditionKey: 'id',
        conditionValue: 1,
        predicate: (item) => item['name'].contains('Item'),
      );

      expect(result.isSuccess, true);
      expect(result.value, true);
    });
  });
}