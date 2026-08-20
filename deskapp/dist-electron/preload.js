import { ipcRenderer as e } from "electron";
//#region electron/preload.ts
window.ipcRenderer = e;
//#endregion
export {};
