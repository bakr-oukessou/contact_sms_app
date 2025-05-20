import 'dart:typed_data';

class Favorite {
  final String id;
  final String contactId;
  final String name;
  final int callCount;
  final int smsCount;
  final DateTime lastInteraction;
  final DateTime createdAt;
  final Uint8List? avatar;

  Favorite({
    required this.id,
    required this.contactId,
    required this.name,
    required this.callCount,
    required this.smsCount,
    required this.lastInteraction,
    required this.createdAt,
    this.avatar,
  });

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'],
      contactId: map['contactId'],
      name: map['name'],
      callCount: map['callCount'],
      smsCount: map['smsCount'],
      lastInteraction: DateTime.fromMillisecondsSinceEpoch(map['lastInteraction']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      avatar: map['avatar'] != null 
          ? Uint8List.fromList(map['avatar'].cast<int>())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactId': contactId,
      'name': name,
      'callCount': callCount,
      'smsCount': smsCount,
      'lastInteraction': lastInteraction.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'avatar': avatar?.toList(),
    };
  }

  Favorite copyWith({
    String? id,
    String? contactId,
    String? name,
    int? callCount,
    int? smsCount,
    DateTime? lastInteraction,
    DateTime? createdAt,
    Uint8List? avatar,
  }) {
    return Favorite(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      name: name ?? this.name,
      callCount: callCount ?? this.callCount,
      smsCount: smsCount ?? this.smsCount,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      createdAt: createdAt ?? this.createdAt,
      avatar: avatar ?? this.avatar,
    );
  }
}

class FavoriteStats {
  final String contactId;
  final String name;
  final int totalInteractions;
  final double callPercentage;
  final DateTime lastInteraction;

  FavoriteStats({
    required this.contactId,
    required this.name,
    required this.totalInteractions,
    required this.callPercentage,
    required this.lastInteraction,
  });
}