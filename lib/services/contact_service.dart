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

  Future<List<app_models.Contact>> _getContactsFromFirebase(String userId) async {
    try {
      print("Fetching contacts from Firebase for user: $userId");
      final snapshot = await _firebaseService.getUserRef(userId)
          .child('contacts')
          .once();

      final data = snapshot.snapshot.value;
      if (data == null) {
        print("No contacts found in Firebase");
        return [];
      }

      final List<app_models.Contact> contacts = [];

      if (data is Map) {
        // Standard case: contacts stored as a map
        data.forEach((key, value) {
          if (value is Map) {
            contacts.add(app_models.Contact(
              identifier: key,
              displayName: value['displayName'],
              phones: (value['phones'] as List<dynamic>?)?.map((phone) =>
                  app_models.ContactPhone(
                    value: phone['value'],
                    label: phone['label'],
                  )).toList(),
              emails: (value['emails'] as List<dynamic>?)?.map((email) =>
                  app_models.ContactEmail(
                    value: email['value'],
                    label: email['label'],
                  )).toList(),
              avatar: value['avatar'],
              createdAt: value['createdAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(value['createdAt'])
                  : null,
              updatedAt: value['updatedAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(value['updatedAt'])
                  : null,
            ));
          }
        });
      } else if (data is List) {
        // Rare case: contacts stored as a list (shouldn't happen, but handle gracefully)
        for (var i = 0; i < data.length; i++) {
          final value = data[i];
          if (value is Map) {
            contacts.add(app_models.Contact(
              identifier: value['identifier'] ?? i.toString(),
              displayName: value['displayName'],
              phones: (value['phones'] as List<dynamic>?)?.map((phone) =>
                  app_models.ContactPhone(
                    value: phone['value'],
                    label: phone['label'],
                  )).toList(),
              emails: (value['emails'] as List<dynamic>?)?.map((email) =>
                  app_models.ContactEmail(
                    value: email['value'],
                    label: email['label'],
                  )).toList(),
              avatar: value['avatar'],
              createdAt: value['createdAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(value['createdAt'])
                  : null,
              updatedAt: value['updatedAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(value['updatedAt'])
                  : null,
            ));
          }
        }
      } else {
        print("Contacts data in Firebase is neither Map nor List.");
      }

      print("Successfully parsed ${contacts.length} contacts");
      return contacts;
    } catch (e) {
      print("Error getting contacts from Firebase: $e");
      return [];
    }
  }

  Future<List<app_models.Contact>> restoreContactsFromFirebase(String userId) async {
    try {
      // Get contacts from Firebase
      final cloudContacts = await _getContactsFromFirebase(userId);
      if (cloudContacts.isEmpty) {
        print("No contacts found in Firebase");
        return await getDeviceContacts();
      }

      // Get current device contacts
      final deviceContacts = await getDeviceContacts();
      
      // Find contacts that exist in cloud but not on device
      final newContacts = cloudContacts.where((cloudContact) {
        return !deviceContacts.any((deviceContact) => 
            _areContactsSame(deviceContact, cloudContact));
      }).toList();

      print("Found ${newContacts.length} new contacts to restore");

      // Write new contacts to device
      if (newContacts.isNotEmpty) {
        final success = await writeContactsToDevice(newContacts);
        if (!success) {
          print("Failed to write some contacts to device");
        }
      }

      // Return combined list of existing and new contacts
      return [...deviceContacts, ...newContacts];
    } catch (e) {
      print("Error restoring contacts: $e");
      return await getDeviceContacts(); // Fallback to device contacts
    }
  }


  Future<void> syncContacts(String userId) async {
    final deviceContacts = await getDeviceContacts();
    final cloudContacts = await restoreContactsFromFirebase(userId);
    final contactsToUpdate = deviceContacts.where((deviceContact) {
      return !cloudContacts.any((cloudContact) =>
          cloudContact.identifier == deviceContact.identifier);
    }).toList();

    if (contactsToUpdate.isNotEmpty) {
      await backupContactsToFirebase(userId, contactsToUpdate);
    }
  }
  
  Future<bool> writeContactsToDevice(List<app_models.Contact> contacts) async {
  try {
    // Request write permission specifically
    if (!await _requestContactsWritePermission()) {
      print("Contacts write permission denied");
      return false;
    }

    int successCount = 0;
    for (final contact in contacts) {
      try {
        print("Attempting to write contact: ${contact.displayName}");
        
        final newContact = fc.Contact()
          ..displayName = contact.displayName ?? 'No Name'
          ..name.first = contact.displayName ?? 'No Name'
          ..phones = contact.phones?.map((phone) => 
              fc.Phone(
                phone.value ?? '',
                label: _convertLabelStringToEnum(phone.label),
              )).toList() ?? []
          ..emails = contact.emails?.map((email) => 
              fc.Email(
                email.value ?? '',
                label: _convertEmailLabelStringToEnum(email.label),
              )).toList() ?? []
          ..photo = contact.avatar;

        await newContact.insert();
        successCount++;
        print("Successfully wrote contact: ${contact.displayName}");
      } catch (e) {
        print('Error writing contact ${contact.displayName}: $e');
      }
    }

    print("Successfully wrote $successCount out of ${contacts.length} contacts");
    return successCount > 0;
  } catch (e) {
    print('Error writing contacts to device: $e');
    return false;
  }
}

fc.PhoneLabel _convertLabelStringToEnum(String? label) {
  if (label == null) return fc.PhoneLabel.other;
  return fc.PhoneLabel.values.firstWhere(
    (e) => e.toString().split('.').last == label.toLowerCase(),
    orElse: () => fc.PhoneLabel.other,
  );
}

fc.EmailLabel _convertEmailLabelStringToEnum(String? label) {
  if (label == null) return fc.EmailLabel.other;
  return fc.EmailLabel.values.firstWhere(
    (e) => e.toString().split('.').last == label.toLowerCase(),
    orElse: () => fc.EmailLabel.other,
  );
}
  bool _areContactsSame(app_models.Contact a, app_models.Contact b) {
    // Compare by identifier if available
    if (a.identifier != null && b.identifier != null) {
      return a.identifier == b.identifier;
    }
    
    // Fallback to comparing by name and primary phone number
    final aPrimaryPhone = a.phones?.isNotEmpty == true ? a.phones?.first.value : null;
    final bPrimaryPhone = b.phones?.isNotEmpty == true ? b.phones?.first.value : null;
    
    return a.displayName == b.displayName && 
          aPrimaryPhone == bPrimaryPhone;
  }
  Future<bool> _requestContactsWritePermission() async {
    try {
      var status = await Permission.contacts.status;
      if (status.isGranted) return true;
      
      status = await Permission.contacts.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
      return status.isGranted;
    } catch (e) {
      print("Error requesting contacts permission: $e");
      return false;
    }
  }
}