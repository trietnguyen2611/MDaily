import { ipcRenderer } from "electron";
//#region electron/preload.ts
window.ipcRenderer = ipcRenderer;
//#endregion
export {};
