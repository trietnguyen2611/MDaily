import { BrowserWindow as e, app as t, ipcMain as n, nativeTheme as r } from "electron";
import { spawn as i } from "node:child_process";
import a from "node:http";
import o from "node:os";
import s from "node:fs";
import c from "node:path";
import { fileURLToPath as l } from "node:url";
//#region electron/main.ts
var u = c.dirname(l(import.meta.url));
process.env.DIST = c.join(u, "../dist"), process.env.VITE_PUBLIC = t.isPackaged ? process.env.DIST : c.join(process.env.DIST, "../public");
var d = null, f = process.env.VITE_DEV_SERVER_URL, p = 18321, m = v(), h = null, g = !1, _ = /* @__PURE__ */ new Set();
function v() {
	let e = "";
	for (let t = 0; t < 6; t++) e += "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".charAt(Math.floor(Math.random() * 32));
	return e;
}
function y() {
	let e = o.networkInterfaces(), t = [];
	for (let n of Object.keys(e)) for (let r of e[n] || []) r.family === "IPv4" && !r.internal && t.push(r.address);
	return t.length > 0 ? t : ["127.0.0.1"];
}
function b() {
	let e = y();
	return e.find((e) => e.startsWith("192.168.") || e.startsWith("10.") || e.startsWith("172.")) || e[0] || "127.0.0.1";
}
function x() {
	let e = b(), t = y(), n = JSON.stringify({
		app: "MDaily",
		v: "2.4",
		ip: e,
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
function S(e = "data_changed", t) {
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
}, 25e3);
var C = /* @__PURE__ */ new Map();
function w(e, t) {
	return new Promise((n, r) => {
		if (!d || d.isDestroyed()) return r(/* @__PURE__ */ Error("Window not available"));
		let i = `sync_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`, a = setTimeout(() => {
			C.delete(i), r(/* @__PURE__ */ Error("Sync request to renderer timed out"));
		}, 15e3);
		C.set(i, {
			resolve: n,
			reject: r,
			timeout: a
		}), d.webContents.send("sync-bridge-request", {
			requestId: i,
			type: e,
			payload: t
		});
	});
}
function T(e = 18321) {
	if (h) try {
		h.close();
	} catch {}
	let t = a.createServer(async (e, t) => {
		if (t.setHeader("Access-Control-Allow-Origin", "*"), t.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS"), t.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, x-sync-token"), e.method === "OPTIONS") {
			t.writeHead(204), t.end();
			return;
		}
		let n = new URL(e.url || "/", `http://localhost:${p}`), r = n.pathname, i = (t) => {
			let r = e.headers.authorization || "", i = r.startsWith("Bearer ") ? r.substring(7) : "", a = e.headers["x-sync-token"] || "", o = n.searchParams.get("token") || "";
			return (i || a || o || t || "").trim().toUpperCase() === m.toUpperCase();
		};
		if (r === "/api/ping" && e.method === "GET") {
			t.writeHead(200, { "Content-Type": "application/json" }), t.end(JSON.stringify({
				app: "MDaily",
				version: "2.4.0",
				deviceName: o.hostname(),
				status: "ready",
				timestamp: Date.now()
			}));
			return;
		}
		if (r === "/api/sync/stream" && e.method === "GET") {
			if (!i()) {
				t.writeHead(401, { "Content-Type": "application/json" }), t.end(JSON.stringify({
					success: !1,
					error: "Unauthorized: Invalid token"
				}));
				return;
			}
			t.writeHead(200, {
				"Content-Type": "text/event-stream",
				"Cache-Control": "no-cache",
				Connection: "keep-alive"
			}), t.write(`data: ${JSON.stringify({
				event: "connected",
				timestamp: Date.now()
			})}\n\n`), _.add(t), e.on("close", () => {
				_.delete(t);
			});
			return;
		}
		let a = async () => new Promise((t, n) => {
			let r = "";
			e.on("data", (e) => {
				r += e.toString();
			}), e.on("end", () => {
				try {
					t(r ? JSON.parse(r) : {});
				} catch {
					t({});
				}
			}), e.on("error", n);
		});
		try {
			if (r === "/api/sync/pull" && e.method === "POST") {
				if (!i((await a()).token)) {
					t.writeHead(401, { "Content-Type": "application/json" }), t.end(JSON.stringify({
						success: !1,
						error: "Unauthorized: Invalid token"
					}));
					return;
				}
				let e = await w("export");
				d && !d.isDestroyed() && d.webContents.send("sync-event-notification", {
					type: "pull",
					source: "phone",
					message: "Đã gửi dữ liệu chi tiêu sang Điện thoại",
					timestamp: Date.now()
				}), t.writeHead(200, { "Content-Type": "application/json" }), t.end(JSON.stringify({
					success: !0,
					expenses: e.expenses || [],
					categories: e.categories || [],
					deletedExpenseIds: e.deletedExpenseIds || [],
					timestamp: Date.now()
				}));
				return;
			}
			if (r === "/api/sync/push" && e.method === "POST") {
				let e = await a();
				if (!i(e.token)) {
					t.writeHead(401, { "Content-Type": "application/json" }), t.end(JSON.stringify({
						success: !1,
						error: "Unauthorized: Invalid token"
					}));
					return;
				}
				let n = await w("import", {
					expenses: e.expenses || [],
					categories: e.categories || [],
					deletedExpenseIds: e.deletedExpenseIds || []
				});
				d && !d.isDestroyed() && d.webContents.send("sync-event-notification", {
					type: "push",
					source: "phone",
					message: `Đã nhận ${e.expenses?.length || 0} chi tiêu từ Điện thoại`,
					timestamp: Date.now()
				}), S("data_changed", { source: "phone_push" }), t.writeHead(200, { "Content-Type": "application/json" }), t.end(JSON.stringify({
					success: !0,
					count: e.expenses?.length || 0,
					details: n,
					timestamp: Date.now()
				}));
				return;
			}
			if (r === "/api/sync/merge" && e.method === "POST") {
				let e = await a();
				if (!i(e.token)) {
					t.writeHead(401, { "Content-Type": "application/json" }), t.end(JSON.stringify({
						success: !1,
						error: "Unauthorized: Invalid token"
					}));
					return;
				}
				let n = await w("merge", {
					expenses: e.expenses || [],
					categories: e.categories || [],
					deletedExpenseIds: e.deletedExpenseIds || []
				});
				d && !d.isDestroyed() && d.webContents.send("sync-event-notification", {
					type: "merge",
					source: "phone",
					message: `Đồng bộ 2 chiều tự động (${n.expenses?.length || 0} chi tiêu)`,
					timestamp: Date.now()
				}), S("data_changed", { source: "phone_merge" }), t.writeHead(200, { "Content-Type": "application/json" }), t.end(JSON.stringify({
					success: !0,
					expenses: n.expenses || [],
					categories: n.categories || [],
					deletedExpenseIds: n.deletedExpenseIds || [],
					timestamp: Date.now()
				}));
				return;
			}
			t.writeHead(404, { "Content-Type": "application/json" }), t.end(JSON.stringify({ error: "Endpoint not found" }));
		} catch (e) {
			console.error("Sync Server Error:", e), t.writeHead(500, { "Content-Type": "application/json" }), t.end(JSON.stringify({
				success: !1,
				error: e?.message || "Internal server error"
			}));
		}
	});
	t.listen(e, "0.0.0.0", () => {
		p = e, g = !0, h = t, console.log(`[MDaily Sync Server] Running at http://${b()}:${p}`), d && !d.isDestroyed() && d.webContents.send("sync-server-status-changed", x());
	}), t.on("error", (t) => {
		t.code === "EADDRINUSE" ? (console.warn(`Port ${e} in use, trying ${e + 1}...`), T(e + 1)) : (console.error("[MDaily Sync Server Error]", t), g = !1, d && !d.isDestroyed() && d.webContents.send("sync-server-status-changed", x()));
	});
}
function E() {
	d = new e({
		icon: c.join(process.env.VITE_PUBLIC, "icon.png"),
		title: "MDaily Desktop v2.4",
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
			preload: c.join(u, "preload.js"),
			nodeIntegration: !0,
			contextIsolation: !1,
			webSecurity: !1
		}
	}), d.webContents.on("did-finish-load", () => {
		d?.webContents.send("main-process-message", (/* @__PURE__ */ new Date()).toLocaleString()), d?.webContents.send("sync-server-status-changed", x());
	}), f ? d.loadURL(f) : d.loadFile(c.join(process.env.DIST, "index.html")), r.on("updated", () => {
		d?.webContents.send("theme-changed", r.shouldUseDarkColors ? "dark" : "light");
	});
}
t.on("window-all-closed", () => {
	if (h) try {
		h.close();
	} catch {}
	process.platform !== "darwin" && (t.quit(), d = null);
}), t.on("activate", () => {
	e.getAllWindows().length === 0 && E();
}), t.whenReady().then(() => {
	T(), E();
}), n.handle("analyze-receipt-native", async (e, n) => {
	let r = t.isPackaged ? c.join(process.resourcesPath, "receipt-analyzer") : c.join(u, "../build/native/receipt-analyzer");
	return s.existsSync(r) ? new Promise((e) => {
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
}), n.handle("get-sync-server-info", () => x()), n.handle("refresh-sync-token", () => {
	m = v();
	let e = x();
	return d && !d.isDestroyed() && d.webContents.send("sync-server-status-changed", e), e;
}), n.on("broadcast-sync-event", (e, t) => {
	S("data_changed", t);
}), n.on("sync-bridge-response", (e, { requestId: t, error: n, data: r }) => {
	let i = C.get(t);
	i && (clearTimeout(i.timeout), C.delete(t), n ? i.reject(Error(n)) : i.resolve(r));
}), n.handle("get-system-theme", () => r.shouldUseDarkColors ? "dark" : "light");
//#endregion
export {};
