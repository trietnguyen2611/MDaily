import { BrowserWindow as e, app as t, ipcMain as n, nativeTheme as r } from "electron";
import i from "node:path";
import { fileURLToPath as a } from "node:url";
//#region electron/main.ts
var o = i.dirname(a(import.meta.url));
process.env.DIST = i.join(o, "../dist"), process.env.VITE_PUBLIC = t.isPackaged ? process.env.DIST : i.join(process.env.DIST, "../public");
var s, c = process.env.VITE_DEV_SERVER_URL;
function l() {
	s = new e({
		icon: i.join(process.env.VITE_PUBLIC, "electron-vite.svg"),
		width: 1e3,
		height: 700,
		minWidth: 850,
		minHeight: 600,
		titleBarStyle: "hiddenInset",
		vibrancy: "under-window",
		visualEffectState: "active",
		transparent: !0,
		backgroundColor: "#00000000",
		webPreferences: {
			preload: i.join(o, "preload.js"),
			nodeIntegration: !0,
			contextIsolation: !1,
			webSecurity: !1
		}
	}), s.webContents.on("did-finish-load", () => {
		s?.webContents.send("main-process-message", (/* @__PURE__ */ new Date()).toLocaleString());
	}), c ? s.loadURL(c) : s.loadFile(i.join(process.env.DIST, "index.html")), r.on("updated", () => {
		s?.webContents.send("theme-changed", r.shouldUseDarkColors ? "dark" : "light");
	});
}
t.on("window-all-closed", () => {
	process.platform !== "darwin" && (t.quit(), s = null);
}), t.on("activate", () => {
	e.getAllWindows().length === 0 && l();
}), t.whenReady().then(l), n.handle("get-system-theme", () => r.shouldUseDarkColors ? "dark" : "light");
//#endregion
export {};
