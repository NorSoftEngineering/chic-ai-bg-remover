import { requireNativeView } from 'expo';
import * as React from 'react';

import { ChicBackgroundRemoverViewProps } from './ChicBackgroundRemover.types';

const NativeView: React.ComponentType<ChicBackgroundRemoverViewProps> =
  requireNativeView('ChicBackgroundRemover');

export default function ChicBackgroundRemoverView(props: ChicBackgroundRemoverViewProps) {
  return <NativeView {...props} />;
}
