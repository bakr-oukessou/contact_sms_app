package com.example.contact_sms_app

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    private val CHANNEL = "flutter/sms"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "getSmsMessages" -> {
                    if (checkSmsPermission()) {
                        result.success(getSmsMessages())
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                    }
                }
                "sendSms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    sendSms(phoneNumber, message, result)
                }
                "requestSmsPermissions" -> {
                    requestSmsPermission(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun getSmsMessages(): List<Map<String, Any?>> {
        // Implement SMS retrieval logic
        // This is a simplified example
        val messages = mutableListOf<Map<String, Any?>>()
        val uri = Uri.parse("content://sms/inbox")
        val cursor = contentResolver.query(uri, null, null, null, null)
        
        cursor?.use {
            while (it.moveToNext()) {
                messages.add(mapOf(
                    "id" to it.getString(it.getColumnIndexOrThrow("_id")),
                    "address" to it.getString(it.getColumnIndexOrThrow("address")),
                    "body" to it.getString(it.getColumnIndexOrThrow("body")),
                    "date" to it.getLong(it.getColumnIndexOrThrow("date")),
                    "type" to 1 // 1 for received, 2 for sent
                ))
            }
        }
        return messages
    }

    private fun sendSms(phoneNumber: String?, message: String?, result: Result) {
        try {
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            result.success(true)
        } catch (e: Exception) {
            result.error("SMS_FAILED", "Failed to send SMS", e.message)
        }
    }

    private fun requestSmsPermission(result: Result) {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.READ_SMS,
                Manifest.permission.SEND_SMS
            ),
            SMS_PERMISSION_CODE
        )
        // You'll need to handle the permission callback separately
        result.success(true)
    }

    companion object {
        private const val SMS_PERMISSION_CODE = 123
    }
}
