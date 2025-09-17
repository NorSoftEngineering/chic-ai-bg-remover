# chic-background-remover

Background Remover

# API documentation

- [Documentation for the latest stable release](https://docs.expo.dev/versions/latest/sdk/chic-background-remover/)
- [Documentation for the main branch](https://docs.expo.dev/versions/unversioned/sdk/chic-background-remover/)

# Installation in managed Expo projects

For [managed](https://docs.expo.dev/archive/managed-vs-bare/) Expo projects, please follow the installation instructions in the [API documentation for the latest stable release](#api-documentation). If you follow the link and there is no documentation available then this library is not yet usable within managed projects &mdash; it is likely to be included in an upcoming Expo SDK release.

# Installation in bare React Native projects

For bare React Native projects, you must ensure that you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/) before continuing.

### Add the package to your npm dependencies

```
npm install chic-background-remover
```

### Configure for Android




### Configure for iOS

Run `npx pod-install` after installing the npm package.

# Usage

```ts
import { removeBackground, removeBackgroundWithResult } from 'chic-background-remover';

// Simple usage
const uri = await removeBackground('file:///path/to/image.png');

// With options: composite subject over a solid background color
const whiteBg = await removeBackground('file:///path.png', { backgroundColor: '#FFFFFF' });

// Fallback to original if unsupported
const uriOrOriginal = await removeBackground('file:///path.png', true);

// Detailed result
const result = await removeBackgroundWithResult('file:///path.png', { backgroundColor: '#FF0000' }, true);
```

Notes:
- `backgroundColor` accepts `#RRGGBB` or `#RRGGBBAA`.
- iOS requires iOS 17+ and a physical device (Vision APIs are not available on the simulator).
- Android uses ML Kit Selfie Segmentation.

# Contributing

Contributions are very welcome! Please refer to guidelines described in the [contributing guide]( https://github.com/expo/expo#contributing).
