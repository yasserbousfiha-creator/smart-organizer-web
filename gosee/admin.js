// GOSEE admin portal (smartorganizer.shop/gosee). Static page: Supabase auth (email + password, admins table) and
// row security decide what it can read; every change goes through the admin_* database functions.
(() => {
  "use strict";
  const cfg = window.GOSEE_CONFIG;
  const sb = supabase.createClient(cfg.url, cfg.anonKey, { auth: { persistSession: true, storageKey: "gosee-admin" } });
  const $ = (id) => document.getElementById(id);
  const esc = (v) => String(v ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const n = (v) => Number(v || 0).toLocaleString("en-US");
  const sar = (v) => `${n(v)} ر.س`;

  // ── data ────────────────────────────────────────────────────────────────────────────────────────────────
  const D = { bookings: [], models: [], priv: {}, clients: {}, settings: null, events: {} };
  const ui = { filter: "open", sel: null, q: "", payTab: "receipts", rec: null, receiptUrls: {}, payPick: new Set() };

  async function loadAll() {
    await sb.rpc("advance_bookings");
    const [b, m, p, c, s] = await Promise.all([
      sb.from("bookings").select("*").order("created_at", { ascending: false }).limit(2000),
      sb.from("models").select("*").order("created_at"),
      sb.from("model_private").select("*"),
      sb.from("clients").select("*"),
      sb.from("settings").select("*").eq("id", 1).single(),
    ]);
    for (const r of [b, m, p, c, s]) if (r.error) throw r.error;
    D.bookings = b.data;
    D.models = m.data;
    D.priv = Object.fromEntries(p.data.map((x) => [x.model_id, x]));
    D.clients = Object.fromEntries(c.data.map((x) => [x.user_id, x]));
    D.settings = s.data;
  }
  const model = (id) => D.models.find((m) => m.id === id) || { name: "؟" };
  const client = (b) => D.clients[b.client_user] || {};

  // ── dates (Taif) ────────────────────────────────────────────────────────────────────────────────────────
  const DAYS = ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"];
  const MONTHS = ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"];
  const taifNow = () => new Date(Date.now() + 3 * 3600e3);
  const todayIso = () => taifNow().toISOString().slice(0, 10);
  const hourLabel = (h) => { const x = ((h % 24) + 24) % 24; const p = x < 12 ? "ص" : "م"; const k = x % 12 || 12; return `${k}:00 ${p}`; };
  const dayLabel = (iso) => {
    const d = new Date(iso + "T00:00:00Z");
    const diff = Math.round((d - new Date(todayIso() + "T00:00:00Z")) / 864e5);
    if (diff === 0) return "اليوم";
    if (diff === 1) return "غداً";
    if (diff === -1) return "أمس";
    return `${DAYS[d.getUTCDay()]} ${d.getUTCDate()} ${MONTHS[d.getUTCMonth()]}`;
  };
  const when = (b) => `${dayLabel(b.date)}، ${hourLabel(b.start_hour)}`;
  const hoursLabel = (h) => (h === 1 ? "ساعة" : h === 2 ? "ساعتان" : h <= 10 ? `${h} ساعات` : `${h} ساعة`);
  const ago = (ts) => {
    const m = Math.round((Date.now() - new Date(ts)) / 60e3);
    if (m < 1) return "الآن";
    if (m < 60) return `قبل ${m} دقيقة`;
    const h = Math.round(m / 60);
    if (h < 24) return h === 1 ? "قبل ساعة" : `قبل ${h} ساعات`;
    const d = Math.round(h / 24);
    return d === 1 ? "أمس" : `قبل ${d} أيام`;
  };
  const stamp = (ts) => { const d = new Date(new Date(ts).getTime() + 3 * 3600e3); return `${dayLabel(d.toISOString().slice(0, 10))} ${d.getUTCHours() % 12 || 12}:${String(d.getUTCMinutes()).padStart(2, "0")} ${d.getUTCHours() < 12 ? "ص" : "م"}`; };

  // ── states ──────────────────────────────────────────────────────────────────────────────────────────────
  function state(b) {
    if (b.status === "approved" && b.deposit_status === "submitted") return ["receipt", "إيصال للمراجعة"];
    if (b.status === "approved" && b.deposit_status === "rejected") return ["rejected-receipt", "إيصال مرفوض"];
    return [b.status, { pending: "بانتظار رد المودل", approved: "بانتظار العربون", confirmed: "مؤكدة", completed: "منتهية", rejected: "اعتذر المودل", cancelled: "ملغاة", expired: "انتهت المهلة" }[b.status]];
  }
  const pill = (b) => { const [k, t] = state(b); return `<span class="pill s-${k}">${t}</span>`; };
  const code = (b) => `GS-${b.code}`;
  const isReceipt = (b) => b.status === "approved" && b.deposit_status === "submitted";
  const parties = (b) => `<b>${esc(b.client_name)}</b> ← ${esc(model(b.model_id).name)}`;

  // ── shell ───────────────────────────────────────────────────────────────────────────────────────────────
  const ICON = {
    today: '<rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/>',
    bookings: '<rect x="3" y="4" width="18" height="17" rx="2"/><path d="M8 2v4M16 2v4M3 10h18"/>',
    payments: '<rect x="2" y="6" width="20" height="13" rx="2"/><path d="M2 10h20M6 15h4"/>',
    models: '<circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/>',
    clients: '<path d="M3 21V8l9-5 9 5v13"/><path d="M9 21v-7h6v7"/>',
    settings: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M2 12h3M19 12h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/>',
  };
  const svg = (k) => `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICON[k]}</svg>`;
  const PAGES = [["today", "لوحة اليوم"], ["bookings", "الطلبات"], ["payments", "المبالغ"], ["models", "المودلز"], ["clients", "العملاء"], ["settings", "الإعدادات"]];
  const route = () => (location.hash.replace(/^#\/?/, "").split("/")[0] || "today");

  function renderMenu() {
    const r = route();
    const waiting = D.bookings.filter((b) => b.status === "pending").length;
    const money = D.bookings.filter(isReceipt).length + D.bookings.filter((b) => b.payout_status === "due").length + D.bookings.filter((b) => b.refund_status === "due").length;
    const pending = D.models.filter((m) => !m.is_sample && !m.verified && m.status === "active").length;
    const counts = { bookings: waiting, payments: money, models: pending };
    $("menu").innerHTML = PAGES.map(([k, t]) => `<a href="#/${k}" class="${r === k ? "on" : ""}" ${r === k ? 'aria-current="page"' : ""}>${svg(k)}${t}${counts[k] ? `<span class="count">${counts[k]}</span>` : ""}</a>`).join("");
  }

  function render() {
    renderMenu();
    const r = route();
    const page = { today: pageToday, bookings: pageBookings, payments: pagePayments, models: pageModels, clients: pageClients, settings: pageSettings }[r] || pageToday;
    $("main").innerHTML = page();
    after[r]?.();
  }
  const after = {};

  // ── today ───────────────────────────────────────────────────────────────────────────────────────────────
  function pageToday() {
    const t = todayIso();
    const pending = D.bookings.filter((b) => b.status === "pending");
    const soon = pending.filter((b) => Date.now() - new Date(b.created_at) > 11 * 3600e3).length;
    const receipts = D.bookings.filter(isReceipt);
    const today = D.bookings.filter((b) => b.date === t && ["confirmed", "completed"].includes(b.status)).sort((a, b) => a.start_hour - b.start_hour);
    const due = D.bookings.filter((b) => b.payout_status === "due");
    const month = t.slice(0, 7);
    const done = D.bookings.filter((b) => b.status === "completed" && b.date.startsWith(month));
    const sum = (xs, k) => xs.reduce((a, b) => a + (b[k] || 0), 0);
    const hour = taifNow().getUTCHours();
    const hello = hour < 12 ? "صباح الخير" : "مساء الخير";
    const d = taifNow();
    return `
      <header class="head"><div><h1>${hello}</h1><span class="sub">${DAYS[d.getUTCDay()]} ${d.getUTCDate()} ${MONTHS[d.getUTCMonth()]} ${d.getUTCFullYear()} · الطائف</span></div>
        <div class="push"><button class="btn" data-act="refresh">تحديث</button></div></header>
      <section class="kpis" aria-label="أرقام اليوم">
        <a class="kpi" href="#/bookings/pending"><span class="label">طلبات بانتظار رد المودل</span><span class="num">${pending.length}</span><span class="hint ${soon ? "warn" : ""}">${soon ? `${soon} منها تنتهي مهلتها خلال ساعة` : "المهلة 12 ساعة"}</span></a>
        <a class="kpi dark" href="#/payments"><span class="label">إيصالات عربون للمراجعة</span><span class="num">${receipts.length}</span><span class="hint">${receipts.length ? `مجموعها ${sar(sum(receipts, "deposit"))}` : "لا شيء الآن"}</span></a>
        <div class="kpi"><span class="label">جلسات اليوم</span><span class="num">${today.length}</span><span class="hint">${today.length ? `الأولى ${hourLabel(today[0].start_hour)} · الأخيرة ${hourLabel(today[today.length - 1].start_hour)}` : "لا جلسات"}</span></div>
        <a class="kpi" href="#/payments/payouts"><span class="label">مستحقات للمودلز</span><span class="num">${n(sum(due, "payout"))} <small style="font-size:15px">ر.س</small></span><span class="hint">${due.length} تحويل بعد جلسات منتهية</span></a>
      </section>
      <div class="row">
        <section class="card wide"><div class="card-head"><h2>إيصالات تنتظر التأكيد</h2><a href="#/payments">كل الإيصالات</a></div>
          ${receipts.length ? receipts.map((b) => `<div class="item"><div class="grow"><span>${parties(b)}</span><span class="sub">${code(b)} · ${when(b)} · رُفع ${ago(b.receipt_at)}</span></div><span class="amount">${sar(b.deposit)}</span><a class="btn primary small" href="#/payments/receipts/${b.id}">مراجعة</a></div>`).join("") : `<p class="empty">لا إيصالات تنتظر.</p>`}
        </section>
        <section class="card narrow"><h2>جلسات اليوم</h2>
          ${today.length ? today.map((b) => { const live = b.status === "confirmed" && hour >= b.start_hour && hour < b.start_hour + b.hours; return `<div class="session"><span class="t">${hourLabel(b.start_hour)}</span><div class="grow"><b>${esc(model(b.model_id).name)}</b><span class="sub">${esc(b.client_name)} · ${hoursLabel(b.hours)}</span></div>${live ? '<span class="pill s-receipt">جارية الآن</span>' : pill(b)}</div>`; }).join("") : `<p class="empty">لا جلسات اليوم.</p>`}
        </section>
      </div>
      <section class="card"><div class="card-head"><h2>دخل المنصة هذا الشهر</h2></div>
        <p class="note">رسوم الخدمة ${Math.round(D.settings.client_fee * 100)}% من العميل + عمولة ${Math.round(D.settings.model_commission * 100)}% من المودل، من الجلسات المنتهية.</p>
        <div class="stats">
          <div><span>جلسات منتهية</span><strong>${done.length}</strong></div>
          <div><span>قيمة الجلسات</span><strong>${sar(sum(done, "subtotal"))}</strong></div>
          <div><span>رسوم الخدمة</span><strong>${sar(sum(done, "fee"))}</strong></div>
          <div><span>العمولة</span><strong>${sar(sum(done, "commission"))}</strong></div>
          <div><span>صافي المنصة</span><strong style="color:var(--plum)">${sar(sum(done, "fee") + sum(done, "commission"))}</strong></div>
        </div>
      </section>`;
  }

  // ── bookings ────────────────────────────────────────────────────────────────────────────────────────────
  const GROUPS = [
    ["open", "المفتوحة", (b) => ["pending", "approved", "confirmed"].includes(b.status)],
    ["pending", "بانتظار رد المودل", (b) => b.status === "pending"],
    ["approved", "بانتظار العربون", (b) => b.status === "approved" && !isReceipt(b)],
    ["receipt", "إيصال للمراجعة", isReceipt],
    ["confirmed", "مؤكدة", (b) => b.status === "confirmed"],
    ["completed", "منتهية", (b) => b.status === "completed"],
    ["closed", "ملغاة ومرفوضة ومنتهية المهلة", (b) => ["cancelled", "rejected", "expired"].includes(b.status)],
    ["all", "الكل", () => true],
  ];
  function searchHit(b) {
    if (!ui.q) return true;
    const q = ui.q.trim().toLowerCase().replace(/^gs-?/, "");
    const c = client(b);
    return [String(b.code), b.client_name, model(b.model_id).name, c.phone, c.name].some((x) => String(x || "").toLowerCase().includes(q));
  }
  function pageBookings() {
    const parts = location.hash.split("/");
    if (parts[2] && GROUPS.some((g) => g[0] === parts[2])) ui.filter = parts[2];
    if (parts[3]) ui.sel = parts[3];
    const g = GROUPS.find((x) => x[0] === ui.filter) || GROUPS[0];
    const rows = D.bookings.filter(g[2]).filter(searchHit);
    if (!ui.sel || !D.bookings.some((b) => b.id === ui.sel)) ui.sel = rows[0]?.id || null;
    return `
      <header class="head"><h1>الطلبات</h1>
        <div class="push"><label class="sr" for="q">بحث في الطلبات</label><input id="q" class="search" type="search" placeholder="رقم طلب، عميل، مودل أو جوال" value="${esc(ui.q)}">
        <button class="btn" data-act="csv-bookings">تصدير (Excel)</button></div></header>
      <div class="chips" role="group" aria-label="تصفية حسب الحالة">
        ${GROUPS.map(([k, t, f]) => `<button class="chip ${ui.filter === k ? "on" : ""}" aria-pressed="${ui.filter === k}" data-filter="${k}">${t} <b>${D.bookings.filter(f).length}</b></button>`).join("")}
      </div>
      <div class="row">
        <section class="card wide" style="padding:0" aria-label="قائمة الطلبات"><div class="table-box">
          ${rows.length ? `<table><thead><tr><th>الطلب</th><th>العميل ← المودل</th><th>الموعد</th><th>الإجمالي</th><th>الحالة</th></tr></thead><tbody>
            ${rows.map((b) => `<tr class="click ${b.id === ui.sel ? "sel" : ""}" data-sel="${b.id}" tabindex="0"><td class="code">${code(b)}</td><td>${parties(b)}${model(b.model_id).is_sample ? ' <span class="pill s-sample">تجريبي</span>' : ""}</td><td>${when(b)}</td><td>${sar(b.total)}</td><td>${pill(b)}</td></tr>`).join("")}
          </tbody></table>` : `<p class="empty">لا طلبات هنا.</p>`}
        </div></section>
        <aside class="card narrow" id="detail" aria-label="تفاصيل الطلب">${ui.sel ? detail(D.bookings.find((b) => b.id === ui.sel)) : `<p class="empty">اختر طلباً.</p>`}</aside>
      </div>`;
  }
  const PLACE = { work: "مقر العميل", home: "منزل العميل" };
  const USAGE = { social: "سوشال ميديا", paid: "إعلان مدفوع", print: "مطبوعات ولوحات" };
  const EVENT = {
    created: ["أرسل العميل الطلب", ""], approved: ["وافق المودل", ""], rejected: ["اعتذر المودل", "bad"], proposed: ["اقترح المودل وقتاً آخر", ""],
    accepted_proposal: ["وافق العميل على الوقت الجديد", ""], declined_proposal: ["رفض العميل الوقت الجديد", "bad"], receipt: ["رفع العميل إيصال العربون", ""],
    deposit_confirmed: ["أكدت الإدارة العربون", "ok"], deposit_rejected: ["رفضت الإدارة الإيصال", "bad"], cancelled: ["أُلغي الطلب", "bad"],
    expired: ["انتهت المهلة", "sys"], completed: ["انتهت الجلسة", "ok"], payout_paid: ["حُوّل مستحق المودل", "ok"], refund_done: ["استُرجع العربون", "ok"],
  };
  const ACTOR = { client: "العميل", model: "المودل", admin: "الإدارة", system: "النظام" };
  function detail(b) {
    if (!b) return "";
    const m = model(b.model_id), c = client(b), pv = D.priv[b.model_id] || {};
    const ev = D.events[b.id];
    if (!ev) loadEvents(b.id);
    const open = ["pending", "approved", "confirmed"].includes(b.status);
    return `
      <div class="card-head"><h2>${code(b)}</h2>${pill(b)}</div>
      <div class="facts">
        <div><span>العميل</span><b>${esc(b.client_name)}</b><span>${b.client_kind === "company" ? "شركة" : "فرد"}${c.phone ? ` · <a href="tel:${esc(c.phone)}" dir="ltr">${esc(c.phone)}</a>` : ""}</span></div>
        <div><span>المودل</span><b>${esc(m.name)}</b><span>${m.is_sample ? "حساب تجريبي" : pv.phone ? `<a href="tel:${esc(pv.phone)}" dir="ltr">${esc(pv.phone)}</a>` : ""}</span></div>
        <div><span>الموعد</span><b>${when(b)}</b><span>${hoursLabel(b.hours)}</span></div>
        <div><span>المكان والاستخدام</span><b>${PLACE[b.place] || ""}${b.address ? `، ${esc(b.address)}` : ""}</b><span>${USAGE[b.usage] || esc(b.usage)}</span></div>
      </div>
      ${b.note ? `<p class="note">ملاحظة العميل: ${esc(b.note)}</p>` : ""}
      ${b.decline_note ? `<p class="note">ملاحظة الإلغاء/الاعتذار: ${esc(b.decline_note)}</p>` : ""}
      ${b.proposal_date ? `<p class="note">اقترح المودل: ${dayLabel(b.proposal_date)}، ${hourLabel(b.proposal_start)} (بانتظار رد العميل)</p>` : ""}
      <div class="money">
        <div>سعر المودل<b>${sar(b.subtotal)}</b></div>
        <div>رسوم الخدمة<b>${sar(b.fee)}</b></div>
        <div class="strong">يدفع العميل<b>${sar(b.total)}</b></div>
        <hr>
        <div>العربون (تحويل للمنصة)<b>${sar(b.deposit)}${b.deposit_received != null && b.deposit_received !== b.deposit ? ` · وصل ${n(b.deposit_received)}` : ""}</b></div>
        <div>الباقي يدفعه العميل للمودل يوم الجلسة<b>${sar(b.total - b.deposit)}</b></div>
        <div>عمولة المنصة<b>${sar(b.commission)}</b></div>
        <div class="plum">تحوّله المنصة للمودل بعد الجلسة<b>${sar(b.payout)}</b></div>
        ${b.payout_status === "paid" ? `<div>حُوّل للمودل<b>${stamp(b.payout_paid_at)}${b.payout_ref ? ` · ${esc(b.payout_ref)}` : ""}</b></div>` : ""}
        ${b.refund_status !== "none" ? `<div>استرجاع للعميل<b>${sar(b.refund_amount)} · ${b.refund_status === "done" ? "تم" : "بانتظار التحويل"}</b></div>` : ""}
      </div>
      <div><h3 style="margin:0 0 6px;font-size:15px">سجل الطلب</h3><div class="log" id="log">${ev ? ev.map((e) => { const [t, k] = EVENT[e.kind] || [e.kind, ""]; return `<div><i class="${k}"></i><span>${t}${e.note ? `: ${esc(e.note)}` : ""}<small>${ACTOR[e.actor]} · ${stamp(e.at)}</small></span></div>`; }).join("") : '<span class="note">...</span>'}</div></div>
      <label>ملاحظة داخلية (لا يراها العميل ولا المودل)<textarea id="admin-note" rows="2">${esc(b.admin_note)}</textarea></label>
      <div class="actions">
        <button class="btn small" data-act="save-note" data-id="${b.id}">حفظ الملاحظة</button>
        ${isReceipt(b) ? `<a class="btn primary small" href="#/payments/receipts/${b.id}">مراجعة الإيصال</a>` : ""}
        ${c.phone ? `<a class="btn small" target="_blank" rel="noopener" href="${wa(c.phone)}">واتساب العميل</a>` : ""}
        ${pv.phone ? `<a class="btn small" target="_blank" rel="noopener" href="${wa(pv.phone)}">واتساب المودل</a>` : ""}
        ${open ? `<button class="btn danger small" data-act="admin-cancel" data-id="${b.id}">إلغاء الطلب</button>` : ""}
      </div>`;
  }
  const wa = (p) => `https://wa.me/${String(p).replace(/\D/g, "").replace(/^0/, "966")}`;
  async function loadEvents(id) {
    const { data } = await sb.from("booking_events").select("*").eq("booking_id", id).order("at");
    D.events[id] = data || [];
    if (ui.sel === id && $("detail")) $("detail").innerHTML = detail(D.bookings.find((b) => b.id === id));
  }

  // ── payments ────────────────────────────────────────────────────────────────────────────────────────────
  function pagePayments() {
    const parts = location.hash.split("/");
    if (["receipts", "payouts", "refunds", "ledger"].includes(parts[2])) ui.payTab = parts[2];
    if (parts[3]) ui.rec = parts[3];
    const receipts = D.bookings.filter(isReceipt).sort((a, b) => new Date(a.receipt_at) - new Date(b.receipt_at));
    const payouts = D.bookings.filter((b) => b.payout_status === "due");
    const refunds = D.bookings.filter((b) => b.refund_status !== "none");
    const tabs = [["receipts", "إيصالات العربون", receipts.length], ["payouts", "مستحقات المودلز", payouts.length], ["refunds", "الاسترجاع", refunds.filter((b) => b.refund_status === "due").length], ["ledger", "دفتر العمولة", ""]];
    const s = D.settings;
    let body = "";
    if (ui.payTab === "receipts") {
      if (!receipts.some((b) => b.id === ui.rec)) ui.rec = receipts[0]?.id || null;
      const cur = receipts.find((b) => b.id === ui.rec);
      body = receipts.length ? `<div class="row">
        <section class="narrow" style="display:flex;flex-direction:column;gap:10px" aria-label="إيصالات بانتظار التأكيد">
          ${receipts.map((b) => `<button class="pick ${b.id === ui.rec ? "on" : ""}" data-rec="${b.id}"><span style="flex:1;display:flex;flex-direction:column"><b>${esc(b.client_name)}</b><span class="note">${code(b)} · رُفع ${ago(b.receipt_at)}</span></span><span class="amount">${sar(b.deposit)}</span></button>`).join("")}
        </section>
        <section class="card wide" aria-label="مراجعة الإيصال"><div class="row" style="gap:20px">
          <div class="receipt-view" id="receipt-view">جارٍ تحميل الإيصال...</div>
          <div style="flex:1 1 260px;display:flex;flex-direction:column;gap:12px;min-width:0">
            <h2 style="margin:0">${code(cur)} · ${esc(cur.client_name)}</h2>
            <div class="money"><div>المودل<b>${esc(model(cur.model_id).name)}</b></div><div>الموعد<b>${when(cur)}</b></div><div class="plum">العربون المطلوب<b>${sar(cur.deposit)}</b></div></div>
            <label>المبلغ الذي وصل الحساب<input id="received" type="text" inputmode="numeric" value="${cur.deposit}"></label>
            <label class="check"><input type="checkbox" id="seen">تأكدت من وصول المبلغ في كشف الحساب</label>
            <div class="actions"><button class="btn primary" data-act="confirm-deposit" data-id="${cur.id}">تأكيد العربون</button><button class="btn danger" data-act="reject-deposit" data-id="${cur.id}">رفض مع سبب</button><a class="btn" href="#/bookings/all/${cur.id}">الطلب</a></div>
            <p class="note">بعد التأكيد يصير الطلب «مؤكداً» ويرى العميل والمودل ذلك في التطبيق. الرفض يرجع الطلب إلى «بانتظار العربون» ويظهر السبب للعميل.</p>
          </div></div></section></div>` : `<section class="card"><p class="empty">لا إيصالات تنتظر التأكيد.</p></section>`;
    } else if (ui.payTab === "payouts") {
      const total = payouts.filter((b) => ui.payPick.has(b.id)).reduce((a, b) => a + b.payout, 0);
      body = `<section class="card" aria-label="مستحقات المودلز">
        <p class="note">بعد كل جلسة منتهية: العربون ناقص رسوم الخدمة وعمولة المنصة يُحوَّل للمودل. باقي السعر دفعه العميل للمودل يوم الجلسة.</p>
        ${payouts.length ? `<div class="table-box"><table><thead><tr><th><span class="sr">اختيار</span></th><th>المودل</th><th>الجلسة</th><th>العربون</th><th>رسوم + عمولة</th><th>يُحوَّل</th><th>IBAN</th></tr></thead><tbody>
          ${payouts.map((b) => { const pv = D.priv[b.model_id] || {}; return `<tr><td><input type="checkbox" class="pay-pick" data-id="${b.id}" ${ui.payPick.has(b.id) ? "checked" : ""} aria-label="اختيار ${code(b)}" style="width:20px;min-height:20px;height:20px"></td><td><b>${esc(model(b.model_id).name)}</b></td><td>${code(b)} · ${dayLabel(b.date)}</td><td>${n(b.deposit_received ?? b.deposit)}</td><td>${n(b.fee + b.commission)}</td><td class="code">${sar(b.payout)}</td><td class="ltr">${pv.iban ? `${esc(pv.iban)}<br><small>${esc(pv.iban_name)}</small>` : '<span class="note">لم تضفه المودل</span>'}</td></tr>`; }).join("")}
        </tbody></table></div>
        <div class="actions" style="align-items:center"><b>المختار: ${sar(total)}</b><button class="btn primary" data-act="mark-paid" ${ui.payPick.size ? "" : "disabled"}>تم التحويل للمختار</button><button class="btn" data-act="pick-all">اختيار الكل</button><button class="btn" data-act="csv-payouts">ملف التحويلات (Excel)</button></div>` : `<p class="empty">لا مستحقات الآن.</p>`}
      </section>`;
    } else if (ui.payTab === "refunds") {
      body = `<section class="card" aria-label="الاسترجاع">${refunds.length ? refunds.map((b) => `<div class="item"><div class="grow"><b>${esc(b.client_name)} · ${code(b)}</b><span class="sub">${esc(b.refund_reason || "")}${client(b).phone ? ` · <span dir="ltr">${esc(client(b).phone)}</span>` : ""}</span></div><span class="amount">${sar(b.refund_amount)}</span>${b.refund_status === "done" ? `<span class="pill s-confirmed">تم الاسترجاع</span>` : `<span class="pill s-pending">بانتظار التحويل</span><button class="btn primary small" data-act="refund-done" data-id="${b.id}">تم الاسترجاع</button>`}</div>`).join("") : `<p class="empty">لا استرجاع.</p>`}
        ${s.refund_policy ? `<p class="note">سياسة الاسترجاع: ${esc(s.refund_policy)}</p>` : `<p class="note">اكتب سياسة الاسترجاع في الإعدادات.</p>`}</section>`;
    } else {
      const months = [...new Set(D.bookings.filter((b) => b.status === "completed").map((b) => b.date.slice(0, 7)))].sort().reverse();
      const mon = ui.ledgerMonth || months[0] || todayIso().slice(0, 7);
      const rows = D.bookings.filter((b) => b.status === "completed" && b.date.startsWith(mon)).sort((a, b) => a.date.localeCompare(b.date));
      const sum = (k) => rows.reduce((a, b) => a + b[k], 0);
      body = `<section class="card" aria-label="دفتر العمولة">
        <div class="actions" style="align-items:center"><label style="display:flex;align-items:center;gap:8px">الشهر <select id="ledger-month">${(months.length ? months : [mon]).map((m) => `<option value="${m}" ${m === mon ? "selected" : ""}>${MONTHS[+m.slice(5) - 1]} ${m.slice(0, 4)}</option>`).join("")}</select></label><button class="btn" data-act="csv-ledger" style="margin-inline-start:auto">تصدير (Excel)</button></div>
        ${rows.length ? `<div class="table-box"><table><thead><tr><th>التاريخ</th><th>الطلب</th><th>سعر الجلسة</th><th>رسوم الخدمة</th><th>العمولة</th><th>صافي المنصة</th></tr></thead><tbody>
          ${rows.map((b) => `<tr><td>${b.date}</td><td>${code(b)} · ${esc(model(b.model_id).name)}</td><td>${n(b.subtotal)}</td><td>${n(b.fee)}</td><td>${n(b.commission)}</td><td class="code">${sar(b.fee + b.commission)}</td></tr>`).join("")}
          <tr><td colspan="2"><b>المجموع (${rows.length})</b></td><td><b>${n(sum("subtotal"))}</b></td><td><b>${n(sum("fee"))}</b></td><td><b>${n(sum("commission"))}</b></td><td class="code">${sar(sum("fee") + sum("commission"))}</td></tr>
        </tbody></table></div>` : `<p class="empty">لا جلسات منتهية في هذا الشهر.</p>`}
      </section>`;
    }
    return `<header class="head"><h1>المبالغ</h1><span class="sub">${s.bank_iban ? `حساب المنصة: ${esc(s.bank_name)} · <span dir="ltr">${esc(s.bank_iban)}</span>` : 'أضف حساب المنصة البنكي من <a href="#/settings">الإعدادات</a> ليظهر للعملاء في التطبيق'}</span></header>
      <div class="tabs" role="tablist">${tabs.map(([k, t, c]) => `<button role="tab" aria-selected="${ui.payTab === k}" class="${ui.payTab === k ? "on" : ""}" data-tab="${k}">${t} ${c !== "" ? `<small>${c}</small>` : ""}</button>`).join("")}</div>
      ${body}`;
  }
  after.payments = async () => {
    const box = $("receipt-view");
    if (!box || !ui.rec) return;
    const b = D.bookings.find((x) => x.id === ui.rec);
    if (!b?.receipt_path) { box.textContent = "لا صورة."; return; }
    let url = ui.receiptUrls[b.receipt_path];
    if (!url) {
      const { data, error } = await sb.storage.from("receipts").createSignedUrl(b.receipt_path, 3600);
      if (error) { box.textContent = "تعذر فتح الإيصال."; return; }
      url = ui.receiptUrls[b.receipt_path] = data.signedUrl;
    }
    if (/\.pdf$/i.test(b.receipt_path)) box.innerHTML = `<a class="btn" target="_blank" rel="noopener" href="${esc(url)}">فتح ملف PDF</a>`;
    else box.innerHTML = `<img src="${esc(url)}" alt="إيصال التحويل" data-zoom>`;
  };

  // ── models ──────────────────────────────────────────────────────────────────────────────────────────────
  const KIND = { woman: "امرأة", man: "رجل", child: "طفل" };
  function pageModels() {
    const list = [...D.models].sort((a, b) => (a.is_sample - b.is_sample) || (a.verified - b.verified) || a.name.localeCompare(b.name));
    return `<header class="head"><h1>المودلز</h1><span class="sub">${D.models.filter((m) => !m.is_sample).length} حساب حقيقي · ${D.models.filter((m) => m.is_sample).length} تجريبي</span></header>
      <section class="card" style="padding:0"><div class="table-box"><table><thead><tr><th>المودل</th><th>النوع</th><th>الساعة / نصف يوم / يوم</th><th>الجلسات</th><th>التقييم</th><th>الجوال</th><th>IBAN</th><th>الحالة</th><th></th></tr></thead><tbody>
        ${list.map((m) => { const pv = D.priv[m.id] || {}; const photo = m.photos?.[0]; return `<tr><td><div style="display:flex;align-items:center;gap:10px">${photo && /^https?:/.test(photo) ? `<img class="photo" src="${esc(photo)}" alt="">` : `<span class="photo"></span>`}<span><b>${esc(m.name)}</b>${m.is_sample ? ' <span class="pill s-sample">تجريبي</span>' : ""}<br><small class="note">${esc(m.bio).slice(0, 60)}</small></span></div></td>
          <td>${KIND[m.kind] || ""}${m.age ? ` · ${m.age}` : ""}</td><td>${n(m.hourly)} / ${n(m.half_day)} / ${n(m.full_day)}</td><td>${m.completed}</td><td>${m.rating_count ? `${m.rating} (${m.rating_count})` : "-"}</td>
          <td class="ltr">${esc(pv.phone || "")}</td><td class="ltr">${esc(pv.iban || "")}</td>
          <td>${m.status === "suspended" ? '<span class="pill s-cancelled">موقوف</span>' : m.verified ? '<span class="pill s-confirmed">موثّق</span>' : '<span class="pill s-pending">بانتظار التوثيق</span>'}</td>
          <td><div class="actions">${m.is_sample ? "" : `<button class="btn small" data-act="verify" data-id="${m.id}" data-on="${!m.verified}">${m.verified ? "إلغاء التوثيق" : "توثيق"}</button><button class="btn ${m.status === "suspended" ? "" : "danger"} small" data-act="suspend" data-id="${m.id}" data-on="${m.status !== "suspended"}">${m.status === "suspended" ? "تفعيل" : "إيقاف"}</button>`}</div></td></tr>`; }).join("")}
      </tbody></table></div></section>`;
  }

  // ── clients ─────────────────────────────────────────────────────────────────────────────────────────────
  function pageClients() {
    const list = Object.values(D.clients).sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    const stats = (u) => { const bs = D.bookings.filter((b) => b.client_user === u); return [bs.length, bs.filter((b) => b.status === "completed").reduce((a, b) => a + b.total, 0)]; };
    return `<header class="head"><h1>العملاء</h1><span class="sub">${list.length} عميل</span></header>
      <section class="card" style="padding:0"><div class="table-box">${list.length ? `<table><thead><tr><th>العميل</th><th>النوع</th><th>الجوال</th><th>العنوان</th><th>الطلبات</th><th>قيمة الجلسات المنتهية</th><th>منذ</th></tr></thead><tbody>
        ${list.map((c) => { const [cnt, val] = stats(c.user_id); return `<tr><td><b>${esc(c.kind === "company" && c.business_name ? c.business_name : c.name)}</b>${c.kind === "company" && c.business_name ? `<br><small class="note">${esc(c.name)}</small>` : ""}</td><td>${c.kind === "company" ? "شركة" : "فرد"}</td><td class="ltr"><a href="${wa(c.phone)}" target="_blank" rel="noopener">${esc(c.phone)}</a></td><td>${esc(c.address)}</td><td>${cnt}</td><td>${sar(val)}</td><td>${dayLabel(c.created_at.slice(0, 10))}</td></tr>`; }).join("")}
      </tbody></table>` : `<p class="empty">لا عملاء بعد.</p>`}</div></section>`;
  }

  // ── settings ────────────────────────────────────────────────────────────────────────────────────────────
  function pageSettings() {
    const s = D.settings;
    return `<header class="head"><h1>الإعدادات</h1></header>
      <section class="card"><h2>حساب المنصة البنكي</h2><p class="note">يظهر للعميل في التطبيق عند دفع العربون.</p>
        <div class="form">
          <label>البنك<input id="bank_name" value="${esc(s.bank_name)}"></label>
          <label>اسم صاحب الحساب<input id="bank_holder" value="${esc(s.bank_holder)}"></label>
          <label>IBAN<input id="bank_iban" dir="ltr" value="${esc(s.bank_iban)}" placeholder="SA00 0000 0000 0000 0000 0000"></label>
        </div></section>
      <section class="card"><h2>النسب</h2><p class="note">تُطبَّق على الطلبات الجديدة فقط؛ الطلب يحفظ مبالغه وقت إرساله.</p>
        <div class="form">
          <label>رسوم الخدمة على العميل %<input id="client_fee" inputmode="decimal" value="${+(s.client_fee * 100).toFixed(2)}"></label>
          <label>عمولة المنصة من المودل %<input id="model_commission" inputmode="decimal" value="${+(s.model_commission * 100).toFixed(2)}"></label>
          <label>العربون من الإجمالي %<input id="deposit_share" inputmode="decimal" value="${+(s.deposit_share * 100).toFixed(2)}"></label>
        </div></section>
      <section class="card"><h2>سياسة الاسترجاع</h2><textarea id="refund_policy" rows="3">${esc(s.refund_policy)}</textarea></section>
      <div class="actions"><button class="btn primary" data-act="save-settings">حفظ الإعدادات</button></div>
      <section class="card"><h2>كلمة مرور الدخول</h2><div class="form"><label>كلمة مرور جديدة (8 أحرف على الأقل)<input id="new-pw" type="password" autocomplete="new-password" dir="ltr"></label></div>
        <div class="actions"><button class="btn" data-act="change-pw">تغيير كلمة المرور</button></div></section>`;
  }

  // ── actions ─────────────────────────────────────────────────────────────────────────────────────────────
  function toast(t) { const el = $("toast"); el.textContent = t; el.hidden = false; clearTimeout(toast.t); toast.t = setTimeout(() => (el.hidden = true), 3200); }
  const ERR = { forbidden: "ليست لديك صلاحية.", not_waiting: "الطلب لم يعد بانتظار التأكيد (حدّث الصفحة).", not_open: "الطلب لم يعد مفتوحاً.", not_due: "تم من قبل." };
  async function call(fn, args, ok) {
    const { error } = await sb.rpc(fn, args);
    if (error) { toast(ERR[error.message] || `تعذر الحفظ: ${error.message}`); return false; }
    if (ok) toast(ok);
    await refresh();
    return true;
  }
  function ask(title, fields, okText, danger) {
    return new Promise((resolve) => {
      $("dialog-title").textContent = title;
      $("dialog-body").innerHTML = fields.map((f) => `<label>${f.label}${f.area ? `<textarea id="f-${f.id}" rows="3">${esc(f.value || "")}</textarea>` : `<input id="f-${f.id}" value="${esc(f.value ?? "")}" ${f.num ? 'inputmode="numeric"' : ""}>`}</label>`).join("");
      $("dialog-actions").innerHTML = `<button class="btn ${danger ? "danger" : "primary"}" id="d-ok">${okText}</button><button class="btn" id="d-no">رجوع</button>`;
      $("dialog").hidden = false;
      const first = $("dialog-body").querySelector("input,textarea");
      (first || $("d-ok")).focus();
      const done = (v) => { $("dialog").hidden = true; resolve(v); };
      $("d-ok").onclick = () => done(Object.fromEntries(fields.map((f) => [f.id, $(`f-${f.id}`).value.trim()])));
      $("d-no").onclick = () => done(null);
      $("dialog").onkeydown = (e) => e.key === "Escape" && done(null);
    });
  }
  const num = (v) => { const x = Number(String(v).replace(/[٠-٩]/g, (d) => "٠١٢٣٤٥٦٧٨٩".indexOf(d)).replace(/[^\d.]/g, "")); return Number.isFinite(x) ? Math.round(x) : null; };

  function csv(name, head, rows) {
    const cell = (v) => `"${String(v ?? "").replace(/"/g, '""')}"`;
    const text = "﻿" + [head, ...rows].map((r) => r.map(cell).join(",")).join("\r\n");
    const a = document.createElement("a");
    a.href = URL.createObjectURL(new Blob([text], { type: "text/csv;charset=utf-8" }));
    a.download = name;
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 2000);
  }

  const ACT = {
    refresh: () => refresh().then(() => toast("تم التحديث")),
    "save-note": (el) => call("admin_set_note", { p_id: el.dataset.id, p_note: $("admin-note").value }, "حُفظت الملاحظة"),
    "admin-cancel": async (el) => {
      const b = D.bookings.find((x) => x.id === el.dataset.id);
      const paid = b.deposit_status === "confirmed" || b.deposit_status === "submitted";
      const v = await ask(`إلغاء ${code(b)}`, [{ id: "reason", label: "السبب (يظهر للعميل والمودل)", area: true }, ...(paid ? [{ id: "refund", label: "يُسترجع للعميل (ر.س)", value: b.deposit_received ?? b.deposit, num: true }] : [])], "إلغاء الطلب", true);
      if (v) call("admin_cancel", { p_id: b.id, p_reason: v.reason, p_refund: paid ? num(v.refund) || 0 : 0 }, "أُلغي الطلب");
    },
    "confirm-deposit": (el) => {
      if (!$("seen").checked) { toast("تأكد من كشف الحساب أولاً وضع علامة."); $("seen").focus(); return; }
      const v = num($("received").value);
      if (!v) { toast("اكتب المبلغ الذي وصل."); return; }
      call("admin_confirm_deposit", { p_id: el.dataset.id, p_received: v }, "تم تأكيد العربون");
    },
    "reject-deposit": async (el) => {
      const v = await ask("رفض الإيصال", [{ id: "reason", label: "السبب (يظهر للعميل)", area: true, value: "لم يصل المبلغ إلى الحساب" }], "رفض", true);
      if (v && v.reason) call("admin_reject_deposit", { p_id: el.dataset.id, p_reason: v.reason }, "رُفض الإيصال");
    },
    "pick-all": () => { D.bookings.filter((b) => b.payout_status === "due").forEach((b) => ui.payPick.add(b.id)); render(); },
    "mark-paid": async () => {
      const v = await ask(`تحويل ${ui.payPick.size} مستحق`, [{ id: "ref", label: "مرجع التحويل (اختياري)" }], "تم التحويل");
      if (v) { const ids = [...ui.payPick]; ui.payPick.clear(); call("admin_mark_payouts", { p_ids: ids, p_ref: v.ref }, "سُجّل التحويل"); }
    },
    "refund-done": async (el) => {
      const b = D.bookings.find((x) => x.id === el.dataset.id);
      const v = await ask(`استرجاع ${code(b)}`, [{ id: "amount", label: "المبلغ المسترجع (ر.س)", value: b.refund_amount, num: true }], "تم الاسترجاع");
      if (v) call("admin_refund_done", { p_id: b.id, p_amount: num(v.amount) }, "سُجّل الاسترجاع");
    },
    verify: async (el) => { const { error } = await sb.from("models").update({ verified: el.dataset.on === "true" }).eq("id", el.dataset.id); if (error) toast(error.message); else { toast("تم"); refresh(); } },
    suspend: async (el) => { const { error } = await sb.from("models").update({ status: el.dataset.on === "true" ? "suspended" : "active" }).eq("id", el.dataset.id); if (error) toast(error.message); else { toast("تم"); refresh(); } },
    "save-settings": async () => {
      const pct = (id) => { const v = Number($(id).value); return Number.isFinite(v) && v >= 0 && v <= 100 ? v / 100 : null; };
      const row = { bank_name: $("bank_name").value.trim(), bank_holder: $("bank_holder").value.trim(), bank_iban: $("bank_iban").value.replace(/\s+/g, " ").trim().toUpperCase(), refund_policy: $("refund_policy").value.trim(), client_fee: pct("client_fee"), model_commission: pct("model_commission"), deposit_share: pct("deposit_share"), updated_at: new Date().toISOString() };
      if ([row.client_fee, row.model_commission, row.deposit_share].includes(null)) { toast("النسب أرقام بين 0 و 100."); return; }
      const { error } = await sb.from("settings").update(row).eq("id", 1);
      if (error) toast(error.message); else { toast("حُفظت الإعدادات"); refresh(); }
    },
    "change-pw": async () => {
      const pw = $("new-pw").value;
      if (pw.length < 8) { toast("8 أحرف على الأقل."); return; }
      const { error } = await sb.auth.updateUser({ password: pw });
      toast(error ? error.message : "تغيّرت كلمة المرور");
      $("new-pw").value = "";
    },
    "csv-bookings": () => csv(`gosee-bookings-${todayIso()}.csv`, ["الطلب", "التاريخ", "الساعة", "الساعات", "العميل", "جوال العميل", "المودل", "سعر المودل", "رسوم الخدمة", "الإجمالي", "العربون", "العمولة", "للمودل بعد الجلسة", "الحالة", "العربون", "التحويل للمودل", "الاسترجاع"],
      D.bookings.map((b) => [code(b), b.date, b.start_hour, b.hours, b.client_name, client(b).phone, model(b.model_id).name, b.subtotal, b.fee, b.total, b.deposit, b.commission, b.payout, state(b)[1], b.deposit_status, b.payout_status, b.refund_status])),
    "csv-payouts": () => csv(`gosee-payouts-${todayIso()}.csv`, ["المودل", "صاحب الحساب", "IBAN", "المبلغ", "الطلب", "تاريخ الجلسة"],
      D.bookings.filter((b) => b.payout_status === "due" && (!ui.payPick.size || ui.payPick.has(b.id))).map((b) => { const pv = D.priv[b.model_id] || {}; return [model(b.model_id).name, pv.iban_name, pv.iban, b.payout, code(b), b.date]; })),
    "csv-ledger": () => { const mon = $("ledger-month").value; csv(`gosee-ledger-${mon}.csv`, ["التاريخ", "الطلب", "المودل", "سعر الجلسة", "رسوم الخدمة", "العمولة", "صافي المنصة"], D.bookings.filter((b) => b.status === "completed" && b.date.startsWith(mon)).map((b) => [b.date, code(b), model(b.model_id).name, b.subtotal, b.fee, b.commission, b.fee + b.commission])); },
  };

  document.addEventListener("click", (e) => {
    const t = e.target.closest("[data-act],[data-filter],[data-sel],[data-tab],[data-rec],[data-zoom]");
    if (!t) return;
    if (t.dataset.act) return ACT[t.dataset.act]?.(t);
    if (t.dataset.filter) { ui.filter = t.dataset.filter; ui.sel = null; location.hash = `#/bookings/${ui.filter}`; return; }
    if (t.dataset.sel) { ui.sel = t.dataset.sel; document.querySelectorAll("tr.sel").forEach((r) => r.classList.remove("sel")); t.classList.add("sel"); $("detail").innerHTML = detail(D.bookings.find((b) => b.id === ui.sel)); return; }
    if (t.dataset.tab) { location.hash = `#/payments/${t.dataset.tab}`; return; }
    if (t.dataset.rec) { location.hash = `#/payments/receipts/${t.dataset.rec}`; return; }
    if (t.dataset.zoom !== undefined) { const z = document.createElement("div"); z.className = "zoom"; z.innerHTML = `<img src="${esc(t.src)}" alt="إيصال التحويل">`; z.onclick = () => z.remove(); document.body.append(z); }
  });
  document.addEventListener("keydown", (e) => { if (e.key === "Enter" && e.target.dataset?.sel) e.target.click(); });
  document.addEventListener("change", (e) => {
    if (e.target.classList.contains("pay-pick")) { e.target.checked ? ui.payPick.add(e.target.dataset.id) : ui.payPick.delete(e.target.dataset.id); render(); }
    if (e.target.id === "ledger-month") { ui.ledgerMonth = e.target.value; render(); }
  });
  document.addEventListener("input", (e) => {
    if (e.target.id === "q") {
      ui.q = e.target.value;
      clearTimeout(ACT.qt);
      ACT.qt = setTimeout(() => { const pos = e.target.selectionStart; render(); const q = $("q"); q.focus(); q.setSelectionRange(pos, pos); }, 200);
    }
  });
  window.addEventListener("hashchange", () => { render(); $("main").focus(); });

  // ── start ───────────────────────────────────────────────────────────────────────────────────────────────
  let busy = false, again = false;
  async function refresh() {
    if (busy) { again = true; return; }
    busy = true;
    try { await loadAll(); D.events = {}; render(); } catch (e) { toast(`تعذر التحميل: ${e.message || e}`); }
    busy = false;
    if (again) { again = false; refresh(); }
  }

  let channel = null;
  async function start() {
    const { data: { session } } = await sb.auth.getSession();
    if (!session) { $("login").hidden = false; $("shell").hidden = true; return; }
    const { data: me } = await sb.from("admins").select("name").eq("user_id", session.user.id).maybeSingle();
    if (!me) { await sb.auth.signOut(); $("login-error").textContent = "هذا الحساب ليس مديراً."; $("login").hidden = false; return; }
    $("me-name").textContent = me.name || "المدير";
    $("login").hidden = true; $("shell").hidden = false;
    await refresh();
    channel = sb.channel("admin-bookings").on("postgres_changes", { event: "*", schema: "public", table: "bookings" }, () => { clearTimeout(start.t); start.t = setTimeout(refresh, 600); }).subscribe();
    setInterval(refresh, 60e3);
  }
  $("login-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    $("login-error").textContent = "";
    const { error } = await sb.auth.signInWithPassword({ email: $("email").value.trim(), password: $("password").value });
    if (error) { $("login-error").textContent = "البريد أو كلمة المرور غير صحيحة."; return; }
    start();
  });
  $("logout").addEventListener("click", async () => { channel && sb.removeChannel(channel); await sb.auth.signOut(); location.reload(); });
  start();
})();
