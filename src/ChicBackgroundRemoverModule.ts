import { NativeModule, requireNativeModule } from 'expo';

import { ChicBackgroundRemoverModuleEvents } from './ChicBackgroundRemover.types';

declare class ChicBackgroundRemoverModule extends NativeModule<ChicBackgroundRemoverModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ChicBackgroundRemoverModule>('ChicBackgroundRemover');
