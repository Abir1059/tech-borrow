import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tech_borrow.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT UNIQUE,
        firstName TEXT,
        lastName TEXT,
        studentId TEXT,
        department TEXT,
        email TEXT UNIQUE,
        mobile TEXT,
        password TEXT,
        profilePic TEXT,
        createdAt TEXT
      )
    ''');

    // Items table
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        specs TEXT,
        userId TEXT,
        userEmail TEXT,
        ownerName TEXT,
        ownerStudentId TEXT,
        image TEXT,
        isAvailable INTEGER DEFAULT 1,
        createdAt TEXT
      )
    ''');

    // Borrow requests table
    await db.execute('''
      CREATE TABLE borrow_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemId INTEGER,
        itemTitle TEXT,
        ownerId TEXT,
        senderId TEXT,
        senderEmail TEXT,
        deadline TEXT,
        status TEXT DEFAULT 'pending',
        createdAt TEXT
      )
    ''');
  }

  // User Operations
  Future<int> insertUser(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('users', row);
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUserProfile(String uid, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'users',
      row,
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  // Item Operations
  Future<int> insertItem(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('items', row);
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    Database db = await database;
    return await db.query('items', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> getMyItems(String uid) async {
    Database db = await database;
    return await db.query(
      'items',
      where: 'userId = ?',
      whereArgs: [uid],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> deleteItem(int id) async {
    Database db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateItem(int id, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update('items', row, where: 'id = ?', whereArgs: [id]);
  }

  // Request Operations
  Future<int> insertRequest(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('borrow_requests', row);
  }

  Future<List<Map<String, dynamic>>> getIncomingRequests(String uid) async {
    Database db = await database;
    return await db.query(
      'borrow_requests',
      where: 'ownerId = ?',
      whereArgs: [uid],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateRequestStatus(int id, String status) async {
    Database db = await database;
    return await db.update(
      'borrow_requests',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
