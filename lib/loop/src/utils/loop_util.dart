import 'package:collection/collection.dart';
import '../handlers/base_nested_data_handler.dart';
import '../handlers/recursive_nested_data_handler.dart';
import '../models/loop_result.dart';
import '../interfaces/data_transformer.dart';
// Helper class สำหรับการแปลงข้อมูล
class MapTransformer<T> implements IDataTransformer<T> {
  final T Function(Map<String, dynamic>) fromMap;

  MapTransformer(this.fromMap);

  @override
  T transform(Map<String, dynamic> data) => fromMap(data);
}

class LoopUtil {
  /// ฟังก์ชันพื้นฐานสำหรับดึงข้อมูลจากโครงสร้างข้อมูลแบบซ้อน
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการดึงข้อมูล
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// - allowEmpty: อนุญาตให้คืนค่าเป็น list ว่างหรือไม่ (default: false)
  /// 
  /// Returns:
  /// - LoopResult<List<Map<String, dynamic>>>: ผลลัพธ์ที่ได้จากข้อมูล
  static LoopResult<List<Map<String, dynamic>>> getNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    int depth = 2,
    bool allowEmpty = false,
  }) {
    final handler = BaseNestedDataHandler<Map<String, dynamic>>(
      depth: depth,
      allowEmpty: allowEmpty,
    );
    return handler.getItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
    );
  }

  /// ฟังก์ชันดึงข้อมูลแบบ Recursive จากโครงสร้างข้อมูลแบบซ้อน
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการดึงข้อมูล
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - fromMap: ฟังก์ชันสำหรับแปลงข้อมูล (optional)
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// - allowEmpty: อนุญาตให้คืนค่าเป็น list ว่างหรือไม่ (default: false)
  /// 
  /// Returns:
  /// - LoopResult<List<T>>: ผลลัพธ์ที่ได้จากข้อมูล
  static LoopResult<List<T>> getNestedItemsRecursive<T>({
    required dynamic data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    T Function(Map<String, dynamic>)? fromMap,
    int depth = 2,
    bool allowEmpty = false,
  }) {
    final handler = RecursiveNestedDataHandler<T>(
      transformer: fromMap != null ? MapTransformer<T>(fromMap) : null,
      allowEmpty: allowEmpty,
    );
    return handler.getItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
    );
  }

  /// ฟังก์ชันนับจำนวนข้อมูลที่ตรงเงื่อนไข
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการนับ
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<int>: จำนวนข้อมูลที่ตรงเงื่อนไข
  static LoopResult<int> countNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) => LoopResult.success(items.length)
    );
  }

  /// ฟังก์ชันค้นหาข้อมูลที่ตรงเงื่อนไข
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการค้นหา
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - predicate: ฟังก์ชันสำหรับตรวจสอบเงื่อนไขเพิ่มเติม
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<Map<String, dynamic>?>: ข้อมูลที่พบ หรือ null ถ้าไม่พบ
  static LoopResult<Map<String, dynamic>?> findNestedItem({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required bool Function(Map<String, dynamic>) predicate,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) {
        final found = items.firstWhereOrNull(predicate);
        return LoopResult.success(found);
      }
    );
  }

  /// ฟังก์ชันกรองข้อมูลตามเงื่อนไข
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการกรอง
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - predicate: ฟังก์ชันสำหรับตรวจสอบเงื่อนไขเพิ่มเติม
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<List<Map<String, dynamic>>>: ข้อมูลที่ผ่านการกรอง
  static LoopResult<List<Map<String, dynamic>>> filterNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required bool Function(Map<String, dynamic>) predicate,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) => LoopResult.success(items.where(predicate).toList())
    );
  }

  /// ฟังก์ชันแปลงข้อมูลเป็นรูปแบบใหม่
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการแปลง
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - mapper: ฟังก์ชันสำหรับแปลงข้อมูล
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<List<R>>: ข้อมูลที่แปลงแล้ว
  static LoopResult<List<R>> mapNestedItems<R>({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required R Function(Map<String, dynamic>) mapper,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) => LoopResult.success(items.map(mapper).toList())
    );
  }

  /// ฟังก์ชันจัดกลุ่มข้อมูลตาม key ที่กำหนด
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการจัดกลุ่ม
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - keySelector: ฟังก์ชันสำหรับเลือก key ในการจัดกลุ่ม
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<Map<K, List<Map<String, dynamic>>>>: ข้อมูลที่จัดกลุ่มแล้ว
  static LoopResult<Map<K, List<Map<String, dynamic>>>> groupNestedItems<K>({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required K Function(Map<String, dynamic>) keySelector,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) => LoopResult.success(items.groupListsBy(keySelector))
    );
  }

  /// ฟังก์ชันเรียงลำดับข้อมูล
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการเรียง
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - compare: ฟังก์ชันสำหรับเปรียบเทียบข้อมูล
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<List<Map<String, dynamic>>>: ข้อมูลที่เรียงแล้ว
  static LoopResult<List<Map<String, dynamic>>> sortNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required int Function(Map<String, dynamic>, Map<String, dynamic>) compare,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) => LoopResult.success(items.sorted(compare))
    );
  }

  /// ฟังก์ชันรวมข้อมูลตามเงื่อนไข
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการรวม
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - initialValue: ค่าเริ่มต้น
  /// - aggregator: ฟังก์ชันสำหรับรวมข้อมูล
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<R>: ผลลัพธ์ที่รวมแล้ว
  static LoopResult<R> aggregateNestedItems<R>({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required R initialValue,
    required R Function(R, Map<String, dynamic>) aggregator,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) => LoopResult.success(items.fold(initialValue, aggregator))
    );
  }

  /// ฟังก์ชันกรองข้อมูลซ้ำตาม key ที่กำหนด
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการกรอง
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - keySelector: ฟังก์ชันสำหรับเลือก key ในการกรองซ้ำ
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<List<Map<String, dynamic>>>: ข้อมูลที่กรองซ้ำแล้ว
  static LoopResult<List<Map<String, dynamic>>> distinctNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required dynamic Function(Map<String, dynamic>) keySelector,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) {
        final seen = <dynamic>{};
        return LoopResult.success(
          items.where((item) => seen.add(keySelector(item))).toList()
        );
      }
    );
  }

  /// ฟังก์ชันจำกัดจำนวนข้อมูล
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการจำกัด
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - count: จำนวนข้อมูลที่ต้องการ
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<List<Map<String, dynamic>>>: ข้อมูลที่จำกัดแล้ว
  static LoopResult<List<Map<String, dynamic>>> takeNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required int count,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) => LoopResult.success(items.take(count).toList())
    );
  }

  /// ฟังก์ชันข้ามข้อมูลตามจำนวนที่กำหนด
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการข้าม
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - count: จำนวนข้อมูลที่ต้องการข้าม
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<List<Map<String, dynamic>>>: ข้อมูลที่ข้ามแล้ว
  static LoopResult<List<Map<String, dynamic>>> skipNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required int count,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) => LoopResult.success(items.skip(count).toList())
    );
  }

  /// ฟังก์ชันแบ่งข้อมูลเป็นกลุ่มตามขนาดที่กำหนด
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการแบ่ง
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - chunkSize: ขนาดของแต่ละกลุ่ม
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<List<List<Map<String, dynamic>>>>: ข้อมูลที่แบ่งกลุ่มแล้ว
  static LoopResult<List<List<Map<String, dynamic>>>> chunkNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required int chunkSize,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) {
        final chunks = <List<Map<String, dynamic>>>[];
        for (var i = 0; i < items.length; i += chunkSize) {
          chunks.add(items.skip(i).take(chunkSize).toList());
        }
        return LoopResult.success(chunks);
      }
    );
  }

  /// ฟังก์ชันจำลองข้อมูลซ้ำตามจำนวนที่กำหนด
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการจำลอง
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - count: จำนวนครั้งที่ต้องการจำลอง
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<List<Map<String, dynamic>>>: ข้อมูลที่จำลองแล้ว
  static LoopResult<List<Map<String, dynamic>>> repeatNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required int count,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) => LoopResult.success(List.generate(count, (_) => items).expand((x) => x).toList())
    );
  }

  /// ฟังก์ชันสุ่มลำดับข้อมูล
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการสุ่ม
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<List<Map<String, dynamic>>>: ข้อมูลที่สุ่มแล้ว
  static LoopResult<List<Map<String, dynamic>>> shuffleNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) {
        final shuffled = List<Map<String, dynamic>>.from(items)..shuffle();
        return LoopResult.success(shuffled);
      }
    );
  }

  /// ฟังก์ชันรวมข้อมูลจากหลายแหล่ง
  /// 
  /// Parameters:
  /// - dataList: รายการข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการรวม
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<List<Map<String, dynamic>>>: ข้อมูลที่รวมแล้ว
  static LoopResult<List<Map<String, dynamic>>> concatNestedItems({
    required List<Map<String, dynamic>> dataList,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    int depth = 2,
  }) {
    try {
      final results = <Map<String, dynamic>>[];
      for (final data in dataList) {
        final items = getNestedItems(
          data: data,
          listKey: listKey,
          conditionKey: conditionKey,
          conditionValue: conditionValue,
          depth: depth,
          allowEmpty: true,
        );
        
        items.fold(
          (error) => throw error,
          (items) => results.addAll(items)
        );
      }
      return LoopResult.success(results);
    } catch (e) {
      return LoopResult.error('เกิดข้อผิดพลาด: $e', code: 'CONCAT_ERROR');
    }
  }

  /// ฟังก์ชันจำลองข้อมูลซ้ำตามเงื่อนไข
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการจำลอง
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - repeatCountSelector: ฟังก์ชันสำหรับกำหนดจำนวนครั้งที่ต้องการจำลอง
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<List<Map<String, dynamic>>>: ข้อมูลที่จำลองแล้ว
  static LoopResult<List<Map<String, dynamic>>> repeatNestedItemsByCondition({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required int Function(Map<String, dynamic>) repeatCountSelector,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) {
        final result = <Map<String, dynamic>>[];
        for (final item in items) {
          final count = repeatCountSelector(item);
          result.addAll(List.generate(count, (_) => item));
        }
        return LoopResult.success(result);
      }
    );
  }

  /// ฟังก์ชันจัดกลุ่มข้อมูลตาม key ที่กำหนด
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการจัดกลุ่ม
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - groupKeySelector: ฟังก์ชันสำหรับเลือก key ในการจัดกลุ่ม
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<Map<String, List<Map<String, dynamic>>>>: ข้อมูลที่จัดกลุ่มแล้ว
  static LoopResult<Map<String, List<Map<String, dynamic>>>> groupByNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required String Function(Map<String, dynamic>) groupKeySelector,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) {
        final groups = <String, List<Map<String, dynamic>>>{};
        for (final item in items) {
          final key = groupKeySelector(item);
          groups.putIfAbsent(key, () => []).add(item);
        }
        return LoopResult.success(groups);
      }
    );
  }

  /// ฟังก์ชันหาข้อมูลที่มีค่าสูงสุดตามเงื่อนไข
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการค้นหา
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - selector: ฟังก์ชันสำหรับเลือกค่าที่ต้องการเปรียบเทียบ
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<Map<String, dynamic>>: ข้อมูลที่มีค่าสูงสุด หรือ error ถ้าไม่พบข้อมูล
  static LoopResult<Map<String, dynamic>> maxNestedItem({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required num Function(Map<String, dynamic>) selector,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) {
        if (items.isEmpty) {
          return LoopResult.error('ไม่พบข้อมูล', code: 'EMPTY_DATA');
        }
        return LoopResult.success(
          items.reduce((a, b) => selector(a) > selector(b) ? a : b)
        );
      }
    );
  }

  /// ฟังก์ชันหาข้อมูลที่มีค่าต่ำสุดตามเงื่อนไข
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการค้นหา
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - selector: ฟังก์ชันสำหรับเลือกค่าที่ต้องการเปรียบเทียบ
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<Map<String, dynamic>>: ข้อมูลที่มีค่าต่ำสุด หรือ error ถ้าไม่พบข้อมูล
  static LoopResult<Map<String, dynamic>> minNestedItem({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required num Function(Map<String, dynamic>) selector,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) {
        if (items.isEmpty) {
          return LoopResult.error('ไม่พบข้อมูล', code: 'EMPTY_DATA');
        }
        return LoopResult.success(
          items.reduce((a, b) => selector(a) < selector(b) ? a : b)
        );
      }
    );
  }

  /// ฟังก์ชันตรวจสอบว่ามีข้อมูลที่ตรงเงื่อนไขหรือไม่
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการตรวจสอบ
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - predicate: ฟังก์ชันสำหรับตรวจสอบเงื่อนไขเพิ่มเติม
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<bool>: true ถ้ามีข้อมูลที่ตรงเงื่อนไข, false ถ้าไม่มี
  static LoopResult<bool> anyNestedItem({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required bool Function(Map<String, dynamic>) predicate,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) => LoopResult.success(items.any(predicate))
    );
  }

  /// ฟังก์ชันตรวจสอบว่าทุกข้อมูลตรงเงื่อนไขหรือไม่
  /// 
  /// Parameters:
  /// - data: ข้อมูลต้นทาง
  /// - listKey: key ของ list ที่ต้องการตรวจสอบ
  /// - conditionKey: key ที่ใช้ในการกรอง
  /// - conditionValue: ค่าที่ใช้ในการกรอง
  /// - predicate: ฟังก์ชันสำหรับตรวจสอบเงื่อนไขเพิ่มเติม
  /// - depth: ความลึกของข้อมูลที่ต้องการดึง (default: 2)
  /// 
  /// Returns:
  /// - LoopResult<bool>: true ถ้าทุกข้อมูลตรงเงื่อนไข, false ถ้ามีข้อมูลที่ไม่ตรงเงื่อนไข
  static LoopResult<bool> allNestedItems({
    required Map<String, dynamic> data,
    required String listKey,
    required String conditionKey,
    required dynamic conditionValue,
    required bool Function(Map<String, dynamic>) predicate,
    int depth = 2,
  }) {
    final items = getNestedItems(
      data: data,
      listKey: listKey,
      conditionKey: conditionKey,
      conditionValue: conditionValue,
      depth: depth,
      allowEmpty: true,
    );

    return items.fold(
      (error) => LoopResult.error(error.message, code: error.code, details: error.details),
      (items) => LoopResult.success(items.every(predicate))
    );
  }
} 