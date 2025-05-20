import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import '../models/sms_model.dart' as my_models;
import 'firebase_service.dart';

class SmsService extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Telephony telephony = Telephony.instance;

  Future<List<my_models.SmsMessage>> getDeviceSms() async {
    try {
      final List<my_models.SmsMessage> smsList = [];
      final List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE, SmsColumn.TYPE, SmsColumn.READ],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
      for (final msg in messages) {
        smsList.add(
          my_models.SmsMessage(
            id: msg.id?.toString() ?? '',
            address: msg.address,
            body: msg.body,
            date: msg.date != null ? DateTime.fromMillisecondsSinceEpoch(msg.date!) : null,
            type: msg.type?.index,
            isRead: msg.read == 1,
          ),
        );
      }
      return smsList;
    } catch (e) {
      print("Error getting SMS: $e");
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
}