import 'package:contacts_service/contacts_service.dart' as device_contacts;
import 'package:flutter/widgets.dart';
import '../models/contact_model.dart' as app_models;
import 'firebase_service.dart';
import 'package:firebase_database/firebase_database.dart';

class ContactService extends ChangeNotifier{
  final FirebaseService _firebaseService = FirebaseService();

  Future<List<app_models.Contact>> getDeviceContacts() async {
    try {
      final Iterable<device_contacts.Contact> contacts = await device_contacts.ContactsService.getContacts();
      return contacts.map((contact) => app_models.Contact(
        identifier: contact.identifier,
        displayName: contact.displayName,
        phones: contact.phones?.map((phone) => 
          app_models.ContactPhone(value: phone.value, label: phone.label)).toList(),
        emails: contact.emails?.map((email) => 
          app_models.ContactEmail(value: email.value, label: email.label)).toList(),
        avatar: contact.avatar,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();
    } catch (e) {
      print("Error getting contacts: $e");
      return [];
    }
  }

  Future<void> backupContactsToFirebase(
    String userId, 
    List<app_models.Contact> contacts,
  ) async {
    try {
      final contactsRef = _firebaseService.getUserRef(userId).child('contacts');
      
      for (final contact in contacts) {
        await contactsRef.child(contact.identifier!).set({
          'displayName': contact.displayName,
          'phones': contact.phones?.map((phone) => {
            'value': phone.value,
            'label': phone.label,
          }).toList(),
          'emails': contact.emails?.map((email) => {
            'value': email.value,
            'label': email.label,
          }).toList(),
          'avatar': contact.avatar,
          'createdAt': contact.createdAt?.millisecondsSinceEpoch,
          'updatedAt': ServerValue.timestamp,
        });
      }
    } catch (e) {
      print("Error backing up contacts: $e");
      rethrow;
    }
  }

  Future<List<app_models.Contact>> restoreContactsFromFirebase(String userId) async {
    try {
      final snapshot = await _firebaseService.getUserRef(userId)
          .child('contacts')
          .once();
      
      final Map<dynamic, dynamic>? contactsMap = 
          snapshot.snapshot.value as Map<dynamic, dynamic>?;
      
      if (contactsMap == null) return [];
      
      return contactsMap.entries.map((entry) {
        final data = entry.value as Map<dynamic, dynamic>;
        return app_models.Contact(
          identifier: entry.key,
          displayName: data['displayName'],
          phones: (data['phones'] as List<dynamic>?)?.map((phone) => 
            app_models.ContactPhone(
              value: phone['value'],
              label: phone['label'],
            )).toList(),
          emails: (data['emails'] as List<dynamic>?)?.map((email) => 
            app_models.ContactEmail(
              value: email['value'],
              label: email['label'],
            )).toList(),
          avatar: data['avatar'],
          createdAt: data['createdAt'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
              : null,
          updatedAt: data['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
              : null,
        );
      }).toList();
    } catch (e) {
      print("Error restoring contacts: $e");
      return [];
    }
  }

  Future<void> syncContacts(String userId) async {
    final deviceContacts = await getDeviceContacts();
    final cloudContacts = await restoreContactsFromFirebase(userId);
    
    // Implement your sync logic here (compare and merge contacts)
    // This is a basic example - you'll need to enhance it
    final contactsToUpdate = deviceContacts.where((deviceContact) {
      return !cloudContacts.any((cloudContact) => 
          cloudContact.identifier == deviceContact.identifier);
    }).toList();
    
    if (contactsToUpdate.isNotEmpty) {
      await backupContactsToFirebase(userId, contactsToUpdate);
    }
  }
}