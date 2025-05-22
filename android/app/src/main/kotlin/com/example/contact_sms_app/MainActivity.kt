package com.example.contact_sms_app

import android.content.ContentValues
import android.net.Uri
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.contact_sms_app/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "writeSms" -> {
                    try {
                        val address = call.argument<String>("address")
                        val body = call.argument<String>("body")
                        val date = call.argument<Long>("date")
                        val type = call.argument<Int>("type")
                        
                        val values = ContentValues().apply {
                            put(Telephony.Sms.ADDRESS, address)
                            put(Telephony.Sms.BODY, body)
                            put(Telephony.Sms.DATE, date)
                            put(Telephony.Sms.TYPE, type)
                            put(Telephony.Sms.READ, 1)
                            put(Telephony.Sms.SEEN, 1)
                        }

                        val uri = if (type == 1) {
                            Telephony.Sms.Inbox.CONTENT_URI
                        } else {
                            Telephony.Sms.Sent.CONTENT_URI
                        }
                        
                        val inserted = contentResolver.insert(uri, values)
                        result.success(inserted != null)
                    } catch (e: Exception) {
                        result.error("WRITE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
