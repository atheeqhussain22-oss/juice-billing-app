import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('juice_billing.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        date_time TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_mode TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bill_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES bills(id)
      )
    ''');
  }

  Future<int> insertBill({
    required String customerName,
    required double total,
    required String paymentMode,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final billId = await txn.insert('bills', {
        'customer_name': customerName,
        'date_time': DateTime.now().toIso8601String(),
        'total_amount': total,
        'payment_mode': paymentMode,
      });

      for (var item in items) {
        await txn.insert('bill_items', {
          'bill_id': billId,
          'item_name': item['name'],
          'unit_price': item['price'],
          'quantity': item['qty'],
          'subtotal': (item['qty'] as int) * (item['price'] as double),
        });
      }
      return billId;
    });
  }

  Future<List<Map<String, dynamic>>> fetchBills() async {
    final db = await instance.database;
    return await db.query('bills', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> fetchBillDetails(int billId) async {
    final db = await instance.database;
    return await db.query('bill_items', where: 'bill_id = ?', whereArgs: [billId]);
  }
}
