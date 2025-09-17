export type ChicBackgroundRemoverModuleEvents = Record<string, never>;

export interface BackgroundRemovalResult {
	success: boolean;
	processedImageUri?: string;
	wasProcessed?: boolean; // Indicates if background removal was actually performed
	error?: string;
}

export interface BackgroundRemovalOptions {
	quality?: number; // Future enhancement
	outputFormat?: "png" | "jpg"; // Future enhancement
	/** Hex color like #FFFFFF or #FFFFFFFF for background compositing */
	backgroundColor?: string;
}
