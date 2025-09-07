import { registerWebModule, NativeModule } from 'expo';

import { ChicBackgroundRemoverModuleEvents } from './ChicBackgroundRemover.types';

class ChicBackgroundRemoverModule extends NativeModule<ChicBackgroundRemoverModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ChicBackgroundRemoverModule, 'ChicBackgroundRemoverModule');
