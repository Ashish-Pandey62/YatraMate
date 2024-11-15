package com.example.conductor_app

import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.content.Context
import android.app.AlarmManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.conductor_app/permission"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up one method channel to handle all methods
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestScheduleExactAlarm" -> {
                    // Request permission for exact alarm scheduling (Android S+)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                        startActivity(intent)
                        result.success(null)  // Send success result back to Flutter
                    } else {
                        result.success(null)  // No permission needed for lower versions
                    }
                }
                "checkScheduleExactAlarmPermission" -> {
                    // Handle checking the permission
                    result.success(hasScheduleExactAlarmPermission())  // Return true/false based on the permission check
                }
                "openLocationSettings" -> {
                    openLocationSettings()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()  // Handle other method calls
                }
            }
        }
    }

    private fun hasScheduleExactAlarmPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.canScheduleExactAlarms()
        } else {
            // Permission not needed for devices below Android 12
            true
        }
    }

    private fun openLocationSettings() {
        val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
        startActivity(intent)
    }
}
