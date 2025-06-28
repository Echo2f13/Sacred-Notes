import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'models/user.dart';
import 'models/transaction_record.dart';
import 'models/category.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sacred_notes.db');
    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return _db!;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        mobile TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        amount REAL,
        is_payment INTEGER,
        description TEXT,
        date TEXT,
        category_id INTEGER,
        FOREIGN KEY(user_id) REFERENCES users(id),
        FOREIGN KEY(category_id) REFERENCES categories(id)
      )
    ''');
  }

  // User CRUD
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((m) => User.fromMap(m)).toList();
  }

  // Category CRUD
  Future<int> insertCategory(Category cat) async {
    final db = await database;
    return await db.insert('categories', cat.toMap());
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  // Transaction CRUD
  Future<int> insertTransaction(TransactionRecord txn) async {
    final db = await database;
    return await db.insert('transactions', txn.toMap());
  }

  Future<List<TransactionRecord>> getTransactions({int? userId}) async {
    final db = await database;
    final where = userId != null ? 'WHERE user_id = ?' : '';
    final args = userId != null ? [userId] : [];
    final maps = await db.rawQuery('SELECT * FROM transactions $where', args);
    return maps.map((m) => TransactionRecord.fromMap(m)).toList();
  }
}
