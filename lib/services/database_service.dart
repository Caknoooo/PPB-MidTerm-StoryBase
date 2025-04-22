import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/story.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'story_base.db');
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stories(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        imageUrl TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  Future<String> insertStory(Story story) async {
    final Database db = await database;
    story.id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert(
      'stories',
      story.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return story.id!;
  }

  Future<List<Story>> getStories() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stories',
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Story.fromMap(maps[i]);
    });
  }

  Future<Story?> getStory(String id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Story.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateStory(Story story) async {
    final Database db = await database;
    story.updatedAt = DateTime.now();
    await db.update(
      'stories',
      story.toMap(),
      where: 'id = ?',
      whereArgs: [story.id],
    );
  }

  Future<void> deleteStory(String id) async {
    final Database db = await database;
    await db.delete('stories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllStories() async {
    final Database db = await database;
    await db.delete('stories');
  }
}
