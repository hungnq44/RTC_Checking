package com.example.rtc_checking

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val TAG = "MainActivity"
        const val METHOD_CHANNEL = "com.example.rtc_checking/location_service"
        const val EVENT_CHANNEL = "com.example.rtc_checking/location_service/events"

        const val BROADCAST_LOCATION_UPDATE = "com.example.rtc_checking.LOCATION_UPDATE"
        const val BROADCAST_ALARM_TRIGGERED = "com.example.rtc_checking.ALARM_TRIGGERED"
        const val BROADCAST_ALARM_DISMISSED = "com.example.rtc_checking.ALARM_DISMISSED"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var serviceIntent: Intent? = null

    private val locationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                BROADCAST_LOCATION_UPDATE -> {
                    val lat = intent.getDoubleExtra("lat", 0.0)
                    val lng = intent.getDoubleExtra("lng", 0.0)
                    val distance = intent.getFloatExtra("distance", 0f)
                    val isInZone = intent.getBooleanExtra("isInZone", false)

                    val data = mapOf(
                        "type" to "location",
                        "lat" to lat,
                        "lng" to lng,
                        "distance" to distance,
                        "isInZone" to isInZone
                    )
                    runOnUiThread {
                        eventSink?.success(data)
                    }
                    Log.d(TAG, "Location update: lat=$lat, lng=$lng, distance=$distance, isInZone=$isInZone")
                }

                BROADCAST_ALARM_TRIGGERED -> {
                    val title = intent.getStringExtra("alarm_title") ?: "Vị trí"
                    val data = mapOf("type" to "alarm", "title" to title)
                    runOnUiThread {
                        eventSink?.success(data)
                    }
                    Log.d(TAG, "Alarm triggered: $title")
                }

                BROADCAST_ALARM_DISMISSED -> {
                    val data = mapOf("type" to "dismissed")
                    runOnUiThread {
                        eventSink?.success(data)
                    }
                    Log.d(TAG, "Alarm dismissed")
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel for commands
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val targetLat = call.argument<Double>("targetLat") ?: 0.0
                    val targetLng = call.argument<Double>("targetLng") ?: 0.0
                    val radius = call.argument<Double>("radius")?.toFloat() ?: 100f
                    val title = call.argument<String>("title") ?: "Vị trí"
                    val notificationEnabled = call.argument<Boolean>("notificationEnabled") ?: true

                    serviceIntent = Intent(this, LocationService::class.java).apply {
                        putExtra(LocationService.EXTRA_TARGET_LAT, targetLat)
                        putExtra(LocationService.EXTRA_TARGET_LNG, targetLng)
                        putExtra(LocationService.EXTRA_TARGET_RADIUS, radius)
                        putExtra(LocationService.EXTRA_TARGET_TITLE, title)
                        putExtra(LocationService.EXTRA_ALARM_ENABLED, notificationEnabled)
                    }
                    startForegroundService(serviceIntent!!)
                    result.success(true)
                    Log.d(TAG, "Service started: lat=$targetLat, lng=$targetLng, radius=$radius, title=$title, alarmEnabled=$notificationEnabled")
                }

                "stopService" -> {
                    serviceIntent?.let { stopService(it) }
                    serviceIntent = null
                    result.success(true)
                    Log.d(TAG, "Service stopped")
                }

                "updateTarget" -> {
                    val targetLat = call.argument<Double>("targetLat") ?: 0.0
                    val targetLng = call.argument<Double>("targetLng") ?: 0.0
                    val radius = call.argument<Double>("radius")?.toFloat() ?: 100f
                    val title = call.argument<String>("title") ?: "Vị trí"

                    serviceIntent?.let {
                        it.putExtra(LocationService.EXTRA_TARGET_LAT, targetLat)
                        it.putExtra(LocationService.EXTRA_TARGET_LNG, targetLng)
                        it.putExtra(LocationService.EXTRA_TARGET_RADIUS, radius)
                        it.putExtra(LocationService.EXTRA_TARGET_TITLE, title)
                        // Restart service with new target
                        stopService(it)
                        startForegroundService(it)
                    }
                    result.success(true)
                    Log.d(TAG, "Target updated: lat=$targetLat, lng=$targetLng, radius=$radius, title=$title")
                }

                "dismissAlarm" -> {
                    serviceIntent?.let {
                        val dismissIntent = Intent(this, LocationService::class.java).apply {
                            action = LocationService.ACTION_DISMISS_ALARM
                        }
                        startService(dismissIntent)
                    }
                    result.success(true)
                    Log.d(TAG, "Alarm dismissed via method channel")
                }

                "enableAlarm" -> {
                    serviceIntent?.let {
                        val enableIntent = Intent(this, LocationService::class.java).apply {
                            action = LocationService.ACTION_ENABLE_ALARM
                        }
                        startService(enableIntent)
                    }
                    result.success(true)
                    Log.d(TAG, "Alarm enabled via method channel")
                }

                "disableAlarm" -> {
                    serviceIntent?.let {
                        val disableIntent = Intent(this, LocationService::class.java).apply {
                            action = LocationService.ACTION_DISABLE_ALARM
                        }
                        startService(disableIntent)
                    }
                    result.success(true)
                    Log.d(TAG, "Alarm disabled via method channel")
                }

                "isAlarmActive" -> {
                    val locationService = LocationServiceHelper.getInstance()
                    result.success(locationService?.isAlarmActive() ?: false)
                }

                "isServiceRunning" -> {
                    val locationService = LocationServiceHelper.getInstance()
                    result.success(locationService?.isRunning() ?: false)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        // Event Channel for streaming data
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerReceiver()
                    Log.d(TAG, "EventChannel listener attached")
                }

                override fun onCancel(arguments: Any?) {
                    try {
                        unregisterReceiver(locationReceiver)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error unregistering receiver: ${e.message}")
                    }
                    eventSink = null
                    Log.d(TAG, "EventChannel listener cancelled")
                }
            }
        )
    }

    private fun registerReceiver() {
        val filter = IntentFilter().apply {
            addAction(BROADCAST_LOCATION_UPDATE)
            addAction(BROADCAST_ALARM_TRIGGERED)
            addAction(BROADCAST_ALARM_DISMISSED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(locationReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(locationReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(locationReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver: ${e.message}")
        }
    }
}

object LocationServiceHelper {
    @Volatile
    private var instance: LocationService? = null

    fun getInstance(): LocationService? = instance
}
