import ChicBackgroundRemoverModule from "./ChicBackgroundRemoverModule";
import { BackgroundRemovalResult } from "./ChicBackgroundRemover.types";

/**
 * Check if background removal is supported on the current device
 * @returns boolean indicating if background removal is available
 */
export function isBackgroundRemovalSupported(): boolean {
	try {
		return ChicBackgroundRemoverModule.isBackgroundRemovalSupported();
	} catch (error) {
		console.warn("Unable to check background removal support:", error);
		return false;
	}
}

/**
 * Remove background from an image using native Vision (iOS) or MLKit (Android)
 * @param imageUri - Local file URI or base64 data URI of the image
 * @param fallbackToOriginal - If true, returns original image when background removal is not supported
 * @returns Promise resolving to the processed image URI (or original if fallback is enabled)
 */
export async function removeBackground(
	imageUri: string,
	fallbackToOriginal: boolean = false,
): Promise<string> {
	try {
		if (!imageUri) {
			throw new Error("Image URI is required");
		}

		// Validate URI format
		if (
			!imageUri.startsWith("file://") &&
			!imageUri.startsWith("data:") &&
			!imageUri.startsWith("content://")
		) {
			throw new Error(
				"Invalid image URI format. Expected file://, data:, or content:// URI",
			);
		}

		// Check if background removal is supported
		if (!isBackgroundRemovalSupported()) {
			if (fallbackToOriginal) {
				console.warn(
					"Background removal not supported on this device, returning original image",
				);
				return imageUri;
			} else {
				throw new Error(
					"Background removal is not supported on this device (requires iOS 17+ on device, not simulator)",
				);
			}
		}

		const processedImageUri =
			await ChicBackgroundRemoverModule.removeBackground(imageUri);

		if (!processedImageUri) {
			throw new Error(
				"Background removal failed - no processed image returned",
			);
		}

		return processedImageUri;
	} catch (error) {
		console.error("Background removal error:", error);
		throw error;
	}
}

/**
 * Remove background from an image with detailed result information
 * @param imageUri - Local file URI or base64 data URI of the image
 * @param fallbackToOriginal - If true, returns original image when background removal is not supported
 * @returns Promise resolving to detailed result object
 */
export async function removeBackgroundWithResult(
	imageUri: string,
	fallbackToOriginal: boolean = false,
): Promise<BackgroundRemovalResult> {
	try {
		const processedImageUri = await removeBackground(
			imageUri,
			fallbackToOriginal,
		);
		const wasProcessed = processedImageUri !== imageUri;

		return {
			success: true,
			processedImageUri,
			// Add a flag to indicate if processing actually occurred
			wasProcessed,
		};
	} catch (error) {
		return {
			success: false,
			error: error instanceof Error ? error.message : "Unknown error occurred",
		};
	}
}

// Export types for consumers
export * from "./ChicBackgroundRemover.types";
