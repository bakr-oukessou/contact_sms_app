import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sms_model.dart' as my_models;
import 'firebase_service.dart';

class SmsService extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final SmsQuery _query = SmsQuery();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

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
        address: null, // Get all messages
        count: 1000, // Increase message count
        sort: true, // Sort by date
      );
      
      print("Raw messages count: ${messages.length}");
      final List<my_models.SmsMessage> smsList = [];
      
      for (final msg in messages) {
        try {
          if (msg.body != null && msg.body!.isNotEmpty) {
            print("Processing message from: ${msg.address}");
            smsList.add(
              my_models.SmsMessage(
                id: msg.id?.toString() ?? DateTime.now().toString(),
                address: msg.address ?? 'Unknown',
                body: msg.body ?? '',
                date: msg.date ?? DateTime.now(),
                type: msg.kind?.index ?? 0,
                isRead: msg.read ?? false,
              ),
            );
          }
        } catch (e) {
          print("Error processing message: $e");
          continue;
        }
      }

      print("Successfully processed ${smsList.length} messages");
      return smsList;
    } catch (e) {
      print("Error getting SMS: $e");
      print("Stack trace: ${StackTrace.current}");
      return [];
    }
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

  Future<List<my_models.SmsMessage>> restoreSmsFromFirebase(String userId) async {
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
              id: msg['id'],
              address: address,
              body: msg['body'],
              date: msg['date'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(msg['date'])
                  : null,
              type: msg['type'],
              isRead: msg['isRead'],
            )));
      });

      return allMessages;
    } catch (e) {
      print("Error restoring SMS: $e");
      return [];
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
}