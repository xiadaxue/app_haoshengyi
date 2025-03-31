package com.example.flutter_application_1

import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VoiceMethodChannel(flutterEngine: FlutterEngine) {
    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.haoshengyi/voice_service")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceBrand" -> {
                    result.success(getDeviceBrand())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getDeviceBrand(): String {
        return Build.BRAND ?: ""
    }
} 