// android/app/src/main/kotlin/com/example/file_manager/MainActivity.kt
package com.example.file_manager

import android.app.ActivityManager
import android.content.Context
import android.content.ComponentCallbacks2
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "ram_cleaner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRam" -> {
                        try {
                            val snap = getRamSnapshot()
                            result.success(
                                hashMapOf(
                                    "totalBytes" to snap.first,
                                    "freeBytes" to snap.second
                                )
                            )
                        } catch (e: Exception) {
                            result.error("RAM_ERROR", e.message, null)
                        }
                    }

                    "trimMemory" -> {
                        val ok = try {
                            trimMemoryBestEffort()
                            true
                        } catch (_: Exception) {
                            false
                        }
                        result.success(ok)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun getRamSnapshot(): Pair<Long, Long> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mi = ActivityManager.MemoryInfo()
        am.getMemoryInfo(mi)

        val freeBytes = mi.availMem
        val totalBytes: Long =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) mi.totalMem
            else Runtime.getRuntime().maxMemory()

        return Pair(totalBytes, freeBytes)
    }

    private fun trimMemoryBestEffort() {
        // ✅ correct API: Application implements ComponentCallbacks2
        try {
            application.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW)
            application.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN)
        } catch (_: Exception) { }

        // ✅ GC best effort
        try {
            Runtime.getRuntime().gc()
            System.gc()
        } catch (_: Exception) { }
    }
}
