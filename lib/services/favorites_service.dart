import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/favorite_model.dart';

class FavoritesService extends ChangeNotifier {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'favorites.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites(
            id TEXT PRIMARY KEY,
            contactId TEXT NOT NULL,
            name TEXT NOT NULL,
            callCount INTEGER DEFAULT 0,
            smsCount INTEGER DEFAULT 0,
            lastInteraction INTEGER NOT NULL,
            createdAt INTEGER NOT NULL,
            avatar BLOB
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_contact_id ON favorites(contactId)
        ''');
      },
      version: 1,
    );
  }

  Future<void> addFavorite(Favorite favorite) async {
    final db = await database;
    await db.insert(
      'favorites',
      favorite.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Favorite>> getAllFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return List.generate(maps.length, (i) => Favorite.fromMap(maps[i]));
  }

  Future<Favorite?> getFavorite(String contactId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'contactId = ?',
      whereArgs: [contactId],
    );
    if (maps.isNotEmpty) {
      return Favorite.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateFavorite(Favorite favorite) async {
    final db = await database;
    await db.update(
      'favorites',
      favorite.toMap(),
      where: 'id = ?',
      whereArgs: [favorite.id],
    );
  }

  Future<void> incrementInteractionCount(
    String contactId, {
    bool isCall = false,
  }) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE favorites 
      SET ${isCall ? 'callCount' : 'smsCount'} = ${isCall ? 'callCount' : 'smsCount'} + 1,
          lastInteraction = ?
      WHERE contactId = ?
    ''', [DateTime.now().millisecondsSinceEpoch, contactId]);
  }

  Future<void> removeFavorite(String id) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}