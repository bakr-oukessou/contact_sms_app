import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/favorite_model.dart';
import 'firebase_service.dart';

class FavoritesService extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
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

  Future<void> syncFavoritesToFirebase(String userId) async {
    try {
      final favorites = await getAllFavorites();
      final favoritesRef = _firebaseService.getUserRef(userId).child('favorites');
      
      await favoritesRef.set({
        'lastSynced': ServerValue.timestamp,
        'items': favorites.map((f) => {
          'id': f.id,
          'contactId': f.contactId,
          'name': f.name,
          'callCount': f.callCount,
          'smsCount': f.smsCount,
          'lastInteraction': f.lastInteraction.millisecondsSinceEpoch,
          'createdAt': f.createdAt.millisecondsSinceEpoch,
          'avatar': f.avatar?.toList(),
        }).toList(),
      });
      
      notifyListeners();
    } catch (e) {
      print('Error syncing favorites to Firebase: $e');
      rethrow;
    }
  }

  Future<void> restoreFavoritesFromFirebase(String userId) async {
    try {
      final snapshot = await _firebaseService.getUserRef(userId)
          .child('favorites/items')
          .once();

      final List<dynamic>? favoritesList = snapshot.snapshot.value as List<dynamic>?;
      if (favoritesList == null) return;

      final db = await database;
      await db.transaction((txn) async {
        // Clear existing favorites
        await txn.delete('favorites');
        
        // Insert restored favorites
        for (final item in favoritesList) {
          await txn.insert('favorites', {
            'id': item['id'],
            'contactId': item['contactId'],
            'name': item['name'],
            'callCount': item['callCount'],
            'smsCount': item['smsCount'],
            'lastInteraction': item['lastInteraction'],
            'createdAt': item['createdAt'],
            'avatar': item['avatar'] != null 
                ? Uint8List.fromList(List<int>.from(item['avatar']))
                : null,
          });
        }
      });
      
      notifyListeners();
    } catch (e) {
      print('Error restoring favorites from Firebase: $e');
      rethrow;
    }
  }

  Future<void> incrementInteractionCount(String contactId, {bool isCall = false}) async {
    try {
      final db = await database;
      final favorite = await getFavorite(contactId);

      if (favorite != null) {
        final updatedFavorite = Favorite(
          id: favorite.id,
          contactId: favorite.contactId,
          name: favorite.name,
          callCount: isCall ? favorite.callCount + 1 : favorite.callCount,
          smsCount: isCall ? favorite.smsCount : favorite.smsCount + 1,
          lastInteraction: DateTime.now(),
          createdAt: favorite.createdAt,
          avatar: favorite.avatar,
        );

        await db.update(
          'favorites',
          updatedFavorite.toMap(),
          where: 'id = ?',
          whereArgs: [favorite.id],
        );

        notifyListeners();
      }
    } catch (e) {
      print("Error incrementing interaction count: $e");
      rethrow;
    }
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

  Future<List<FavoriteStats>> getInteractionStats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      columns: ['contactId', 'name', 'callCount', 'smsCount', 'lastInteraction'],
    );

    return maps.map((map) {
      final totalInteractions = map['callCount'] + map['smsCount'];
      final callPercentage = map['callCount'] / totalInteractions;

      return FavoriteStats(
        contactId: map['contactId'],
        name: map['name'],
        totalInteractions: totalInteractions,
        callPercentage: callPercentage,
        lastInteraction: DateTime.fromMillisecondsSinceEpoch(map['lastInteraction']),
      );
    }).toList();
  }

  Future<void> addToFavorites(String contactId, String name, {Uint8List? avatar}) async {
    final favorite = Favorite(
      id: contactId,
      contactId: contactId,
      name: name,
      callCount: 0,
      smsCount: 0,
      lastInteraction: DateTime.now(),
      createdAt: DateTime.now(),
      avatar: avatar,
    );
    await addFavorite(favorite);
    notifyListeners();
  }

  Future<bool> isFavorite(String contactId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'contactId = ?',
      whereArgs: [contactId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<String?> getContactPhone(String contactId) async {
    try {
      final contact = await FlutterContacts.getContact(contactId);
      return contact?.phones.firstOrNull?.number;
    } catch (e) {
      print("Error getting contact phone: $e");
      return null;
    }
  }
}