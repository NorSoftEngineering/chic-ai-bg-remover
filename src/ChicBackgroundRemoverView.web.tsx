import * as React from 'react';

import { ChicBackgroundRemoverViewProps } from './ChicBackgroundRemover.types';

export default function ChicBackgroundRemoverView(props: ChicBackgroundRemoverViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
