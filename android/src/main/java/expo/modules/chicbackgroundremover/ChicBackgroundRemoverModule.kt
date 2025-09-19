package expo.modules.chicbackgroundremover

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import androidx.core.graphics.drawable.toBitmap
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.exception.CodedException
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.Segmentation
import com.google.mlkit.vision.segmentation.SegmentationMask
import com.google.mlkit.vision.segmentation.selfie.SelfieSegmenterOptions
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.UUID

class ChicBackgroundRemoverModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ChicBackgroundRemover")

    AsyncFunction("removeBackground") { imageUri: String, backgroundColorHex: String?, promise: Promise ->
      try {
        processBackgroundRemoval(imageUri, backgroundColorHex, promise)
      } catch (e: Exception) {
        promise.reject("BACKGROUND_REMOVAL_ERROR", "Failed to process image: ${e.message}", e)
      }
    }
  }

  private fun processBackgroundRemoval(imageUri: String, backgroundColorHex: String?, promise: Promise) {
    try {
      // Load bitmap from URI
      val inputStream = appContext.reactContext?.contentResolver?.openInputStream(Uri.parse(imageUri))
      val bitmap = BitmapFactory.decodeStream(inputStream)
      inputStream?.close()

      if (bitmap == null) {
        promise.reject("INVALID_IMAGE", "Failed to load image from URI", null as Throwable?)
        return
      }

      // Create MLKit input image
      val image = InputImage.fromBitmap(bitmap, 0)

      // Configure selfie segmentation options
      val options = SelfieSegmenterOptions.Builder()
        .setDetectorMode(SelfieSegmenterOptions.SINGLE_IMAGE_MODE)
        .build()

      // Create segmenter
      val segmenter = Segmentation.getClient(options)

      // Process image
      segmenter.process(image)
        .addOnSuccessListener { segmentationMask ->
          try {
            val bgColor = parseHexColor(backgroundColorHex) ?: Color.WHITE
            val processedBitmap = applySegmentationMask(bitmap, segmentationMask, bgColor)
            val outputUri = saveBitmapToTempFile(processedBitmap)
            promise.resolve(outputUri)
          } catch (e: Exception) {
            promise.reject("PROCESSING_ERROR", "Failed to apply mask: ${e.message}", e)
          }
        }
        .addOnFailureListener { e ->
          promise.reject("SEGMENTATION_ERROR", "MLKit segmentation failed: ${e.message}", e)
        }

    } catch (e: Exception) {
      promise.reject("BACKGROUND_REMOVAL_ERROR", "Error processing image: ${e.message}", e)
    }
  }

  private fun applySegmentationMask(originalBitmap: Bitmap, mask: SegmentationMask, backgroundColor: Int): Bitmap {
    val width = originalBitmap.width
    val height = originalBitmap.height
    
    // Create result bitmap with transparency
    val resultBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    
    // Get mask buffer
    val maskBuffer = mask.buffer
    val maskArray = ByteArray(maskBuffer.remaining())
    maskBuffer.get(maskArray)
    
    // Apply mask pixel by pixel
    for (y in 0 until height) {
      for (x in 0 until width) {
        val originalPixel = originalBitmap.getPixel(x, y)
        
        // Calculate mask index (mask may be different resolution)
        val maskX = (x * mask.width) / width
        val maskY = (y * mask.height) / height
        val maskIndex = maskY * mask.width + maskX
        
        if (maskIndex < maskArray.size) {
          // Convert byte to unsigned int (0-255)
          val maskValue = maskArray[maskIndex].toInt() and 0xFF
          
          // Threshold for foreground detection (adjust as needed)
          val threshold = 128
          
          if (maskValue > threshold) {
            // Foreground - keep original pixel
            resultBitmap.setPixel(x, y, originalPixel)
          } else {
            // Background - fill with provided background color
            resultBitmap.setPixel(x, y, backgroundColor)
          }
        } else {
          // If mask is out of bounds, use background color
          resultBitmap.setPixel(x, y, backgroundColor)
        }
      }
    }
    
    return resultBitmap
  }

  private fun parseHexColor(hex: String?): Int? {
    if (hex == null) return null
    var value = hex.trim()
    if (value.startsWith("#")) value = value.substring(1)
    return try {
      when (value.length) {
        6 -> {
          val rgb = value.toLong(16).toInt()
          // Add full alpha
          0xFF000000.toInt() or rgb
        }
        8 -> {
          // ARGB
          value.toLong(16).toInt()
        }
        else -> null
      }
    } catch (e: Exception) {
      null
    }
  }

  private fun saveBitmapToTempFile(bitmap: Bitmap): String {
    val context = appContext.reactContext ?: throw IOException("React context is null")
    
    // Create temp file
    val tempDir = File(context.cacheDir, "background_removal")
    if (!tempDir.exists()) {
      tempDir.mkdirs()
    }
    
    val fileName = "bg_removed_${UUID.randomUUID()}.png"
    val tempFile = File(tempDir, fileName)
    
    // Save bitmap to file
    FileOutputStream(tempFile).use { outputStream ->
      bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
    }
    
    return "file://${tempFile.absolutePath}"
  }
}