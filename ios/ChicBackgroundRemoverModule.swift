import ExpoModulesCore
import Vision
import UIKit
import CoreImage

public class ChicBackgroundRemoverModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ChicBackgroundRemover")

    Function("isBackgroundRemovalSupported") { () -> Bool in
      if #available(iOS 17.0, *) {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
      } else {
        return false
      }
    }

    AsyncFunction("removeBackground") { (imageUri: String, backgroundColorHex: String?, promise: Promise) in
      // Check if running on simulator
      #if targetEnvironment(simulator)
      promise.reject("SIMULATOR_ERROR", "Background removal is not supported on simulator")
      return
      #endif
      
      // Check iOS version - Vision background removal requires iOS 17+
      guard #available(iOS 17.0, *) else {
        promise.reject("UNSUPPORTED_VERSION", "Background removal requires iOS 17.0 or later")
        return
      }
      
      // Process image on background queue
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let processedImageUri = try self.processBackgroundRemoval(imageUri: imageUri, backgroundColorHex: backgroundColorHex)
          DispatchQueue.main.async {
            promise.resolve(processedImageUri)
          }
        } catch {
          DispatchQueue.main.async {
            promise.reject("BACKGROUND_REMOVAL_ERROR", error.localizedDescription)
          }
        }
      }
    }
  }
  
  @available(iOS 17.0, *)
  private func processBackgroundRemoval(imageUri: String, backgroundColorHex: String?) throws -> String {
    // Load image from URI
    guard let url = URL(string: imageUri),
          let originalImage = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else {
      throw BackgroundRemovalError.invalidImage
    }
    
    // Create mask from the image
    guard let maskImage = createMask(from: originalImage) else {
      throw BackgroundRemovalError.maskGenerationFailed
    }
    
    // Apply mask to original image
    let outputImage = applyMask(mask: maskImage, to: originalImage, backgroundColorHex: backgroundColorHex)
    
    // Convert to UIImage
    let finalImage = convertToUIImage(ciImage: outputImage)
    
    // Save processed image to temporary directory
    let tempDir = FileManager.default.temporaryDirectory
    let fileName = "bg_removed_\(UUID().uuidString).png"
    let outputURL = tempDir.appendingPathComponent(fileName)
    
    guard let imageData = finalImage.pngData() else {
      throw BackgroundRemovalError.imageSaveFailed
    }
    
    try imageData.write(to: outputURL)
    
    return outputURL.absoluteString
  }
  
  @available(iOS 17.0, *)
  private func createMask(from inputImage: CIImage) -> CIImage? {
    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(ciImage: inputImage)
    
    do {
      try handler.perform([request])
      
      if let result = request.results?.first {
        let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
        return CIImage(cvPixelBuffer: mask)
      }
    } catch {
      print("Error creating mask: \(error)")
    }
    
    return nil
  }
  
  @available(iOS 17.0, *)
  private func applyMask(mask: CIImage, to image: CIImage, backgroundColorHex: String?) -> CIImage {
    guard let filter = CIFilter(name: "CIBlendWithMask") else {
      print("Failed to create CIBlendWithMask filter")
      return image
    }
    
    // Compose the foreground (subject) over a solid background color to avoid
    // black/transparent backgrounds in consumers that don't handle alpha.
    let uiColor = backgroundColorHex.flatMap { colorFromHexString($0) } ?? UIColor.white
    let backgroundImage = CIImage(color: CIColor(color: uiColor)).cropped(to: image.extent)

    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(mask, forKey: kCIInputMaskImageKey)
    filter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
    
    // Ensure the output is confined to the original image bounds
    return (filter.outputImage?.cropped(to: image.extent)) ?? image
  }

  // Parse hex strings like "#RRGGBB" or "#RRGGBBAA" into UIColor
  private func colorFromHexString(_ hexString: String) -> UIColor? {
    var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
    if hex.hasPrefix("#") {
      hex.removeFirst()
    }

    guard hex.count == 6 || hex.count == 8 else { return nil }

    var int: UInt64 = 0
    guard Scanner(string: hex).scanHexInt64(&int) else { return nil }

    let r, g, b, a: CGFloat
    if hex.count == 6 {
      r = CGFloat((int & 0xFF0000) >> 16) / 255.0
      g = CGFloat((int & 0x00FF00) >> 8) / 255.0
      b = CGFloat(int & 0x0000FF) / 255.0
      a = 1.0
    } else {
      r = CGFloat((int & 0xFF000000) >> 24) / 255.0
      g = CGFloat((int & 0x00FF0000) >> 16) / 255.0
      b = CGFloat((int & 0x0000FF00) >> 8) / 255.0
      a = CGFloat(int & 0x000000FF) / 255.0
    }

    return UIColor(red: r, green: g, blue: b, alpha: a)
  }
  
  @available(iOS 17.0, *)
  private func convertToUIImage(ciImage: CIImage) -> UIImage {
    guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
      fatalError("Failed to render CGImage")
    }
    
    return UIImage(cgImage: cgImage)
  }
}

enum BackgroundRemovalError: Error, LocalizedError {
  case invalidImage
  case noSubjectFound
  case maskGenerationFailed
  case filterCreationFailed
  case blendingFailed
  case cgImageCreationFailed
  case imageSaveFailed
  
  var errorDescription: String? {
    switch self {
    case .invalidImage:
      return "Invalid or corrupted image"
    case .noSubjectFound:
      return "No subject found in image for background removal"
    case .maskGenerationFailed:
      return "Failed to generate mask for background removal"
    case .filterCreationFailed:
      return "Failed to create image processing filter"
    case .blendingFailed:
      return "Failed to blend image with mask"
    case .cgImageCreationFailed:
      return "Failed to create final processed image"
    case .imageSaveFailed:
      return "Failed to save processed image"
    }
  }
}