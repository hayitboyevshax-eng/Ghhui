package com.oldv2.pixcompact

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val channelName = "pixcompact/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToDownloads") {
                    val path = call.argument<String>("path")
                    val name = call.argument<String>("name")
                    val mime = call.argument<String>("mime") ?: "application/octet-stream"
                    if (path == null || name == null) {
                        result.error("ARGS", "path/name yo'q", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(saveToDownloads(path, name, mime))
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    /// Faylni "Download" jildiga ko'chiradi.
    /// Android 10+ : MediaStore (ruxsat shart emas). Android 9 va eski: to'g'ridan-to'g'ri nusxa.
    private fun saveToDownloads(path: String, name: String, mime: String): String {
        val src = File(path)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, name)
                put(MediaStore.Downloads.MIME_TYPE, mime)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw Exception("Fayl yaratilmadi")
            resolver.openOutputStream(uri)?.use { out ->
                FileInputStream(src).use { input -> input.copyTo(out) }
            } ?: throw Exception("Yozib bo'lmadi")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "Download/$name"
        } else {
            val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            dir.mkdirs()
            val dest = File(dir, name)
            src.copyTo(dest, overwrite = true)
            return dest.absolutePath
        }
    }
}
