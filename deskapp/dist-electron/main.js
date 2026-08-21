import { BrowserWindow as e, app as t, dialog as n, ipcMain as r, nativeTheme as i } from "electron";
import { spawn as a } from "node:child_process";
import o from "node:os";
import s from "node:fs";
import c from "node:path";
import { fileURLToPath as l } from "node:url";
//#region electron/main.ts
var u = c.dirname(l(import.meta.url));
process.env.DIST = c.join(u, "../dist"), process.env.VITE_PUBLIC = t.isPackaged ? process.env.DIST : c.join(process.env.DIST, "../public");
var d = null, f = process.env.VITE_DEV_SERVER_URL, p = 18321, m = "", h = null, g = !1;
setInterval(() => {
	g && T("sync_requested", { source: "desktop_interval" });
}, 1e3);
var _ = /* @__PURE__ */ new Set();
function v() {
	return c.join(t.getPath("appData"), "deskapp", "sync-server.json");
}
function y() {
	try {
		let e = JSON.parse(s.readFileSync(v(), "utf8"));
		m = typeof e.token == "string" && e.token.length > 0 ? e.token : x();
	} catch {
		try {
			let e = c.join(t.getPath("appData"), "Electron", "sync-server.json"), n = JSON.parse(s.readFileSync(e, "utf8"));
			m = typeof n.token == "string" && n.token.length > 0 ? n.token : x();
		} catch {
			m = x();
		}
	}
}
function b() {
	try {
		s.mkdirSync(c.dirname(v()), { recursive: !0 }), s.writeFileSync(v(), JSON.stringify({ token: m }), "utf8");
	} catch (e) {
		console.error("[MDaily Sync] Failed to persist sync token:", e);
	}
}
function x() {
	let e = "";
	for (let t = 0; t < 6; t++) e += "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".charAt(Math.floor(Math.random() * 32));
	return e;
}
function S() {
	let e = o.networkInterfaces(), t = [], n = [];
	for (let r of Object.keys(e)) {
		let i = /^(vboxnet|vmnet|docker|utun|tun|tap|virbr|veth|vEthernet)/i.test(r);
		for (let a of e[r] || []) a.family === "IPv4" && !a.internal && (i || a.address.startsWith("192.168.56.") || a.address.startsWith("172.17.") ? n.push(a.address) : /^(en0|wlan0|wi-fi|ethernet)/i.test(r) ? t.unshift(a.address) : t.push(a.address));
	}
	let r = [.../* @__PURE__ */ new Set([...t, ...n])];
	return r.length > 0 ? r : ["127.0.0.1"];
}
function C() {
	let e = S();
	return e.find((e) => e.startsWith("192.168.") || e.startsWith("10.") || e.startsWith("172.")) || e[0] || "127.0.0.1";
}
function w() {
	let e = C(), t = S(), n = JSON.stringify({
		app: "MDaily",
		v: "2.4",
		ip: e,
		allIps: t,
		port: p,
		token: m,
		name: o.hostname()
	});
	return {
		active: g,
		ip: e,
		port: p,
		token: m,
		url: `http://${e}:${p}`,
		qrPayload: n,
		deviceName: o.hostname(),
		allIps: t,
		connectedClients: _.size
	};
}
function T(e = "data_changed", t) {
	let n = JSON.stringify({
		event: e,
		timestamp: Date.now(),
		...t || {}
	});
	for (let e of _) try {
		e.write(`data: ${n}\n\n`);
	} catch {
		_.delete(e);
	}
}
setInterval(() => {
	for (let e of _) try {
		e.write(": ping\n\n");
	} catch {
		_.delete(e);
	}
}, 15e3);
var E = /* @__PURE__ */ new Map();
function D() {
	d = new e({
		icon: t.isPackaged ? c.join(process.resourcesPath, "icon.icns") : c.join(process.env.VITE_PUBLIC, "icon.png"),
		title: "MDaily Desktop v2.4",
		width: 1e3,
		height: 700,
		minWidth: 850,
		minHeight: 600,
		titleBarStyle: "hiddenInset",
		backgroundColor: "#f5f5f7",
		webPreferences: {
			preload: c.join(u, "preload.js"),
			nodeIntegration: !0,
			contextIsolation: !1,
			webSecurity: !1,
			backgroundThrottling: !1
		}
	}), d.webContents.on("did-finish-load", () => {
		d?.webContents.send("main-process-message", (/* @__PURE__ */ new Date()).toLocaleString()), d?.webContents.send("sync-server-status-changed", w());
	}), d.webContents.on("did-fail-load", (e, t, n, r) => {
		console.error(`[MDaily Renderer] Failed to load ${r}: ${t} ${n}`);
	}), d.webContents.on("console-message", (e, t, n, r, i) => {
		console.log(`[MDaily Renderer] ${i}:${r} ${n}`);
	}), f ? d.loadURL(f) : d.loadFile(c.join(process.env.DIST, "index.html")), i.on("updated", () => {
		d?.webContents.send("theme-changed", i.shouldUseDarkColors ? "dark" : "light");
	});
}
t.on("window-all-closed", () => {
	if (process.platform !== "darwin") {
		if (h) {
			try {
				h.close();
			} catch {}
			h = null;
		}
		g = !1, t.quit(), d = null;
	}
}), t.on("activate", () => {
	e.getAllWindows().length === 0 && D();
}), t.whenReady().then(() => {
	y(), b(), D();
}), r.handle("analyze-receipt-native", async (e, n) => {
	let r = t.isPackaged ? c.join(process.resourcesPath, "receipt-analyzer") : c.join(u, "../build/native/receipt-analyzer");
	return s.existsSync(r) ? new Promise((e) => {
		let t = a(r, [], { stdio: [
			"pipe",
			"pipe",
			"ignore"
		] }), i = "";
		t.stdout.on("data", (e) => {
			i += e.toString();
		}), t.once("error", () => e(null)), t.once("close", () => {
			try {
				e(JSON.parse(i.trim()));
			} catch {
				e(null);
			}
		}), t.stdin.write(`${JSON.stringify({ imageBase64: n })}\n`), t.stdin.end();
	}) : null;
}), r.handle("get-sync-server-info", () => w()), r.handle("refresh-sync-token", () => {
	m = x(), b();
	let e = w();
	return d && !d.isDestroyed() && d.webContents.send("sync-server-status-changed", e), e;
}), r.handle("choose-cloud-sync-file", async () => {
	let e = await n.showOpenDialog(d || void 0, {
		title: "Choose MDaily iCloud sync file",
		properties: ["openFile", "createDirectory"],
		filters: [{
			name: "MDaily Sync File",
			extensions: ["json"]
		}]
	});
	if (e.canceled || e.filePaths.length === 0) return { configured: !1 };
	let r = e.filePaths[0];
	return s.writeFileSync(c.join(t.getPath("userData"), "cloud-sync-path.json"), JSON.stringify({ filePath: r })), {
		configured: !0,
		name: c.basename(r)
	};
});
function O() {
	if (process.platform === "darwin") return c.join(o.homedir(), "Library/Mobile Documents/com~apple~CloudDocs/MDaily.sync.json");
	if (process.platform === "win32") {
		let e = c.join(o.homedir(), "iCloudDrive", "MDaily.sync.json");
		return s.existsSync(c.dirname(e)) ? e : c.join(o.homedir(), "iCloud Drive", "MDaily.sync.json");
	}
	return c.join(o.homedir(), "MDaily.sync.json");
}
function k() {
	let e = O();
	try {
		if (s.existsSync(c.dirname(e))) return s.existsSync(e) || s.writeFileSync(e, JSON.stringify({
			version: 1,
			updatedAt: Date.now(),
			expenses: [],
			categories: [],
			deletedExpenseIds: [],
			deletedCategoryValues: []
		}), "utf8"), s.writeFileSync(c.join(t.getPath("userData"), "cloud-sync-path.json"), JSON.stringify({ filePath: e })), e;
	} catch (e) {
		console.warn("[MDaily Cloud Sync] Could not create default iCloud file:", e);
	}
	return null;
}
r.handle("read-cloud-sync-file", () => {
	try {
		let e = c.join(t.getPath("userData"), "cloud-sync-path.json");
		s.existsSync(e) || k();
		let n = JSON.parse(s.readFileSync(e, "utf8"));
		return {
			configured: !0,
			contents: s.readFileSync(n.filePath, "utf8"),
			name: c.basename(n.filePath)
		};
	} catch {
		return { configured: !1 };
	}
}), r.handle("write-cloud-sync-file", (e, n) => {
	try {
		let e = JSON.parse(s.readFileSync(c.join(t.getPath("userData"), "cloud-sync-path.json"), "utf8"));
		return s.writeFileSync(e.filePath, n, "utf8"), {
			configured: !0,
			success: !0
		};
	} catch {
		return {
			configured: !1,
			success: !1
		};
	}
}), r.on("broadcast-sync-event", (e, t) => {
	T("data_changed", t);
}), r.on("request-sync-now", () => {
	T("sync_requested", { source: "desktop_manual" });
}), r.on("sync-bridge-response", (e, { requestId: t, error: n, data: r }) => {
	let i = E.get(t);
	i && (clearTimeout(i.timeout), E.delete(t), n ? i.reject(Error(n)) : i.resolve(r));
}), r.handle("get-system-theme", () => i.shouldUseDarkColors ? "dark" : "light");
//#endregion
export {};
