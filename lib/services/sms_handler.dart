import 'package:contact_sms_app/models/sms_model.dart';
import 'package:flutter/services.dart';

abstract class SmsHandler {
  Future<List<SmsMessage>> getSmsMessages();
  Future<bool> sendSms(String phoneNumber, String message);
  Future<bool> requestSmsPermissions();
}

class SmsHandlerImpl extends SmsHandler {
  static const platform = MethodChannel('your_channel_name/sms');

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
}