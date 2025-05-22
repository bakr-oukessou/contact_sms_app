import 'package:contact_sms_app/models/sms_model.dart';
import 'package:flutter/services.dart';

abstract class SmsHandler {
  Future<List<SmsMessage>> getSmsMessages();
  Future<bool> sendSms(String phoneNumber, String message);
  Future<bool> requestSmsPermissions();
}

class SmsHandlerImpl extends SmsHandler {
  static const platform = MethodChannel('contacts/sms');

  @override
  Future<List<SmsMessage>> getSmsMessages() async {
    try {
      final result = await platform.invokeMethod('getSmsMessages');
      return (result as List).map((e) => SmsMessage.fromMap(e)).toList();
    } on PlatformException catch (e) {
      print("Failed to get SMS: ${e.message}");
      return [];
    }
  }

  @override
  Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      return await platform.invokeMethod(
        'sendSms',
        {'phoneNumber': phoneNumber, 'message': message},
      );
    } on PlatformException catch (e) {
      print("Failed to send SMS: ${e.message}");
      return false;
    }
  }

  @override
  Future<bool> requestSmsPermissions() async {
    try {
      return await platform.invokeMethod('requestSmsPermissions');
    } on PlatformException catch (e) {
      print("Failed to request permissions: ${e.message}");
      return false;
    }
  }

  static Future<bool> writeSmsToDevice({
    required String address,
    required String body,
    required int date,
    required bool isRead,
  }) async {
    try {
      await platform.invokeMethod('writeSms', {
        'address': address,
        'body': body,
        'date': date,
        'isRead': isRead,
      });
      return true;
    } on PlatformException catch (e) {
      print("Failed to write SMS: ${e.message}");
      return false;
    }
  }

  static Future<bool> deleteSmsFromDevice(String id) async {
    try {
      await platform.invokeMethod('deleteSms', {'id': id});
      return true;
    } on PlatformException catch (e) {
      print("Failed to delete SMS: ${e.message}");
      return false;
    }
  }
}