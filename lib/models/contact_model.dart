import 'dart:typed_data';

class Contact {
  final String? identifier;
  final String? displayName;
  final List<ContactPhone>? phones;
  final List<ContactEmail>? emails;
  final Uint8List? avatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Contact({
    this.identifier,
    this.displayName,
    this.phones,
    this.emails,
    this.avatar,
    this.createdAt,
    this.updatedAt,
  });

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      identifier: map['identifier'],
      displayName: map['displayName'],
      phones: map['phones'] != null 
          ? List<ContactPhone>.from(
              map['phones'].map((x) => ContactPhone.fromMap(x)))
          : null,
      emails: map['emails'] != null
          ? List<ContactEmail>.from(
              map['emails'].map((x) => ContactEmail.fromMap(x)))
          : null,
      avatar: map['avatar'] != null 
          ? Uint8List.fromList(map['avatar'].cast<int>())
          : null,
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'identifier': identifier,
      'displayName': displayName,
      'phones': phones?.map((x) => x.toMap()).toList(),
      'emails': emails?.map((x) => x.toMap()).toList(),
      'avatar': avatar?.toList(),
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  Contact copyWith({
    String? identifier,
    String? displayName,
    List<ContactPhone>? phones,
    List<ContactEmail>? emails,
    Uint8List? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      identifier: identifier ?? this.identifier,
      displayName: displayName ?? this.displayName,
      phones: phones ?? this.phones,
      emails: emails ?? this.emails,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ContactPhone {
  final String? value;
  final String? label;

  ContactPhone({this.value, this.label});

  factory ContactPhone.fromMap(Map<String, dynamic> map) {
    return ContactPhone(
      value: map['value'],
      label: map['label'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'label': label,
    };
  }
}

class ContactEmail {
  final String? value;
  final String? label;

  ContactEmail({this.value, this.label});

  factory ContactEmail.fromMap(Map<String, dynamic> map) {
    return ContactEmail(
      value: map['value'],
      label: map['label'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'label': label,
    };
  }
}