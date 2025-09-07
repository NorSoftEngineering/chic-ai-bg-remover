// Reexport the native module. On web, it will be resolved to ChicBackgroundRemoverModule.web.ts
// and on native platforms to ChicBackgroundRemoverModule.ts
export { default } from './ChicBackgroundRemoverModule';
export { default as ChicBackgroundRemoverView } from './ChicBackgroundRemoverView';
export * from  './ChicBackgroundRemover.types';
