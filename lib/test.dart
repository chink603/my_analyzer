import 'package:my_analyzer/loop/loop.dart';
// // Interface สำหรับการจัดการข้อมูล

void main() {
  // ข้อมูลตัวอย่าง
  final test = {
    'list': [
      {
        'catalog': "food",
        'list': [
          [
            {'name': 'ข้าว', 'price': 30, 'type': 'main'},
            {'name': 'ส้ม', 'price': 20, 'type': 'fruit'}
          ],
          [
            {'name': 'น้ำ', 'price': 15, 'type': 'drink'},
            {'name': 'ขนม', 'price': 25, 'type': 'snack'}
          ]
        ]
      },
      {
        'catalog': "drink",
        'list': [
          [
            {'name': 'กาแฟ', 'price': 35, 'type': 'hot'},
            {'name': 'ชา', 'price': 25, 'type': 'hot'}
          ]
        ]
      }
    ]
  };

  print('=== ทดสอบฟังก์ชันพื้นฐาน ===');
  
  // 1. getNestedItems
  final basicResult = LoopUtil.getNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
  );
  basicResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('รายการอาหาร:');
      items.forEach((item) => print('- ${item['name']}'));
    }
  );

  // 2. getNestedItemsRecursive
  final recursiveResult = LoopUtil.getNestedItemsRecursive<String>(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    fromMap: (item) => item['name'].toString().toUpperCase(),
  );
  recursiveResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('\nรายการอาหาร (แปลงเป็นตัวพิมพ์ใหญ่):');
      items.forEach((item) => print('- $item'));
    }
  );

  // 3. countNestedItems
  final countResult = LoopUtil.countNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
  );
  countResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (count) => print('\nจำนวนรายการอาหาร: $count')
  );

  // 4. findNestedItem
  final findResult = LoopUtil.findNestedItem(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    predicate: (item) => item['price'] > 20,
  );
  findResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (item) => print('\nรายการที่ราคามากกว่า 20: ${item?['name']}')
  );

  // 5. filterNestedItems
  final filterResult = LoopUtil.filterNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    predicate: (item) => item['type'] == 'main',
  );
  filterResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('\nรายการอาหารประเภท main:');
      items.forEach((item) => print('- ${item['name']}'));
    }
  );

  // 6. mapNestedItems
  final mapResult = LoopUtil.mapNestedItems<String>(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    mapper: (item) => '${item['name']} - ${item['price']} บาท',
  );
  mapResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('\nรายการอาหารพร้อมราคา:');
      items.forEach((item) => print('- $item'));
    }
  );

  // 7. groupNestedItems
  final groupResult = LoopUtil.groupNestedItems<String>(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    keySelector: (item) => item['type'],
  );
  groupResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (groups) {
      print('\nจัดกลุ่มตามประเภท:');
      groups.forEach((type, items) {
        print('ประเภท $type:');
        items.forEach((item) => print('- ${item['name']}'));
      });
    }
  );

  // 8. sortNestedItems
  final sortResult = LoopUtil.sortNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    compare: (a, b) => (a['price'] as int).compareTo(b['price'] as int),
  );
  sortResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('\nเรียงตามราคา:');
      items.forEach((item) => print('- ${item['name']}: ${item['price']} บาท'));
    }
  );

  // 9. aggregateNestedItems
  final aggregateResult = LoopUtil.aggregateNestedItems<int>(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    initialValue: 0,
    aggregator: (sum, item) => sum + (item['price'] as int),
  );
  aggregateResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (total) => print('\nราคารวม: $total บาท')
  );

  // 10. distinctNestedItems
  final distinctResult = LoopUtil.distinctNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    keySelector: (item) => item['type'],
  );
  distinctResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('\nรายการที่ไม่ซ้ำประเภท:');
      items.forEach((item) => print('- ${item['name']} (${item['type']})'));
    }
  );

  // 11. takeNestedItems
  final takeResult = LoopUtil.takeNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    count: 2,
  );
  takeResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('\nรายการ 2 รายการแรก:');
      items.forEach((item) => print('- ${item['name']}'));
    }
  );

  // 12. skipNestedItems
  final skipResult = LoopUtil.skipNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    count: 1,
  );
  skipResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('\nรายการที่ข้าม 1 รายการแรก:');
      items.forEach((item) => print('- ${item['name']}'));
    }
  );

  // 13. chunkNestedItems
  final chunkResult = LoopUtil.chunkNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    chunkSize: 2,
  );
  chunkResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (chunks) {
      print('\nแบ่งเป็นกลุ่มละ 2 รายการ:');
      chunks.asMap().forEach((index, items) {
        print('กลุ่ม ${index + 1}:');
        items.forEach((item) => print('- ${item['name']}'));
      });
    }
  );

  // 14. repeatNestedItems
  final repeatResult = LoopUtil.repeatNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    count: 2,
  );
  repeatResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('\nรายการที่ซ้ำ 2 ครั้ง:');
      items.forEach((item) => print('- ${item['name']}'));
    }
  );

  // 15. shuffleNestedItems
  final shuffleResult = LoopUtil.shuffleNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
  );
  shuffleResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('\nรายการที่สลับตำแหน่ง:');
      items.forEach((item) => print('- ${item['name']}'));
    }
  );

  // 16. concatNestedItems
  final concatResult = LoopUtil.concatNestedItems(
    dataList: [test, test],
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
  );
  concatResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('\nรายการที่รวมกัน:');
      items.forEach((item) => print('- ${item['name']}'));
    }
  );

  // 17. repeatNestedItemsByCondition
  final repeatByConditionResult = LoopUtil.repeatNestedItemsByCondition(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    repeatCountSelector: (item) => (item['price'] as int) ~/ 10,
  );
  repeatByConditionResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (items) {
      print('\nรายการที่ซ้ำตามราคา (ราคา/10):');
      items.forEach((item) => print('- ${item['name']} (${item['price']} บาท)'));
    }
  );

  // 18. groupByNestedItems
  final groupByResult = LoopUtil.groupByNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    groupKeySelector: (item) => item['type'],
  );
  groupByResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (groups) {
      print('\nจัดกลุ่มตามประเภท:');
      groups.forEach((type, items) {
        print('ประเภท $type:');
        items.forEach((item) => print('- ${item['name']}'));
      });
    }
  );

  // 19. maxNestedItem
  final maxResult = LoopUtil.maxNestedItem(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    selector: (item) => item['price'] as num,
  );
  maxResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (item) => print('\nรายการที่มีราคาสูงสุด: ${item['name']} (${item['price']} บาท)')
  );

  // 20. minNestedItem
  final minResult = LoopUtil.minNestedItem(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    selector: (item) => item['price'] as num,
  );
  minResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (item) => print('\nรายการที่มีราคาต่ำสุด: ${item['name']} (${item['price']} บาท)')
  );

  // 21. anyNestedItem
  final anyResult = LoopUtil.anyNestedItem(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    predicate: (item) => item['price'] > 25,
  );
  anyResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (hasExpensive) => print('\nมีรายการที่ราคามากกว่า 25 บาท: $hasExpensive')
  );

  // 22. allNestedItems
  final allResult = LoopUtil.allNestedItems(
    data: test,
    listKey: 'list',
    conditionKey: 'catalog',
    conditionValue: 'food',
    predicate: (item) => item['price'] > 10,
  );
  allResult.fold(
    (error) => print('เกิดข้อผิดพลาด: $error'),
    (allExpensive) => print('\nทุกรายการมีราคามากกว่า 10 บาท: $allExpensive')
  );
}
