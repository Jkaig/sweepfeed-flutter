package com.sweepfeed.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
// import com.google.firebase.messaging.FirebaseMessaging
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL_FCM_TOKEN = "sweepfeed/fcm_token"
    private val CHANNEL_NOTIFICATION_TAP = "sweepfeed/notification_tap"
    private val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle notification tap when app is opened from notification
        handleNotificationIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up FCM token channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_FCM_TOKEN).setMethodCallHandler { call, result ->
            when (call.method) {
                "getToken" -> {
                    // FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                    //     if (!task.isSuccessful) {
                    //         Log.w(TAG, "Fetching FCM registration token failed", task.exception)
                    //         result.error("TOKEN_ERROR", "Failed to get FCM token", null)
                    //         return@addOnCompleteListener
                    //     }
                        
                    //     val token = task.result
                    //     Log.d(TAG, "FCM Registration Token: $token")
                    //     result.success(token)
                    // }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set up notification tap channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NOTIFICATION_TAP).setMethodCallHandler { call, result ->
            when (call.method) {
                "handleTap" -> {
                    // Handle notification tap data
                    val data = call.arguments as? Map<*, *>
                    Log.d(TAG, "Notification tapped with data: $data")
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun handleNotificationIntent(intent: android.content.Intent?) {
        intent?.extras?.let { extras ->
            if (extras.containsKey("notification_tap")) {
                val data = extras.getSerializable("notification_data") as? Map<*, *>
                Log.d(TAG, "App opened from notification: $data")
                
                // Forward to Flutter if engine is ready
                flutterEngine?.dartExecutor?.let { executor ->
                    MethodChannel(executor.binaryMessenger, CHANNEL_NOTIFICATION_TAP)
                        .invokeMethod("onNotificationTap", data)
                }
            }
        }
    }
}