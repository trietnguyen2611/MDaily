import { BrowserWindow as e, app as t, ipcMain as n, nativeTheme as r } from "electron";
import { spawn as i } from "node:child_process";
import a from "node:fs";
import o from "node:path";
import { fileURLToPath as s } from "node:url";
//#region electron/main.ts
var c = o.dirname(s(import.meta.url));
process.env.DIST = o.join(c, "../dist"), process.env.VITE_PUBLIC = t.isPackaged ? process.env.DIST : o.join(process.env.DIST, "../public");
var l, u = process.env.VITE_DEV_SERVER_URL;
function d() {
	l = new e({
		icon: o.join(process.env.VITE_PUBLIC, "icon.png"),
		title: "MDaily Desktop v2.1",
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
			preload: o.join(c, "preload.js"),
			nodeIntegration: !0,
			contextIsolation: !1,
			webSecurity: !1
		}
	}), l.webContents.on("did-finish-load", () => {
		l?.webContents.send("main-process-message", (/* @__PURE__ */ new Date()).toLocaleString());
	}), u ? l.loadURL(u) : l.loadFile(o.join(process.env.DIST, "index.html")), r.on("updated", () => {
		l?.webContents.send("theme-changed", r.shouldUseDarkColors ? "dark" : "light");
	});
}
t.on("window-all-closed", () => {
	process.platform !== "darwin" && (t.quit(), l = null);
}), t.on("activate", () => {
	e.getAllWindows().length === 0 && d();
}), t.whenReady().then(d), n.handle("analyze-receipt-native", async (e, n) => {
	let r = t.isPackaged ? o.join(process.resourcesPath, "receipt-analyzer") : o.join(c, "../build/native/receipt-analyzer");
	return a.existsSync(r) ? new Promise((e) => {
		let t = i(r, [], { stdio: [
			"pipe",
			"pipe",
			"ignore"
		] }), a = "";
		t.stdout.on("data", (e) => {
			a += e.toString();
		}), t.once("error", () => e(null)), t.once("close", () => {
			try {
				e(JSON.parse(a.trim()));
			} catch {
				e(null);
			}
		}), t.stdin.write(`${JSON.stringify({ imageBase64: n })}\n`), t.stdin.end();
	}) : null;
}), n.handle("get-system-theme", () => r.shouldUseDarkColors ? "dark" : "light");
//#endregion
export {};
