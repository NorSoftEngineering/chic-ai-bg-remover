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

    AsyncFunction("removeBackground") { (imageUri: String, promise: Promise) in
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
          let processedImageUri = try self.processBackgroundRemoval(imageUri: imageUri)
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
  private func processBackgroundRemoval(imageUri: String) throws -> String {
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
    let outputImage = applyMask(mask: maskImage, to: originalImage)
    
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
  private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
    guard let filter = CIFilter(name: "CIBlendWithMask") else {
      print("Failed to create CIBlendWithMask filter")
      return image
    }
    
    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(mask, forKey: kCIInputMaskImageKey)
    filter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)
    
    return filter.outputImage ?? image
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