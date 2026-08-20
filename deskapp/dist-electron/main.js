import { BrowserWindow, app, ipcMain, nativeTheme } from "electron";
import path from "node:path";
import { fileURLToPath } from "node:url";
//#region electron/main.ts
var __dirname = path.dirname(fileURLToPath(import.meta.url));
process.env.DIST = path.join(__dirname, "../dist");
process.env.VITE_PUBLIC = app.isPackaged ? process.env.DIST : path.join(process.env.DIST, "../public");
var win;
var VITE_DEV_SERVER_URL = process.env["VITE_DEV_SERVER_URL"];
function createWindow() {
	win = new BrowserWindow({
		icon: path.join(process.env.VITE_PUBLIC, "icon.png"),
		title: "MDaily Desktop v2.1",
		width: 1e3,
		height: 700,
		minWidth: 850,
		minHeight: 600,
		titleBarStyle: "hiddenInset",
		vibrancy: "under-window",
		visualEffectState: "active",
		transparent: true,
		backgroundColor: "#00000000",
		webPreferences: {
			preload: path.join(__dirname, "preload.js"),
			nodeIntegration: true,
			contextIsolation: false,
			webSecurity: false
		}
	});
	win.webContents.on("did-finish-load", () => {
		win?.webContents.send("main-process-message", (/* @__PURE__ */ new Date()).toLocaleString());
	});
	if (VITE_DEV_SERVER_URL) win.loadURL(VITE_DEV_SERVER_URL);
	else win.loadFile(path.join(process.env.DIST, "index.html"));
	nativeTheme.on("updated", () => {
		win?.webContents.send("theme-changed", nativeTheme.shouldUseDarkColors ? "dark" : "light");
	});
}
app.on("window-all-closed", () => {
	if (process.platform !== "darwin") {
		app.quit();
		win = null;
	}
});
app.on("activate", () => {
	if (BrowserWindow.getAllWindows().length === 0) createWindow();
});
app.whenReady().then(createWindow);
ipcMain.handle("get-system-theme", () => {
	return nativeTheme.shouldUseDarkColors ? "dark" : "light";
});
//#endregion
export {};
