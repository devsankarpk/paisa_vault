// Paisa Vault clickable prototype. Plain JS, hash routing, dummy data from data.js.
const $ = (s) => document.querySelector(s);
const inr = (n, sign) => (sign && n < 0 ? '-' : '') + '₹' + Math.abs(n).toLocaleString('en-IN', { minimumFractionDigits: n % 1 ? 2 : 0, maximumFractionDigits: 2 });

const P = {
  home: 'M3 11l9-8 9 8v9a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1z',
  chart: 'M4 4h13a3 3 0 013 3v13H7a3 3 0 01-3-3zM8 15l3-4 3 2 4-5',
  list: 'M6 3h12a1 1 0 011 1v16a1 1 0 01-1 1H6a1 1 0 01-1-1V4a1 1 0 011-1zM9 8h6M9 12h6M9 16h4',
  card: 'M3 6h18a1 1 0 011 1v10a1 1 0 01-1 1H3a1 1 0 01-1-1V7a1 1 0 011-1zM2 10h20M6 15h4',
  user: 'M12 12a4 4 0 100-8 4 4 0 000 8zM4 21c0-4 3.5-6 8-6s8 2 8 6',
  search: 'M11 18a7 7 0 100-14 7 7 0 000 14zM21 21l-5-5',
  bell: 'M6 16V11a6 6 0 1112 0v5l2 2H4zM10 21h4',
  back: 'M15 5l-7 7 7 7',
  wallet: 'M3 7h16a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2zM3 7l11-3v3M16 14h2',
  transfer: 'M7 4v16M7 4L3 8M7 4l4 4M17 20V4M17 20l-4-4M17 20l4-4',
  doc: 'M6 3h9l4 4v14H6zM9 12h7M9 16h7',
  plus: 'M12 5v14M5 12h14',
  food: 'M7 3v8a2 2 0 002 2v8M11 3v6a2 2 0 01-2 2M17 3c-2 2-3 5-3 8h3v10',
  bag: 'M5 8h14l-1 12H6zM9 8a3 3 0 016 0',
  car: 'M4 14l2-6h12l2 6v4h-3v-2H7v2H4zM7 14h.01M17 14h.01',
  dots: 'M6 12h.01M12 12h.01M18 12h.01',
  question: 'M9 9a3 3 0 116 0c0 2-3 2-3 4M12 17h.01',
  lock: 'M6 11h12v10H6zM8 11V8a4 4 0 018 0v3',
  eye: 'M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12zM12 15a3 3 0 100-6 3 3 0 000 6z',
  eyeoff: 'M3 3l18 18M10 6a9 9 0 0112 6 13 13 0 01-3 3.5M6 7.5A13 13 0 002 12s4 7 10 7a9 9 0 003.5-.7',
  users: 'M9 11a3.5 3.5 0 100-7 3.5 3.5 0 000 7zM2 20c0-3.5 3-5 7-5s7 1.5 7 5M17 4a3.5 3.5 0 010 7M22 20c0-2.5-1.5-4-4-4.6',
  shield: 'M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z',
  backup: 'M12 16V4M7 9l5-5 5 5M4 16v4h16v-4',
  target: 'M12 21a9 9 0 100-18 9 9 0 000 18zM12 16a4 4 0 100-8 4 4 0 000 8z',
  report: 'M5 20V10M12 20V4M19 20v-7',
  chevron: 'M9 5l7 7-7 7',
  sliders: 'M5 8h.01M10 8h9M5 16h9M19 16h.01',
  check: 'M5 12l5 5 9-10',
  nfc: 'M6 8a8 8 0 010 8M10 6a11 11 0 010 12M14 4a14 14 0 010 16',
};
const ic = (n, c = '') => `<svg class="ico ${c}" viewBox="0 0 24 24"><path d="${P[n]}"/></svg>`;

const NAV = [['home', 'home'], ['dashboard', 'chart'], ['activity', 'list'], ['cards', 'card'], ['profile', 'user']];
const NAV_ROUTES = NAV.map((n) => n[0]);

function toast(msg) { const t = $('#toast'); t.textContent = msg; t.classList.add('show'); clearTimeout(toast.t); toast.t = setTimeout(() => t.classList.remove('show'), 1600); }
const go = (r) => { location.hash = '#/' + r; };
const back = (title, right = '') => `<div class="top"><button class="iconbtn" data-go="home" data-back>${ic('back')}</button><h1>${title}</h1>${right}</div>`;
const searchBtn = `<button class="iconbtn" data-go="search">${ic('search')}</button>`;

function ccCard(c) {
  const bal = c.type === 'Credit' ? `<span class="lbl">Credit used</span><div class="bal"><small>INR</small>${(c.used).toLocaleString('en-IN')}</div>` : `<span class="lbl">${c.bank} Debit</span><div class="bal"><small>INR</small>${c.bal.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</div>`;
  return `<div class="cc ${c.color}" data-go="card/${c.id}">${bal}<div class="net"><i></i><i></i></div>
    <div class="num">****&nbsp;&nbsp;****&nbsp;&nbsp;****&nbsp;&nbsp;${c.last4}</div>
    <div class="foot"><span>${c.holder}</span><span><small>${c.network} · ${c.type}</small><small>Exp. ${c.exp}</small></span></div></div>`;
}

function txnRow(t) {
  const right = t.confirm ? `<span class="pill warn">Confirm</span>` : t.ask ? `<span class="pill warn">Categorise</span>` : `<span class="amt ${t.amt < 0 ? 'neg' : 'pos'}">${t.amt < 0 ? '-' : '+'}${inr(t.amt)}</span>`;
  return `<button class="row" data-go="${t.ask ? 'ask' : t.self ? 'selftransfers' : 'txn/' + t.id}"><div class="ic tone-${t.tone}">${ic(t.icon)}</div><div class="mid"><div class="t">${t.m}</div><div class="s">${t.sub}</div></div>${right}</button>`;
}

function donut(parts, size = 170, w = 28) {
  const r = (size - w) / 2, C = 2 * Math.PI * r, total = parts.reduce((a, p) => a + p.amount, 0);
  let off = 0;
  const arcs = parts.map((p) => { const len = (p.amount / total) * C; const s = `<circle cx="${size / 2}" cy="${size / 2}" r="${r}" fill="none" stroke="${p.color}" stroke-width="${w}" stroke-dasharray="${len - 2} ${C}" stroke-dashoffset="${-off}"/>`; off += len; return s; }).join('');
  return `<svg viewBox="0 0 ${size} ${size}">${arcs}</svg>`;
}
function ring(pct, color) {
  const r = 17, C = 2 * Math.PI * r;
  return `<svg viewBox="0 0 44 44"><circle cx="22" cy="22" r="${r}" fill="none" stroke="#eef1fa" stroke-width="6"/><circle cx="22" cy="22" r="${r}" fill="none" stroke="${color}" stroke-width="6" stroke-linecap="round" stroke-dasharray="${(pct / 100) * C} ${C}"/></svg>`;
}

/* ---------- screens ---------- */
const S = {};

let pin = '';
const pinPad = (title, sub, bio = true) => `<div class="lock"><div class="logo">${ic('shield')}</div><h1 style="font-size:22px">${title}</h1><p class="sub" style="margin-top:6px">${sub}</p>
  <div class="pins">${[0, 1, 2, 3].map((i) => `<i class="${i < pin.length ? 'on' : ''}"></i>`).join('')}</div>
  <div class="keys">${[1, 2, 3, 4, 5, 6, 7, 8, 9].map((k) => `<button data-key="${k}">${k}</button>`).join('')}${bio ? '<button data-key="bio" style="font-size:13px;color:var(--blue)">Use Face ID</button>' : '<span></span>'}<button data-key="0">0</button><button data-key="del">⌫</button></div></div>`;
S.lock = () => pinPad('Paisa Vault', 'Enter your PIN to unlock');

S.home = () => `
  <div class="top"><div><div class="hello">Hello</div><div class="name">${DATA.user.name}</div></div>
    <div class="acts">${searchBtn}<button class="iconbtn" data-go="alerts">${ic('bell')}<i class="dot"></i></button></div></div>
  <div class="peek">${DATA.cards.map(ccCard).join('')}</div>
  <h2 style="margin-top:6px">Quick actions</h2>
  <div class="services">
    ${[['Add', 'plus', 'green', 'addtxn'], ['Budgets', 'target', 'orange', 'budgets'], ['Reports', 'report', 'violet', 'reports'], ['Household', 'users', 'blue', 'household']].map((s) => `<button class="svc" data-go="${s[3]}"><div class="tile tone-${s[2]}">${ic(s[1])}</div>${s[0]}</button>`).join('')}
  </div>
  <h2>Recent transactions</h2>
  ${DATA.txns.slice(0, 4).map(txnRow).join('')}
  <button class="btn ghost" data-go="activity">See all activity</button>`;

S.dashboard = () => {
  const cats = DATA.categories;
  return `<div class="top"><button class="iconbtn" data-go="home">${ic('back')}</button><h1>Dashboard</h1>${searchBtn}</div>
  <div class="card"><div class="donut">${donut(cats)}<div class="c"><div class="sub">Oct spend</div></div></div>
    <div class="big">${inr(DATA.balance)}</div><div class="sub" style="text-align:center;margin-top:4px">Available balance</div>
    <div class="trio"><div><small>Earning</small><b class="pos">${inr(DATA.earning)}</b></div><div><small>Spend</small><b style="color:#e9a912">${inr(DATA.spend)}</b></div><div><small>Savings</small><b>${inr(DATA.earning - DATA.spend)}</b></div></div>
    <div class="legend">${cats.map((c) => `<span><i style="background:${c.color}"></i>${c.name} ${Math.round((c.amount / DATA.spend) * 100)}%</span>`).join('')}</div></div>
  <h2>Budgets</h2>
  <div class="tabs" id="btabs">${['All', 'Near limit', 'On track'].map((t, i) => `<button class="${i ? '' : 'on'}" data-btab="${t}">${t}</button>`).join('')}</div>
  <div id="blist">${budgetRows('All')}</div>`;
};
function budgetRows(tab) {
  return DATA.budgets.filter((b) => { const p = b.spent / b.limit; return tab === 'All' || (tab === 'Near limit' ? p >= 0.7 : p < 0.7); }).map((b) => {
    const p = Math.round((b.spent / b.limit) * 100);
    return `<div class="row"><div class="ic" style="background:var(--blue-soft);color:var(--blue)">${ic(b.icon)}</div><div class="mid"><div class="t">${b.name}</div><div class="s">${inr(b.spent)} of ${inr(b.limit)}</div><div class="prog"><i class="${p >= 90 ? 'max' : p >= 70 ? 'hi' : ''}" style="width:${p}%"></i></div></div><span class="pill ${p >= 70 ? 'warn' : 'ghost'}">${p}%</span></div>`;
  }).join('') || '<p class="sub">Nothing here.</p>';
}

S.activity = () => `
  <div class="top"><button class="iconbtn" data-go="home">${ic('back')}</button><h1>Activity</h1>${searchBtn}</div>
  <div class="card"><div class="stathead"><h3>Statistics</h3><span class="sub">17–23 Oct ▾</span></div>
    <div class="limit"><div class="l"><i>${ic('sliders')}</i>Daily limit</div><div class="r">₹1,500<small>per day</small></div></div>
    <div class="bars">${DATA.week.map((d) => `<div class="bar"><div class="track"><div class="fill" style="height:${d.v}%"></div></div>${d.d}<small>${d.l}</small></div>`).join('')}</div></div>
  <h2>Analytics</h2>
  <div class="rings">${[['Bank', 62, '#5ad0f5'], ['Cards', 48, '#f6a65a'], ['UPI', 80, '#a89cf0']].map((r) => `<div class="ring">${ring(r[1], r[2])}${r[0]}</div>`).join('')}</div>
  <h2>Transactions</h2>
  ${DATA.txns.map(txnRow).join('')}`;

S.search = () => `
  ${back('Search')}
  <div class="search">${ic('search')}<input id="q" placeholder="Merchant or note" autocomplete="off"></div>
  <div class="chips"><span class="chip on">Oct 1–15</span><span class="chip">Category</span><span class="chip">Amount ₹499</span><span class="chip">Card</span></div>
  <div id="results">${DATA.txns.map(txnRow).join('')}</div>`;

S.ask = () => `
  ${back('What was this?')}
  <div class="card" style="text-align:center"><div class="sub">Paid to</div><div class="big" style="margin:6px 0">RAJU STORES</div><div style="font-size:26px;font-weight:700;color:var(--red)">₹480</div><div class="sub" style="margin-top:6px">UPI · SBI •1190 · Yesterday 7:42 pm</div></div>
  <h2>Pick a category</h2>
  <div class="cats">${[['Food', 'food'], ['Shopping', 'bag'], ['Bills', 'doc'], ['Travel', 'car'], ['Groceries', 'bag'], ['Other', 'dots']].map((c, i) => `<button class="${i === 4 ? 'on' : ''}" data-cat>${ic(c[1])}${c[0]}</button>`).join('')}</div>
  <div class="search" style="margin-bottom:8px"><input placeholder="Purpose note (optional)"></div>
  <div class="check on" data-check><i>${ic('check', '')}</i>Always use this category for RAJU STORES</div>
  <div class="check" data-check><i>${ic('check', '')}</i>Hide this transaction (private vault)</div>
  <button class="btn" style="margin-top:14px" data-done="Saved. Rule created for RAJU STORES" data-go="activity">Save</button>`;

S.cards = () => `
  <div class="top"><h1 style="margin-left:0">Card vault</h1><button class="iconbtn" data-go="addcard">${ic('plus')}</button></div>
  <div class="note info">Only the last 4 digits are shown here. Full details need PIN or biometrics. CVV is never stored.</div>
  ${DATA.cards.map((c) => `<button class="row" data-go="card/${c.id}"><div class="ic tone-${c.color === 'dark' ? 'blue' : c.color === 'violet' ? 'violet' : 'blue'}">${ic('card')}</div><div class="mid"><div class="t">${c.bank} •••• ${c.last4}</div><div class="s">${c.type} card · ${c.network}</div></div>${ic('chevron', 'chev')}</button>`).join('')}
  <h2>Credit card bills</h2>
  ${DATA.cards.filter((c) => c.type === 'Credit').map((c) => `<div class="row"><div class="mid"><div class="t">${c.bank} •${c.last4}</div><div class="s">Statement ${c.statement} · Due ${c.due}</div><div class="prog"><i style="width:${Math.round((c.used / c.limit) * 100)}%"></i></div><div class="s">${inr(c.used)} of ${inr(c.limit)} limit</div></div><span class="pill">Pay</span></div>`).join('')}`;

let revealed = false;
S.card = (id) => {
  const c = DATA.cards.find((x) => x.id === id) || DATA.cards[0];
  return `${back(c.bank + ' •' + c.last4)}
  ${ccCard(c).replace(/data-go="[^"]*"/, '')}
  <div class="card" style="margin-top:18px;text-align:center"><div class="sub">Card number</div>
    <div class="reveal">${revealed ? c.full : '•••• •••• •••• ' + c.last4}</div>
    <div class="sub">${revealed ? 'Hides again in 45 seconds' : 'Locked'}</div>
    <button class="btn" style="margin-top:14px" data-reveal>${revealed ? 'Hide now' : 'Reveal with Face ID'}</button></div>
  <div class="note" style="margin-top:14px">Screenshots are blocked on this screen. The app switcher preview is blurred.</div>
  ${c.type === 'Credit' ? `<div class="row"><div class="mid"><div class="t">Bill reminder</div><div class="s">Statement ${c.statement} · Due ${c.due} · Remind 5 days and 1 day before</div></div><div class="switch on"></div></div><button class="btn ghost" data-go="billsetup">Edit bill reminder</button>` : ''}
  <div class="row"><div class="mid"><div class="t">Store card PIN</div><div class="s">Off. Banks may hold you liable if a stored PIN is misused.</div></div><div class="switch"></div></div>`;
};
S.addcard = () => `
  ${back('Add card')}
  <button class="row" data-done="NFC read: Visa •••• 5520" data-go="cards"><div class="ic tone-green">${ic('nfc')}</div><div class="mid"><div class="t">Tap card (Android NFC)</div><div class="s">Reads number and expiry</div></div>${ic('chevron', 'chev')}</button>
  <button class="row" data-done="Camera scan demo" data-go="cards"><div class="ic tone-violet">${ic('card')}</div><div class="mid"><div class="t">Scan with camera (iPhone)</div><div class="s">Or type the details yourself</div></div>${ic('chevron', 'chev')}</button>
  <div class="note info">Bank, card type, network and holder name are confirmed manually. For credit cards you will be asked for statement date, due date and reminders.</div>
  <button class="btn ghost" data-go="billsetup">Next: credit card bill reminder</button>`;

S.profile = () => `
  <div class="top"><h1 style="margin-left:0">Profile</h1></div>
  <div style="text-align:center;margin-bottom:20px"><div class="avatar" data-vault>S</div><div class="name" style="font-size:19px;font-weight:700">${DATA.user.name}</div><div class="sub">Paired with ${DATA.user.household}</div></div>
  <div class="menu">${[['SMS setup guide', 'doc', 'onboard'], ['Change PIN', 'lock', 'setpin'], ['Self transfers', 'transfer', 'selftransfers'], ['Household sharing', 'users', 'household'], ['Reports', 'report', 'reports'], ['Budgets', 'target', 'budgets'], ['Alerts', 'bell', 'alerts'], ['Encrypted backup', 'backup', 'backup'], ['Security', 'shield', 'security']].map((m) => `<button class="row" data-go="${m[2]}"><div class="ic">${ic(m[1])}</div><div class="mid"><div class="t">${m[0]}</div></div>${ic('chevron', 'chev')}</button>`).join('')}</div>`;

S.hidden = () => `
  ${back('Hidden vault', `<span class="pill ghost">${ic('lock')}</span>`)}
  <div class="note info">Unlocked with Face ID. These never appear in lists, charts, search, exports or household sharing.</div>
  <div class="card" style="margin-bottom:16px"><div class="sub">Hidden spend this month</div><div class="big" style="text-align:left;margin-top:6px">${inr(5470)}</div><div class="sub" style="margin-top:8px">True budget view: ${inr(DATA.spend + 5470)}</div></div>
  ${DATA.hidden.map((h) => `<div class="row"><div class="ic tone-red">${ic('eyeoff')}</div><div class="mid"><div class="t">${h.m}</div><div class="s">${h.date}</div></div><span class="amt neg">-${inr(h.amt)}</span></div>`).join('')}`;

S.selftransfers = () => `
  ${back('Self transfers')}
  <div class="note">These look like transfers between your own accounts. Confirm so they are left out of spending.</div>
  ${DATA.selfTransfers.map((s) => `<div class="card" style="margin-bottom:12px"><div style="display:flex;justify-content:space-between"><b>${inr(s.amount || s.amt)}</b><span class="sub">${s.date}</span></div><div style="font-size:13px;margin:6px 0">${s.from} → ${s.to}</div><div class="sub">${s.why}</div><div style="display:flex;gap:10px;margin-top:12px"><button class="pill" data-done="Marked as self transfer">Yes, mine</button><button class="pill ghost" data-done="Kept as spending">No, spending</button></div></div>`).join('')}`;

S.household = () => `
  ${back('Household')}
  <div class="card" style="display:flex;align-items:center;gap:14px;margin-bottom:16px"><div class="avatar" style="margin:0;width:52px;height:52px;font-size:20px">X</div><div style="flex:1"><div class="t" style="font-weight:700">${DATA.user.household}'s phone</div><div class="sub">Paired · last sync 10 min ago</div></div><span class="pill" data-done="Synced over Wi-Fi">Sync</span></div>
  <div class="note info">Sync is end-to-end encrypted over the same Wi-Fi. Only transactions marked shared are sent. Hidden ones never are.</div>
  <div class="card" style="margin-bottom:6px"><div class="sub">Household spend (shared categories)</div><div class="big" style="text-align:left;margin-top:6px">${inr(26119)}</div><div class="prog"><i style="width:58%"></i></div><div class="sub" style="margin-top:6px">58% of ₹45,000 home budget</div></div>
  <h2>Shared transactions</h2>
  ${DATA.household.map((h) => `<div class="row"><div class="ic tone-blue">${ic('users')}</div><div class="mid"><div class="t">${h.m}</div><div class="s">${h.who} · ${h.date}</div></div><span class="amt neg">-${inr(h.amt)}</span></div>`).join('')}
  <button class="btn ghost" data-done="QR pairing demo">Pair another phone (QR)</button>`;

S.reports = () => `
  ${back('Reports')}
  <div class="chips"><span class="chip on">October</span><span class="chip">September</span><span class="chip">Custom range</span></div>
  <div class="note">3 possible self transfers need confirming first. <b data-go="selftransfers" style="text-decoration:underline">Review</b></div>
  <div class="card" style="margin-bottom:6px"><div class="donut" style="width:130px;height:130px">${donut(DATA.categories, 130, 22).replace('<svg ', '<svg style="width:130px;height:130px" ')}</div>
    <div class="legend">${DATA.categories.map((c) => `<span><i style="background:${c.color}"></i>${c.name}</span>`).join('')}</div></div>
  <h2>Top merchants</h2>
  ${[['Amazon', 4998], ['Swiggy', 3120], ['BESCOM Electricity', 1840]].map((m, i) => `<div class="row"><div class="ic" style="background:var(--blue-soft);color:var(--blue);font-weight:700">${i + 1}</div><div class="mid"><div class="t">${m[0]}</div></div><span class="amt">${inr(m[1])}</span></div>`).join('')}
  <div style="display:flex;gap:10px"><button class="btn" data-done="PDF saved">PDF</button><button class="btn ghost" style="margin-top:0" data-done="CSV saved">CSV</button></div>`;

S.budgets = () => `${back('Budgets')}<div class="note info">Alerts fire once each at 70%, 80%, 90% and 100%.</div>${budgetRows('All')}<button class="btn" data-done="Budget form demo">Add budget</button>`;

S.alerts = () => `${back('Alerts')}${DATA.alerts.map((a) => `<div class="row"><div class="ic" style="background:var(--blue-soft);color:var(--blue)">${ic(a.icon)}</div><div class="mid"><div class="t">${a.t}</div><div class="s">${a.s}</div></div></div>`).join('')}
  <div class="note info">All alerts are local notifications. No server involved.</div>`;

S.backup = () => `${back('Encrypted backup')}<div class="note info">Cloud backups are excluded. Export a file protected by your own passphrase.</div><div class="search"><input type="password" placeholder="Passphrase" value="••••••••••"></div><button class="btn" data-done="Backup file created">Export backup</button><button class="btn ghost" data-done="Restore demo">Restore from file</button>`;

S.security = () => `${back('Security')}${[['App lock (PIN)', 1], ['Face ID / fingerprint', 1], ['Auto-lock after 1 minute', 1], ['Block screenshots on card screens', 1]].map((s) => `<div class="row"><div class="mid"><div class="t">${s[0]}</div></div><div class="switch ${s[1] ? 'on' : ''}"></div></div>`).join('')}
  <div class="note info">Main data and the hidden vault use separate encryption keys. Nothing leaves this phone.</div>`;


S.onboard = () => `
  <div class="lock" style="padding-top:40px"><div class="logo">${ic('shield')}</div><h1 style="font-size:22px">Read bank SMS on this phone</h1>
  <p class="sub" style="margin:8px 0 20px;line-height:1.5">Paisa Vault finds amount, merchant and card from new bank SMS so you do not type them.</p></div>
  <div class="row"><div class="ic tone-green">${ic('lock')}</div><div class="mid"><div class="t">Stays on your phone</div><div class="s">SMS are read by an on-device AI. Nothing is uploaded.</div></div></div>
  <div class="row"><div class="ic tone-blue">${ic('check')}</div><div class="mid"><div class="t">Only bank messages</div><div class="s">OTP and promotional SMS are ignored.</div></div></div>
  <div class="row"><div class="ic tone-violet">${ic('bell')}</div><div class="mid"><div class="t">New messages only</div><div class="s">Older SMS are not imported.</div></div></div>
  <button class="btn" style="margin-top:10px" data-done="SMS permission granted (demo)" data-go="setpin">Allow SMS access (Android)</button>
  <button class="btn ghost" data-go="shortcut">I use iPhone: set up Shortcut</button>`;

S.shortcut = () => `
  ${back('iPhone Shortcut setup')}
  <div class="note info">iPhone does not let apps read SMS. A one-time Shortcuts automation sends each new bank SMS to Paisa Vault.</div>
  ${[['Open Shortcuts, then Automation, then New, then Message'], ['Set "Message contains" to one keyword: debited, credited, spent, Rs or INR. Repeat per keyword.'], ['Choose "Run Immediately"'], ['Add the action "Log Bank Message" (Paisa Vault) with the message as input'], ['Done. New bank SMS are saved and processed when you next open the app.']].map((s, i) => `<div class="row"><div class="ic" style="background:var(--blue-soft);color:var(--blue);font-weight:700">${i + 1}</div><div class="mid"><div class="s" style="font-size:13px;color:var(--ink);margin:0;white-space:normal">${s[0]}</div></div></div>`).join('')}
  <div class="note">iOS may show a small "Shortcut ran" banner each time. This is normal.</div>
  <button class="btn" data-done="Setup marked done" data-go="setpin">I have set it up</button>`;

S.setpin = () => pinPad('Create your PIN', 'Choose a 4-digit PIN. You can add Face ID next.', false);

S.txn = (id) => {
  const t = DATA.txns.find((x) => x.id === +id) || DATA.txns[0];
  return `${back('Transaction')}
  <div class="card" style="text-align:center"><div class="sub">${t.amt < 0 ? 'Paid to' : 'Received from'}</div><div class="big" style="margin:6px 0">${t.m}</div>
    <div style="font-size:26px;font-weight:700;color:${t.amt < 0 ? 'var(--red)' : 'var(--blue)'}">${inr(t.amt, true)}</div><div class="sub" style="margin-top:6px">${t.sub} · ${t.date}</div></div>
  ${t.confirm ? `<div class="note" style="margin-top:14px">The AI could not match the amount to the SMS text. Please confirm it is right.</div><input class="field" value="1250" aria-label="Amount">` : ''}
  <h2>Category</h2>
  <div class="cats">${[['Food', 'food'], ['Shopping', 'bag'], ['Bills', 'doc'], ['Travel', 'car'], ['Groceries', 'bag'], ['Other', 'dots']].map((c) => `<button class="${c[0] === t.cat ? 'on' : ''}" data-cat>${ic(c[1])}${c[0]}</button>`).join('')}</div>
  <div class="search" style="margin-bottom:8px"><input placeholder="Purpose note (optional)"></div>
  <div class="check on" data-check><i>${ic('check')}</i>Always use this category for ${t.m}</div>
  <div class="check" data-check><i>${ic('check')}</i>Share with household</div>
  <div class="check" data-check><i>${ic('check')}</i>Hide this transaction (private vault)</div>
  <button class="btn" style="margin-top:14px" data-done="Transaction updated" data-go="activity">Save</button>`;
};

S.addtxn = () => `
  ${back('Add transaction')}
  <div class="chips"><span class="chip on" data-seg>Expense</span><span class="chip" data-seg>Income</span></div>
  <input class="field" placeholder="Amount (₹)" inputmode="decimal" aria-label="Amount">
  <input class="field" placeholder="Merchant or payee" aria-label="Merchant">
  <input class="field" value="Today" aria-label="Date">
  <input class="field" value="SBI •1190" aria-label="Account or card">
  <h2>Category</h2>
  <div class="cats">${[['Food', 'food'], ['Shopping', 'bag'], ['Bills', 'doc'], ['Travel', 'car'], ['Groceries', 'bag'], ['Other', 'dots']].map((c) => `<button data-cat>${ic(c[1])}${c[0]}</button>`).join('')}</div>
  <input class="field" placeholder="Purpose note (optional)" aria-label="Note">
  <button class="btn" style="margin-top:8px" data-done="Transaction added" data-go="activity">Save</button>`;

S.billsetup = () => `
  ${back('Credit card bill reminder')}
  <div class="note info">Set this up once so Paisa Vault can remind you before the due date. Reminders are local notifications.</div>
  <div class="sub" style="margin:4px 0 6px">Statement date</div><input class="field" value="18th of every month" aria-label="Statement date">
  <div class="sub" style="margin:4px 0 6px">Payment due date</div><input class="field" value="5th of every month" aria-label="Due date">
  <div class="sub" style="margin:4px 0 6px">Credit limit (optional)</div><input class="field" value="₹2,00,000" aria-label="Credit limit">
  <h2>Remind me</h2>
  <div class="chips"><span class="chip on" data-seg>5 days before</span><span class="chip on" data-seg>1 day before</span><span class="chip" data-seg>On the day</span></div>
  <button class="btn" style="margin-top:8px" data-done="Bill reminder saved" data-go="cards">Save</button>`;

/* ---------- router ---------- */
function render() {
  const [route, arg] = (location.hash.replace('#/', '') || 'lock').split('/');
  const fn = S[route] || S.home;
  const scr = $('#screen');
  scr.innerHTML = fn(arg);
  scr.className = 'screen fade';
  scr.scrollTop = 0;
  const showNav = !['lock', 'onboard', 'setpin'].includes(route);
  const active = NAV_ROUTES.includes(route) ? route : route === 'txn' || route === 'addtxn' ? 'activity' : route === 'card' || route === 'addcard' || route === 'billsetup' ? 'cards' : ['hidden', 'onboard', 'shortcut', 'setpin', 'selftransfers', 'household', 'reports', 'budgets', 'alerts', 'backup', 'security'].includes(route) ? 'profile' : '';
  const nav = $('#nav');
  nav.className = 'nav' + (showNav ? '' : ' hide');
  nav.innerHTML = NAV.map((n) => `<button class="${n[0] === active ? 'on' : ''}" data-go="${n[0]}" aria-label="${n[0]}">${ic(n[1])}</button>`).join('');
  bind(route);
}

function bind(route) {
  if (route === 'search') $('#q').addEventListener('input', (e) => {
    const q = e.target.value.toLowerCase();
    $('#results').innerHTML = DATA.txns.filter((t) => t.m.toLowerCase().includes(q) || t.cat.toLowerCase().includes(q)).map(txnRow).join('') || '<p class="sub">No matches.</p>';
  });
}

document.addEventListener('click', (e) => {
  const el = e.target.closest('[data-go],[data-key],[data-btab],[data-cat],[data-check],[data-reveal],[data-done],[data-seg]');
  if (!el) return;
  if (el.dataset.done) toast(el.dataset.done);
  if (el.dataset.key !== undefined) {
    const k = el.dataset.key;
    if (k === 'bio') pin = '1234'; else if (k === 'del') pin = pin.slice(0, -1); else if (pin.length < 4) pin += k;
    if (pin.length === 4) { pin = ''; return go('home'); }
    return render();
  }
  if (el.dataset.btab) { document.querySelectorAll('#btabs button').forEach((b) => b.classList.toggle('on', b === el)); $('#blist').innerHTML = budgetRows(el.dataset.btab); return; }
  if (el.dataset.cat !== undefined) { document.querySelectorAll('[data-cat]').forEach((b) => b.classList.toggle('on', b === el)); return; }
  if (el.dataset.check !== undefined || el.dataset.seg !== undefined) return el.classList.toggle('on');
  if (el.dataset.reveal !== undefined) { revealed = !revealed; return render(); }
  if (el.dataset.go) { if (el.dataset.back !== undefined) return history.length > 1 ? history.back() : go(el.dataset.go); go(el.dataset.go); }
});
// Hidden vault has no menu entry: long-press (or double-click) the profile avatar.
let lp;
document.addEventListener('pointerdown', (e) => { if (e.target.closest('[data-vault]')) lp = setTimeout(() => go('hidden'), 700); });
['pointerup', 'pointerleave', 'pointercancel'].forEach((ev) => document.addEventListener(ev, () => clearTimeout(lp)));
document.addEventListener('dblclick', (e) => { if (e.target.closest('[data-vault]')) go('hidden'); });
window.addEventListener('hashchange', render);
render();
