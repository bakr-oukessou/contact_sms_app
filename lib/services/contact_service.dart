import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter/widgets.dart';
import '../models/contact_model.dart' as app_models;
import 'firebase_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<bool> _requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<List<app_models.Contact>> getDeviceContacts() async {
    try {
      // Request permission if not already granted
      if (!await _requestContactsPermission()) {
        print("Permission denied to read contacts");
        return [];
      }
      final List<fc.Contact> contacts = await fc.FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      return contacts
          .map((contact) => app_models.Contact(
                identifier: contact.id,
                displayName: contact.displayName,
                phones: contact.phones.isNotEmpty
                    ? contact.phones
                        .map((phone) => app_models.ContactPhone(
                              value: phone.number,
                              label: phone.label.name ?? phone.label.toString(),
                            ))
                        .toList()
                    : [],
                emails: contact.emails.isNotEmpty
                    ? contact.emails
                        .map((email) => app_models.ContactEmail(
                              value: email.address,
                              label: email.label.name ?? email.label.toString(),
                            ))
                        .toList()
                    : [],
                avatar: contact.photo,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ))
          .toList();
    } catch (e) {
      print("Error getting contacts: $e");
      return [];
    }
  }

  Future<void> initializeUserData(String userId) async {
    try {
      // Check if contacts data exists
      final snapshot = await _dbRef.child('users/$userId/contacts').once();
      if (snapshot.snapshot.value == null) {
        // Get device contacts
        final deviceContacts = await getDeviceContacts();
        if (deviceContacts.isNotEmpty) {
          // Initialize with device contacts
          await backupContactsToFirebase(userId, deviceContacts);
        } else {
          // Initialize with empty structure
          await _dbRef.child('users/$userId').update({
            'contacts': {},
          });
        }
      }
    } catch (e) {
      print("Error initializing contacts data: $e");
      rethrow;
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
    final contactsToUpdate = deviceContacts.where((deviceContact) {
      return !cloudContacts.any((cloudContact) =>
          cloudContact.identifier == deviceContact.identifier);
    }).toList();

    if (contactsToUpdate.isNotEmpty) {
      await backupContactsToFirebase(userId, contactsToUpdate);
    }
  }
}