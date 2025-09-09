import { NativeModule, requireNativeModule } from "expo";

import { ChicBackgroundRemoverModuleEvents } from "./ChicBackgroundRemover.types";

declare class ChicBackgroundRemoverModule extends NativeModule<ChicBackgroundRemoverModuleEvents> {
	isBackgroundRemovalSupported: () => boolean;
	removeBackground: (imageUri: string) => Promise<string>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ChicBackgroundRemoverModule>(
	"ChicBackgroundRemover",
);
