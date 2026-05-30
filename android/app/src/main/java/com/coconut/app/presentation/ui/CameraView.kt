package com.coconut.app.presentation.ui

import android.annotation.SuppressLint
import android.content.Context
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.util.concurrent.Executors

import androidx.compose.ui.unit.IntSize

@Composable
fun CameraView(
    modifier: Modifier = Modifier,
    isFlashlightOn: Boolean = false,
    isScanning: Boolean = true,
    onBarcodeDetected: (android.graphics.Rect?, IntSize) -> Unit = { _, _ -> },
    onBarcodeScanned: (String) -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }
    val executor = remember { Executors.newSingleThreadExecutor() }
    val analyzer = remember { BarcodeAnalyzer(onBarcodeScanned, onBarcodeDetected) }

    LaunchedEffect(isScanning) {
        analyzer.setScanning(isScanning)
    }

    DisposableEffect(Unit) {
        onDispose {
            executor.shutdown()
        }
    }

    AndroidView(
        modifier = modifier.fillMaxSize(),
        factory = { ctx ->
            val previewView = PreviewView(ctx)
            cameraProviderFuture.addListener({
                val cameraProvider = cameraProviderFuture.get()
                val preview = Preview.Builder().build().also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

                val imageAnalyzer = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()
                    .also {
                        it.setAnalyzer(executor, analyzer)
                    }

                val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

                try {
                    cameraProvider.unbindAll()
                    val camera = cameraProvider.bindToLifecycle(
                        lifecycleOwner,
                        cameraSelector,
                        preview,
                        imageAnalyzer
                    )
                    
                    camera.cameraControl.enableTorch(isFlashlightOn)
                    
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }, ContextCompat.getMainExecutor(ctx))
            previewView
        },
        update = { previewView ->
            try {
                val cameraProvider = cameraProviderFuture.get()
                val camera = cameraProvider.bindToLifecycle(
                    lifecycleOwner,
                    CameraSelector.DEFAULT_BACK_CAMERA
                )
                camera.cameraControl.enableTorch(isFlashlightOn)
            } catch (e: Exception) {
                // Ignore
            }
        }
    )
}

class BarcodeAnalyzer(
    private val onBarcodeScanned: (String) -> Unit,
    private val onBarcodeDetected: (android.graphics.Rect?, IntSize) -> Unit
) : ImageAnalysis.Analyzer {

    private val options = BarcodeScannerOptions.Builder()
        .setBarcodeFormats(
            Barcode.FORMAT_EAN_13,
            Barcode.FORMAT_EAN_8,
            Barcode.FORMAT_UPC_A,
            Barcode.FORMAT_UPC_E,
            Barcode.FORMAT_CODE_128,
            Barcode.FORMAT_QR_CODE
        )
        .build()

    private val scanner = BarcodeScanning.getClient(options)
    private var isScanning = true

    fun setScanning(value: Boolean) {
        isScanning = value
    }

    @SuppressLint("UnsafeOptInUsageError")
    override fun analyze(imageProxy: ImageProxy) {
        val previewSize = IntSize(imageProxy.width, imageProxy.height)
        
        if (!isScanning) {
            onBarcodeDetected(null, previewSize)
            imageProxy.close()
            return
        }

        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
            
            scanner.process(image)
                .addOnSuccessListener { barcodes ->
                    val barcode = barcodes.firstOrNull()
                    if (barcode != null) {
                        onBarcodeDetected(barcode.boundingBox, previewSize)
                        val rawValue = barcode.rawValue
                        if (rawValue != null && rawValue.isNotBlank()) {
                            isScanning = false
                            onBarcodeScanned(rawValue)
                        }
                    } else {
                        onBarcodeDetected(null, previewSize)
                    }
                }
                .addOnFailureListener {
                    onBarcodeDetected(null, previewSize)
                }
                .addOnCompleteListener {
                    imageProxy.close()
                }
        } else {
            imageProxy.close()
        }
    }
}
