package com.example.ar_ai_smart_study

import android.graphics.BitmapFactory
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "ar_smart_study/ocr"
    private val tessLanguages = "kaz+rus+eng"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "recognizeCyrillicText" -> {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath.isNullOrBlank()) {
                        result.error("INVALID_IMAGE", "imagePath is required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        result.success(recognizeText(imagePath))
                    } catch (error: Exception) {
                        result.error("OCR_FAILED", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun recognizeText(imagePath: String): String {
        val tessDir = prepareTessData()
        val bitmap = BitmapFactory.decodeFile(imagePath)
            ?: throw IllegalArgumentException("Cannot decode image")

        val tessBaseApi = TessBaseAPI()
        return try {
            if (!tessBaseApi.init(tessDir.absolutePath, tessLanguages)) {
                throw IllegalStateException("Cannot initialize OCR engine")
            }

            tessBaseApi.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO)
            tessBaseApi.setVariable(TessBaseAPI.VAR_CHAR_BLACKLIST, "|")
            tessBaseApi.setImage(bitmap)
            tessBaseApi.utF8Text.orEmpty().trim()
        } finally {
            tessBaseApi.recycle()
        }
    }

    private fun prepareTessData(): File {
        val appTessDir = File(filesDir, "tesseract")
        val tessDataDir = File(appTessDir, "tessdata")
        if (!tessDataDir.exists()) {
            tessDataDir.mkdirs()
        }

        listOf("kaz.traineddata", "rus.traineddata", "eng.traineddata").forEach { fileName ->
            val target = File(tessDataDir, fileName)
            if (!target.exists() || target.length() == 0L) {
                assets.open("flutter_assets/assets/tessdata/$fileName").use { input ->
                    FileOutputStream(target).use { output ->
                        input.copyTo(output)
                    }
                }
            }
        }

        return appTessDir
    }
}
