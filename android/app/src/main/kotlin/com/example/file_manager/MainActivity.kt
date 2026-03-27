// android/app/src/main/kotlin/com/example/file_manager/MainActivity.kt
package com.example.file_manager

import android.app.ActivityManager
import android.content.ComponentCallbacks2
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceFragmentActivity() {

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

                    "killBackgroundApps" -> {
                        // Heavy work off the UI thread; cannot force-stop foreground apps (OS policy).
                        Thread {
                            val count = killOtherAppsBackgroundProcesses()
                            Handler(Looper.getMainLooper()).post {
                                result.success(
                                    hashMapOf(
                                        "count" to count
                                    )
                                )
                            }
                        }.start()
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
        try {
            application.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW)
            application.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN)
        } catch (_: Exception) { }

        try {
            Runtime.getRuntime().gc()
            System.gc()
        } catch (_: Exception) { }
    }

    /**
     * Asks the system to kill background processes for other packages.
     * Does not and cannot close other apps that are on-screen (foreground) — Android forbids that for third-party apps.
     */
    private fun killOtherAppsBackgroundProcesses(): Int {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val pm = applicationContext.packageManager
        val myPkg = applicationContext.packageName

        @Suppress("DEPRECATION")
        val flags = PackageManager.GET_META_DATA
        val apps = try {
            pm.getInstalledApplications(flags)
        } catch (_: Exception) {
            emptyList()
        }

        var attempted = 0
        for (app in apps) {
            val pkg = app.packageName ?: continue
            if (pkg == myPkg) continue

            // Only third-party / non-system installs; avoids meddling with core system packages.
            val isSystem = (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            if (isSystem) continue

            try {
                am.killBackgroundProcesses(pkg)
                attempted++
            } catch (_: Exception) { }
        }
        return attempted
    }
}
