import { BrowserWindow as e, app as t, ipcMain as n, nativeTheme as r } from "electron";
import { spawn as i } from "node:child_process";
import a from "node:http";
import o from "node:os";
import s from "node:fs";
import c from "node:path";
import { fileURLToPath as l } from "node:url";
//#region electron/main.ts
var u = c.dirname(l(import.meta.url));
process.env.DIST = t.isPackaged ? c.join(u, "..") : c.join(u, "../dist"), process.env.VITE_PUBLIC = t.isPackaged ? process.env.DIST : c.join(process.env.DIST, "../public");
var d = null, f = process.env.VITE_DEV_SERVER_URL, p = 18321, m = "", h = null, g = !1, _ = /* @__PURE__ */ new Set();
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
function D(e, t) {
	return new Promise((n, r) => {
		if (!d || d.isDestroyed()) return r(/* @__PURE__ */ Error("Window not available"));
		let i = `sync_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`, a = setTimeout(() => {
			E.delete(i), r(/* @__PURE__ */ Error("Sync request to renderer timed out"));
		}, 15e3);
		E.set(i, {
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
function O(e = 18321) {
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
		if ((r === "/api/ping" || r === "/api/sync/discover") && e.method === "GET") {
			t.writeHead(200, {
				"Content-Type": "application/json",
				"Access-Control-Allow-Origin": "*"
			}), t.end(JSON.stringify({
				app: "MDaily",
				version: "2.4.0",
				deviceName: o.hostname(),
				status: "ready",
				port: p,
				allIps: S(),
				timestamp: Date.now()
			}));
			return;
		}
		if (r === "/api/sync/stream" && e.method === "GET") {
			if (!i()) {
				t.writeHead(401, {
					"Content-Type": "application/json",
					"Access-Control-Allow-Origin": "*"
				}), t.end(JSON.stringify({
					success: !1,
					error: "Unauthorized: Invalid token"
				}));
				return;
			}
			t.writeHead(200, {
				"Content-Type": "text/event-stream; charset=utf-8",
				"Cache-Control": "no-cache, no-transform",
				Connection: "keep-alive",
				"X-Accel-Buffering": "no",
				"Access-Control-Allow-Origin": "*"
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
					t.writeHead(401, {
						"Content-Type": "application/json",
						"Access-Control-Allow-Origin": "*"
					}), t.end(JSON.stringify({
						success: !1,
						error: "Unauthorized: Invalid token"
					}));
					return;
				}
				let e = await D("export");
				d && !d.isDestroyed() && d.webContents.send("sync-event-notification", {
					type: "pull",
					source: "phone",
					message: "Đã gửi dữ liệu chi tiêu sang Điện thoại",
					timestamp: Date.now()
				}), t.writeHead(200, {
					"Content-Type": "application/json",
					"Access-Control-Allow-Origin": "*"
				}), t.end(JSON.stringify({
					success: !0,
					expenses: e.expenses || [],
					categories: e.categories || [],
					deletedExpenseIds: e.deletedExpenseIds || [],
					deletedCategoryValues: e.deletedCategoryValues || [],
					timestamp: Date.now()
				}));
				return;
			}
			if (r === "/api/sync/push" && e.method === "POST") {
				let e = await a();
				if (!i(e.token)) {
					t.writeHead(401, {
						"Content-Type": "application/json",
						"Access-Control-Allow-Origin": "*"
					}), t.end(JSON.stringify({
						success: !1,
						error: "Unauthorized: Invalid token"
					}));
					return;
				}
				let n = await D("import", {
					expenses: e.expenses || [],
					categories: e.categories || [],
					deletedExpenseIds: e.deletedExpenseIds || [],
					deletedCategoryValues: e.deletedCategoryValues || []
				});
				d && !d.isDestroyed() && d.webContents.send("sync-event-notification", {
					type: "push",
					source: "phone",
					message: `Đã nhận ${e.expenses?.length || 0} chi tiêu từ Điện thoại`,
					timestamp: Date.now()
				}), T("data_changed", { source: "phone_push" }), t.writeHead(200, {
					"Content-Type": "application/json",
					"Access-Control-Allow-Origin": "*"
				}), t.end(JSON.stringify({
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
					t.writeHead(401, {
						"Content-Type": "application/json",
						"Access-Control-Allow-Origin": "*"
					}), t.end(JSON.stringify({
						success: !1,
						error: "Unauthorized: Invalid token"
					}));
					return;
				}
				let n = await D("merge", {
					expenses: e.expenses || [],
					categories: e.categories || [],
					deletedExpenseIds: e.deletedExpenseIds || [],
					deletedCategoryValues: e.deletedCategoryValues || []
				}), r = n.stats || {
					added: 0,
					updated: 0
				};
				((r.added || 0) > 0 || (r.updated || 0) > 0) && d && !d.isDestroyed() && d.webContents.send("sync-event-notification", {
					type: "merge",
					source: "phone",
					message: `Đã đồng bộ: +${r.added || 0} mới, ~${r.updated || 0} cập nhật`,
					timestamp: Date.now()
				}), t.writeHead(200, {
					"Content-Type": "application/json",
					"Access-Control-Allow-Origin": "*"
				}), t.end(JSON.stringify({
					success: !0,
					expenses: n.expenses || [],
					categories: n.categories || [],
					deletedExpenseIds: n.deletedExpenseIds || [],
					deletedCategoryValues: n.deletedCategoryValues || [],
					timestamp: Date.now()
				}));
				return;
			}
			t.writeHead(404, {
				"Content-Type": "application/json",
				"Access-Control-Allow-Origin": "*"
			}), t.end(JSON.stringify({ error: "Endpoint not found" }));
		} catch (e) {
			console.error("Sync Server Error:", e), t.writeHead(500, {
				"Content-Type": "application/json",
				"Access-Control-Allow-Origin": "*"
			}), t.end(JSON.stringify({
				success: !1,
				error: e?.message || "Internal server error"
			}));
		}
	});
	t.listen(e, "0.0.0.0", () => {
		p = e, g = !0, h = t, console.log(`[MDaily Sync Server] Running at http://${C()}:${p}`), d && !d.isDestroyed() && d.webContents.send("sync-server-status-changed", w());
	}), t.on("error", (t) => {
		t.code === "EADDRINUSE" ? (console.warn(`Port ${e} in use, trying ${e + 1}...`), O(e + 1)) : (console.error("[MDaily Sync Server Error]", t), g = !1, d && !d.isDestroyed() && d.webContents.send("sync-server-status-changed", w()));
	});
}
function k() {
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
	}), f ? d.loadURL(f) : d.loadFile(c.join(process.env.DIST, "index.html")), r.on("updated", () => {
		d?.webContents.send("theme-changed", r.shouldUseDarkColors ? "dark" : "light");
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
	(!h || !g) && O(), e.getAllWindows().length === 0 && k();
}), t.whenReady().then(() => {
	y(), b(), O(), k();
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
}), n.handle("get-sync-server-info", () => w()), n.handle("refresh-sync-token", () => {
	m = x(), b();
	let e = w();
	return d && !d.isDestroyed() && d.webContents.send("sync-server-status-changed", e), e;
}), n.on("broadcast-sync-event", (e, t) => {
	T("data_changed", t);
}), n.on("sync-bridge-response", (e, { requestId: t, error: n, data: r }) => {
	let i = E.get(t);
	i && (clearTimeout(i.timeout), E.delete(t), n ? i.reject(Error(n)) : i.resolve(r));
}), n.handle("get-system-theme", () => r.shouldUseDarkColors ? "dark" : "light");
//#endregion
export {};
