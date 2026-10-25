package com.cathan.kalasag

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "kalasag/emergency_tools"
    private val cameraPermissionRequest = 4201
    private var pendingTorchResult: MethodChannel.Result? = null
    private var torchOn = false
    private var torchCameraId: String? = null
    private var whistleOn = false
    private var toneGenerator: ToneGenerator? = null
    private val handler = Handler(Looper.getMainLooper())
    private val whistlePulse = object : Runnable {
        override fun run() {
            if (!whistleOn) return
            toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 550)
            handler.postDelayed(this, 850)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "toggleTorch" -> toggleTorch(result)
                "toggleWhistle" -> toggleWhistle(result)
                "stopAll" -> {
                    stopAllTools()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun toggleTorch(result: MethodChannel.Result) {
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)) {
            result.error("NO_FLASH", "This device does not have a flashlight.", null)
            return
        }
        if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            pendingTorchResult = result
            requestPermissions(arrayOf(Manifest.permission.CAMERA), cameraPermissionRequest)
            return
        }
        try {
            val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = torchCameraId ?: manager.cameraIdList.firstOrNull { id ->
                val details = manager.getCameraCharacteristics(id)
                details.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true &&
                    details.get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_BACK
            }
            if (cameraId == null) {
                result.error("NO_FLASH", "No usable rear flashlight was found.", null)
                return
            }
            torchCameraId = cameraId
            torchOn = !torchOn
            manager.setTorchMode(cameraId, torchOn)
            result.success(null)
        } catch (exception: Exception) {
            torchOn = false
            result.error("TORCH_ERROR", "The flashlight could not be changed.", exception.message)
        }
    }

    private fun toggleWhistle(result: MethodChannel.Result) {
        try {
            if (whistleOn) {
                stopWhistle()
            } else {
                toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
                whistleOn = true
                whistlePulse.run()
            }
            result.success(null)
        } catch (exception: Exception) {
            stopWhistle()
            result.error("AUDIO_ERROR", "The emergency sound could not be played.", exception.message)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != cameraPermissionRequest) return
        val result = pendingTorchResult ?: return
        pendingTorchResult = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            toggleTorch(result)
        } else {
            result.error(
                "CAMERA_PERMISSION",
                "Camera permission is needed to use the flashlight.",
                null,
            )
        }
    }

    private fun stopWhistle() {
        whistleOn = false
        handler.removeCallbacks(whistlePulse)
        toneGenerator?.stopTone()
        toneGenerator?.release()
        toneGenerator = null
    }

    private fun stopAllTools() {
        stopWhistle()
        if (torchOn) {
            try {
                val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
                torchCameraId?.let { manager.setTorchMode(it, false) }
            } catch (_: Exception) {
                // The camera may already be unavailable while the activity is stopping.
            }
        }
        torchOn = false
    }

    override fun onStop() {
        stopAllTools()
        super.onStop()
    }

    override fun onDestroy() {
        stopAllTools()
        super.onDestroy()
    }
}
