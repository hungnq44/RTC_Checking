package com.example.rtc_checking

import android.Manifest
import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.*
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*

class LocationService : Service() {
    companion object {
        const val TAG = "LocationService"
        const val CHANNEL_ID = "location_service_channel"
        const val NOTIFICATION_ID = 2001
        const val ACTION_STOP = "com.example.rtc_checking.STOP_SERVICE"
        const val ACTION_DISMISS_ALARM = "com.example.rtc_checking.DISMISS_ALARM"
        const val ACTION_ENABLE_ALARM = "com.example.rtc_checking.ENABLE_ALARM"
        const val ACTION_DISABLE_ALARM = "com.example.rtc_checking.DISABLE_ALARM"

        const val EXTRA_TARGET_LAT = "target_lat"
        const val EXTRA_TARGET_LNG = "target_lng"
        const val EXTRA_TARGET_RADIUS = "target_radius"
        const val EXTRA_TARGET_TITLE = "target_title"
        const val EXTRA_ALARM_ENABLED = "alarm_enabled"

        const val METHOD_CHANNEL = "com.example.rtc_checking/location_service"
        
        const val BROADCAST_LOCATION_UPDATE = "com.example.rtc_checking.LOCATION_UPDATE"
        const val EXTRA_LAT = "lat"
        const val EXTRA_LNG = "lng"
        const val EXTRA_DISTANCE = "distance"
        const val EXTRA_IS_IN_ZONE = "is_in_zone"
        
        const val BROADCAST_ALARM_TRIGGERED = "com.example.rtc_checking.ALARM_TRIGGERED"
        const val BROADCAST_ALARM_DISMISSED = "com.example.rtc_checking.ALARM_DISMISSED"
        const val EXTRA_ALARM_TITLE = "alarm_title"
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private lateinit var notificationManager: NotificationManager
    private lateinit var vibrator: Vibrator
    private var mediaPlayer: MediaPlayer? = null
    private var isAlarmPlaying = false
    private var isAlarmDismissed = false
    private var isAlarmEnabled = true
    private var wasInZone = false
    private var isServiceRunning = false

    private var targetLat: Double = 0.0
    private var targetLng: Double = 0.0
    private var targetRadius: Float = 100f
    private var targetTitle: String = "Vị trí"

    private val binder = LocalBinder()

    inner class LocalBinder : Binder() {
        fun getService(): LocationService = this@LocationService
    }

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        createNotificationChannel()
        createAlarmChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_DISMISS_ALARM -> {
                dismissAlarm()
                return START_STICKY
            }
            ACTION_ENABLE_ALARM -> {
                isAlarmEnabled = true
                isAlarmDismissed = false
                Log.d(TAG, "Alarm enabled")
                return START_STICKY
            }
            ACTION_DISABLE_ALARM -> {
                isAlarmEnabled = false
                if (isAlarmPlaying) {
                    stopAlarm()
                }
                Log.d(TAG, "Alarm disabled")
                return START_STICKY
            }
        }

        targetLat = intent?.getDoubleExtra(EXTRA_TARGET_LAT, 0.0) ?: 0.0
        targetLng = intent?.getDoubleExtra(EXTRA_TARGET_LNG, 0.0) ?: 0.0
        targetRadius = intent?.getFloatExtra(EXTRA_TARGET_RADIUS, 100f) ?: 100f
        targetTitle = intent?.getStringExtra(EXTRA_TARGET_TITLE) ?: "Vị trí"
        isAlarmEnabled = intent?.getBooleanExtra(EXTRA_ALARM_ENABLED, true) ?: true

        startForegroundService()
        startLocationUpdates()
        isServiceRunning = true

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun onDestroy() {
        super.onDestroy()
        stopLocationUpdates()
        stopAlarm()
        isServiceRunning = false
        Log.d(TAG, "Service destroyed")
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "Task removed - stopping service")
        stopLocationUpdates()
        stopAlarm()
        isServiceRunning = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun startForegroundService() {
        val notification = createForegroundNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Dịch vụ vị trí",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Theo dõi vị trí nền"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createAlarmChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "alarm_channel",
                "Thông báo vị trí",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Thông báo khi đến vị trí"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 250, 500)
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createForegroundNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, LocationService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Đang theo dõi vị trí")
            .setContentText("Nhắn tin khi bạn đến $targetTitle")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_delete, "Dừng", stopPendingIntent)
            .build()
    }

    @SuppressLint("MissingPermission")
    private fun startLocationUpdates() {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            return
        }

        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 3000)
            .setMinUpdateIntervalMillis(1000)
            .setWaitForAccurateLocation(false)
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    handleLocationUpdate(location.latitude, location.longitude)
                }
            }
        }

        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper()
        )
    }

    private fun stopLocationUpdates() {
        if (::locationCallback.isInitialized) {
            fusedLocationClient.removeLocationUpdates(locationCallback)
        }
    }

    private fun handleLocationUpdate(latitude: Double, longitude: Double) {
        val distance = calculateDistance(latitude, longitude, targetLat, targetLng)
        val isInZone = distance <= targetRadius

        // Update foreground notification with distance
        updateForegroundNotification(distance)

        // Broadcast location update to Flutter
        broadcastLocationUpdate(latitude, longitude, distance, isInZone)

        // Check zone entry (only if alarm is enabled)
        if (isInZone && !wasInZone && !isAlarmDismissed && isAlarmEnabled) {
            // Just entered zone
            triggerAlarm()
        } else if (!isInZone && wasInZone) {
            // Just exited zone - reset dismissed flag so alarm can trigger again
            isAlarmDismissed = false
        }

        wasInZone = isInZone
    }

    private fun calculateDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Float {
        val results = FloatArray(1)
        Location.distanceBetween(lat1, lng1, lat2, lng2, results)
        return results[0]
    }

    private fun updateForegroundNotification(distance: Float) {
        val distanceText = if (distance < 1000) {
            "${distance.toInt()}m"
        } else {
            String.format("%.1fkm", distance / 1000)
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Đang theo dõi vị trí")
            .setContentText("$targetTitle - $distanceText")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun broadcastLocationUpdate(lat: Double, lng: Double, distance: Float, isInZone: Boolean) {
        val intent = Intent(BROADCAST_LOCATION_UPDATE).apply {
            putExtra(EXTRA_LAT, lat)
            putExtra(EXTRA_LNG, lng)
            putExtra(EXTRA_DISTANCE, distance)
            putExtra(EXTRA_IS_IN_ZONE, isInZone)
            setPackage(packageName)
        }
        sendBroadcast(intent)
    }

    private fun triggerAlarm() {
        isAlarmPlaying = true

        // Show alarm notification
        showAlarmNotification()

        // Play sound
        playAlarmSound()

        // Vibrate
        vibrate()

        // Broadcast alarm triggered
        broadcastAlarmTriggered()
    }

    private fun showAlarmNotification() {
        val stopIntent = Intent(this, LocationService::class.java).apply {
            action = ACTION_DISMISS_ALARM
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, "alarm_channel")
            .setContentTitle("Bạn đang ở $targetTitle")
            .setContentText("Nhấn DỪNG để tắt thông báo")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(android.R.drawable.ic_media_pause, "DỪNG", stopPendingIntent)
            .build()

        notificationManager.notify(NOTIFICATION_ID + 1, notification)
    }

    private fun playAlarmSound() {
        try {
            mediaPlayer?.release()
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@LocationService, alarmUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error playing alarm sound: ${e.message}")
        }
    }

    private fun vibrate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createWaveform(
                    longArrayOf(0, 500, 250, 500),
                    0
                )
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(longArrayOf(0, 500, 250, 500), 0)
        }
    }

    private fun dismissAlarm() {
        isAlarmDismissed = true
        stopAlarm()
        broadcastAlarmDismissed()
        // Update notification to show dismissed state
        updateForegroundNotification(0f)
    }

    private fun stopAlarm() {
        isAlarmPlaying = false

        // Stop sound
        mediaPlayer?.apply {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null

        // Stop vibration
        vibrator.cancel()

        // Cancel alarm notification
        notificationManager.cancel(NOTIFICATION_ID + 1)
    }

    private fun broadcastAlarmTriggered() {
        val intent = Intent(BROADCAST_ALARM_TRIGGERED).apply {
            putExtra(EXTRA_ALARM_TITLE, targetTitle)
            setPackage(packageName)
        }
        sendBroadcast(intent)
    }

    private fun broadcastAlarmDismissed() {
        val intent = Intent(BROADCAST_ALARM_DISMISSED).apply {
            setPackage(packageName)
        }
        sendBroadcast(intent)
    }

    fun updateTarget(lat: Double, lng: Double, radius: Float, title: String) {
        targetLat = lat
        targetLng = lng
        targetRadius = radius
        targetTitle = title
        isAlarmPlaying = false // Reset alarm when target changes
    }

    fun isAlarmActive(): Boolean = isAlarmPlaying

    fun isRunning(): Boolean = isServiceRunning
}
