import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../models/sms_model.dart' as my_models;
import 'firebase_service.dart';
import 'package:flutter/services.dart';

class SmsService extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final SmsQuery _query = SmsQuery();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  List<my_models.SmsMessage> _cachedMessages = [];

  // ignore: unused_element
  Future<bool> _requestSmsPermission() async {
    try {
      // Check if permission is already granted
      var status = await Permission.sms.status;
      if (status.isGranted) return true;

      // Request SMS permission
      status = await Permission.sms.request();
      if (status.isPermanentlyDenied) {
        // Permission is permanently denied, take user to app settings
        return false;
      }

      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print("Error requesting SMS permission: $e");
      }
      return false;
    }
  }

  // Add a getter for cached messages
  List<my_models.SmsMessage> get messages => List.unmodifiable(_cachedMessages);

  Future<List<my_models.SmsMessage>> restoreSmsFromFirebase(String userId) async {
    try {
      // First get messages from Firebase
      final messages = await _getMessagesFromFirebase(userId);
      print("Retrieved ${messages.length} messages from Firebase");

      if (messages.isEmpty) {
        print("No messages found in Firebase");
        return [];
      }

      // Write messages to device in batches
      const batchSize = 10;
      for (var i = 0; i < messages.length; i += batchSize) {
        final end = (i + batchSize < messages.length) ? i + batchSize : messages.length;
        final batch = messages.sublist(i, end);
        
        await Future.delayed(const Duration(milliseconds: 500)); // Add delay between batches
        final success = await writeSmsToDevice(batch);
        print("Wrote batch ${i ~/ batchSize + 1}: $success");
      }

      // Update cache with all messages
      _cachedMessages = messages;
      notifyListeners();

      // Verify messages were written by reading from device
      await Future.delayed(const Duration(seconds: 1));
      final deviceMessages = await getDeviceSms();
      print("Found ${deviceMessages.length} messages on device after restore");

      return messages;
    } catch (e) {
      print("Error restoring SMS: $e");
      return [];
    }
  }

  Future<List<my_models.SmsMessage>> getDeviceSms() async {
    try {
      print("Starting SMS fetch...");
      
      // Request both SMS and phone permissions
      var smsPermission = await Permission.sms.status;
      if (!smsPermission.isGranted) {
        smsPermission = await Permission.sms.request();
        if (!smsPermission.isGranted) {
          print("SMS permission not granted");
          return [];
        }
      }

      print("Fetching SMS messages...");
      final List<SmsMessage> messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox, SmsQueryKind.sent],
        count: 1000,
        sort: true,
      );

      final List<my_models.SmsMessage> smsList = [];
      for (final msg in messages) {
        if (msg.body?.isNotEmpty ?? false) {
          smsList.add(_convertToAppMessage(msg));
        }
      }

      // Update cache
      _cachedMessages = List.from(smsList);
      notifyListeners();

      return smsList;
    } catch (e) {
      print("Error getting SMS: $e");
      print("Stack trace: ${StackTrace.current}");
      return [];
    }
  }

  my_models.SmsMessage _convertToAppMessage(SmsMessage msg) {
    return my_models.SmsMessage(
      id: msg.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      address: msg.address ?? 'Unknown',
      body: msg.body ?? '',
      date: msg.date ?? DateTime.now(),
      type: msg.kind?.index ?? 0,
      isRead: msg.read ?? false,
    );
  }

  Future<void> backupSmsToFirebase(
    String userId,
    List<my_models.SmsMessage> smsList,
  ) async {
    try {
      // Group SMS by contact
      final Map<String, List<my_models.SmsMessage>> smsByContact = {};

      for (final sms in smsList) {
        final address = sms.address ?? 'unknown';
        if (!smsByContact.containsKey(address)) {
          smsByContact[address] = [];
        }
        smsByContact[address]!.add(sms);
      }

      // Backup to Firebase
      final smsRef = _firebaseService.getUserRef(userId).child('sms');

      for (final entry in smsByContact.entries) {
        await smsRef.child(entry.key).set({
          'messages': entry.value.map((sms) => {
                'id': sms.id,
                'body': sms.body,
                'date': sms.date?.millisecondsSinceEpoch,
                'type': sms.type,
                'isRead': sms.isRead,
              }).toList(),
          'lastUpdated': ServerValue.timestamp,
        });
      }
    } catch (e) {
      print("Error backing up SMS: $e");
      rethrow;
    }
  }

  Future<void> syncSms(String userId) async {
    final deviceSms = await getDeviceSms();
    final cloudSms = await restoreSmsFromFirebase(userId);

    // Implement your sync logic here (compare dates to find new/updated SMS)
    final newSms = deviceSms.where((deviceMsg) {
      return !cloudSms.any((cloudMsg) =>
          cloudMsg.id == deviceMsg.id &&
          cloudMsg.date == deviceMsg.date);
    }).toList();

    if (newSms.isNotEmpty) {
      await backupSmsToFirebase(userId, newSms);
    }
  }

  Future<void> initializeUserData(String userId) async {
    try {
      // Check if SMS data exists
      final snapshot = await _dbRef.child('users/$userId/sms').once();
      if (snapshot.snapshot.value == null) {
        // Get device SMS
        final deviceSms = await getDeviceSms();
        if (deviceSms.isNotEmpty) {
          // Initialize with device SMS
          await backupSmsToFirebase(userId, deviceSms);
        }
      }
    } catch (e) {
      print("Error initializing SMS data: $e");
      rethrow;
    }
  }

  Future<Map<String, String>> getContactNames(Set<String> phoneNumbers) async {
    try {
      final contacts = await fc.FlutterContacts.getContacts(
        withProperties: true,
      );
      
      final Map<String, String> result = {};
      for (final number in phoneNumbers) {
        final contact = contacts.firstWhere(
          (c) => c.phones.any((p) => _normalizePhone(p.number) == _normalizePhone(number)),
          orElse: () => fc.Contact(phones: []),
        );
        result[number] = contact.displayName.isNotEmpty ? contact.displayName : number;
      }
      return result;
    } catch (e) {
      print('Error getting contact names: $e');
      return {};
    }
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }
  Future<bool> writeSmsToDevice(List<my_models.SmsMessage> messages) async {
    const platform = MethodChannel('com.example.contact_sms_app/sms');
    var successCount = 0;
    
    for (final msg in messages) {
      try {
        final result = await platform.invokeMethod('writeSms', {
          'address': msg.address,
          'body': msg.body,
          'date': msg.date?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
          'type': msg.type == 1 ? 1 : 2,
          'thread_id': 0,
          'read': 1,
          'seen': 1,
        });
        
        if (result == true) {
          successCount++;
        }
      } catch (e) {
        print('Error writing message: $e');
      }
    }

    print('Successfully wrote $successCount out of ${messages.length} messages');
    return successCount == messages.length;
  }

  Future<void> syncWithDevice() async {
    try {
      final deviceMessages = await getDeviceSms();
      _cachedMessages = deviceMessages;
      notifyListeners();
    } catch (e) {
      print('Error syncing with device: $e');
    }
  }

  Future<void> deleteFromDevice(String messageId) async {
    try {
      const platform = MethodChannel('com.example.contact_sms_app/sms');
      await platform.invokeMethod('deleteSms', {'id': messageId});
      await syncWithDevice();
    } catch (e) {
      print('Error deleting SMS from device: $e');
    }
  }

  Future<List<my_models.SmsMessage>> _getMessagesFromFirebase(String userId) async {
    try {
      final snapshot = await _firebaseService.getUserRef(userId)
          .child('sms')
          .once();

      final Map<dynamic, dynamic>? smsMap =
          snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (smsMap == null) return [];

      final List<my_models.SmsMessage> allMessages = [];

      smsMap.forEach((address, data) {
        final messages = (data['messages'] as List<dynamic>?) ?? [];
        allMessages.addAll(messages.map((msg) => my_models.SmsMessage(
              id: msg['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              address: address,
              body: msg['body'],
              date: msg['date'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(msg['date'])
                  : DateTime.now(),
              type: msg['type'] ?? 1,
              isRead: msg['isRead'] ?? true,
            )));
      });

      // Sort by date descending
      allMessages.sort((a, b) => b.date!.compareTo(a.date!));
      
      return allMessages;
    } catch (e) {
      print("Error getting messages from Firebase: $e");
      return [];
    }
  }
}