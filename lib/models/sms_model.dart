class SmsMessage {
  final String? id;
  final String? address;
  final String? body;
  final DateTime? date;
  final int? type; // 1 for received, 2 for sent
  final bool? isRead;

  SmsMessage({
    this.id,
    this.address,
    this.body,
    this.date,
    this.type,
    this.isRead,
  });

  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      id: map['id'],
      address: map['address'],
      body: map['body'],
      date: map['date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['date'])
          : null,
      type: map['type'],
      isRead: map['isRead'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'body': body,
      'date': date?.millisecondsSinceEpoch,
      'type': type,
      'isRead': isRead,
    };
  }

  SmsMessage copyWith({
    String? id,
    String? address,
    String? body,
    DateTime? date,
    int? type,
    bool? isRead,
  }) {
    return SmsMessage(
      id: id ?? this.id,
      address: address ?? this.address,
      body: body ?? this.body,
      date: date ?? this.date,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}

class SmsConversation {
  final String contact;
  final List<SmsMessage> messages;
  final DateTime lastUpdated;

  SmsConversation({
    required this.contact,
    required this.messages,
    required this.lastUpdated,
  });

  factory SmsConversation.fromMap(Map<String, dynamic> map) {
    return SmsConversation(
      contact: map['contact'],
      messages: List<SmsMessage>.from(
          map['messages'].map((x) => SmsMessage.fromMap(x))),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contact': contact,
      'messages': messages.map((x) => x.toMap()).toList(),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }
}