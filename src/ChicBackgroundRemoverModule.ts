import type { NativeModule } from "expo";
import { requireNativeModule } from "expo";

import type { ChicBackgroundRemoverModuleEvents } from "./ChicBackgroundRemover.types";

declare class ChicBackgroundRemoverModule extends NativeModule<ChicBackgroundRemoverModuleEvents> {
	isBackgroundRemovalSupported: () => boolean;
	removeBackground: (
		imageUri: string,
		backgroundColor?: string,
	) => Promise<string>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ChicBackgroundRemoverModule>(
	"ChicBackgroundRemover",
);
