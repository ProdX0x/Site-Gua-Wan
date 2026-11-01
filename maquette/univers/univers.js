/* L'Univers de Guà Wàn : carte radiale des fiches, centrée sur « Vous ».
   Les données viennent de univers-data.js (window.UNIVERS), généré par scripts/construire-univers.py. */
(() => {
"use strict";

const DATA = window.UNIVERS;
const SVGNS = "http://www.w3.org/2000/svg";
const REDUCED = matchMedia("(prefers-reduced-motion: reduce)").matches;
const DUR = REDUCED ? 1 : 720;                     // déplacement des bulles (ms)
const ease = t => 1 - Math.pow(1 - t, 4);
const ease3 = t => 1 - Math.pow(1 - t, 3);

/* ——— Géométrie ———
   Les bulles sont rangées sur des anneaux concentriques. Chaque branche reçoit un secteur
   angulaire juste assez large pour que rien ne se chevauche ; s'il manque de place, tous
   les anneaux s'éloignent ensemble. Les fiches d'un salon s'ouvrent en éventail, sur
   plusieurs rangées décalées. */
const SIZE = { racine: 228, bloc: 196, branche: 150, carte: 128 };
const RINGS = [0, 330, 620, 900, 1180, 1460, 1740];
const GAP = 32;                        // espace minimal entre deux bulles voisines d'un anneau
const PITCH = SIZE.carte + 26;         // pas entre deux fiches d'une même rangée
const ROW_GAP = 150;                   // pas entre deux rangées de fiches
const MAX_ROWS = 4, PER_ROW = 5;
const Z_MIN = 0.05, Z_MAX = 2.4, Z_FIT_MAX = 1;
const BS_REF = 0.62, BS_MAX = 1.16;    // les bulles grossissent un peu quand on dézoome, pour rester lisibles
let ringScale = 1;
const ringR = d => (RINGS[Math.min(d, RINGS.length - 1)] + Math.max(0, d - RINGS.length + 1) * 280) * ringScale;

/* ——— Icônes (trait fin, 24 × 24) ——— */
const ICONS = {
  esprit: '<path d="M12 20c-4.2 0-7.4-2.6-8.4-6.3 2.7 0 5.2 1.1 6.8 3.1"/><path d="M12 20c4.2 0 7.4-2.6 8.4-6.3-2.7 0-5.2 1.1-6.8 3.1"/><path d="M12 20c-2.2-2.1-3.3-5-3.3-8.2 0-3 1.2-5.6 3.3-7.6 2.1 2 3.3 4.6 3.3 7.6 0 3.2-1.1 6.1-3.3 8.2z"/>',
  creation: '<path d="M12 3.5l1.9 5.2 5.3 1.9-5.3 1.9L12 17.7l-1.9-5.2-5.3-1.9 5.3-1.9z"/><path d="M18.5 15.5v4M16.5 17.5h4"/>',
  corps: '<circle cx="12" cy="4.8" r="2"/><path d="M12 7.5v6.2M12 13.7l-3.3 6.8M12 13.7l3.3 6.8M5.8 10.4 12 9l6.2 1.4"/>',
  sensualite: '<circle cx="12" cy="12" r="1.8"/><path d="M12 10c-2-1.5-2.5-4.5 0-6.5 2.5 2 2 5 0 6.5zM13.9 11.4c.8-2.4 3.6-3.7 6.4-2.1-.9 3.1-3.8 4-6.4 2.1zM13.2 13.7c2.5 0 4.6 2.2 3.9 5.3-3.2.2-4.6-2.5-3.9-5.3zM10.8 13.7c.7 2.8-.7 5.5-3.9 5.3-.7-3.1 1.4-5.3 3.9-5.3zM10.1 11.4c-2.6 1.9-5.5 1-6.4-2.1 2.8-1.6 5.6-.3 6.4 2.1z"/>',
  verrou: '<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8.5 10.5V7.5a3.5 3.5 0 0 1 7 0v3M12 14.5v2.5"/>',
  philo: '<circle cx="12" cy="12" r="8.5"/><path d="M12 3.5a4.25 4.25 0 0 1 0 8.5 4.25 4.25 0 0 0 0 8.5"/><circle cx="12" cy="7.75" r="1" class="fill"/><circle cx="12" cy="16.25" r="1"/>',
  spiritualites: '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.4 2.3 3.6 5.1 3.6 8.5s-1.2 6.2-3.6 8.5c-2.4-2.3-3.6-5.1-3.6-8.5S9.6 5.8 12 3.5z"/>',
  textes: '<path d="M12 6.8C10.2 5.4 7.6 4.8 4 4.8v13.4c3.6 0 6.2.6 8 2 1.8-1.4 4.4-2 8-2V4.8c-3.6 0-6.2.6-8 2zM12 6.8v13.4"/>',
  meditation: '<circle cx="12" cy="12" r="1.7" class="fill"/><circle cx="12" cy="12" r="5"/><path d="M4.2 9.2a8.5 8.5 0 0 1 15.6 0M19.8 14.8a8.5 8.5 0 0 1-15.6 0"/>',
  mythes: '<path d="M19 14.6A7.6 7.6 0 1 1 9.4 5a6 6 0 0 0 9.6 9.6z"/><path d="M17 3.5l.7 1.8 1.8.7-1.8.7-.7 1.8-.7-1.8-1.8-.7 1.8-.7z"/>',
  ethique: '<path d="M12 4v16M8 20h8M5 7.5h14"/><path d="M5 7.5 2.6 13a2.6 2.6 0 0 0 4.8 0zM19 7.5 16.6 13a2.6 2.6 0 0 0 4.8 0z"/>',
  sciences: '<path d="M9.5 3.5h5M10.5 3.5v5.2l-5 8.6a2.2 2.2 0 0 0 1.9 3.2h9.2a2.2 2.2 0 0 0 1.9-3.2l-5-8.6V3.5M7.6 14.5h8.8"/>',
  cosmos: '<circle cx="12" cy="12" r="3"/><ellipse cx="12" cy="12" rx="9.5" ry="3.8" transform="rotate(-28 12 12)"/><circle cx="19.3" cy="7.6" r="1" class="fill"/>',
  arts: '<path d="M12 3.5a8.5 8.5 0 1 0 0 17c1.1 0 1.8-.8 1.8-1.8 0-.5-.2-.9-.5-1.2-.3-.4-.5-.8-.5-1.2 0-1 .8-1.8 1.8-1.8h2.1a4.3 4.3 0 0 0 4.3-4.3c0-3.6-4-6.7-9-6.7z"/><circle cx="7.6" cy="11" r="1" class="fill"/><circle cx="9.6" cy="7.4" r="1" class="fill"/><circle cx="14.2" cy="7.2" r="1" class="fill"/>',
  musique: '<path d="M9 17.5V5.5l10.5-2v12"/><circle cx="6.5" cy="17.5" r="2.5"/><circle cx="17" cy="15.5" r="2.5"/>',
  ecriture: '<path d="M4 20h7"/><path d="M15.8 4.2a2.3 2.3 0 0 1 3.3 3.3L8.6 18l-4.4 1.1 1.1-4.4z"/>',
  cinema: '<rect x="3.5" y="4.5" width="17" height="15" rx="2.5"/><path d="M7.5 4.5v15M16.5 4.5v15M3.5 9.5h4M3.5 14.5h4M16.5 9.5h4M16.5 14.5h4"/>',
  ia: '<rect x="6.5" y="6.5" width="11" height="11" rx="2.5"/><path d="M9.5 3v3.5M14.5 3v3.5M9.5 17.5V21M14.5 17.5V21M3 9.5h3.5M3 14.5h3.5M17.5 9.5H21M17.5 14.5H21M10 14l2-4 2 4M10.6 12.8h2.8"/>',
  gout: '<path d="M4.5 9.5h12v3.8a5.7 5.7 0 0 1-5.7 5.7h-.6a5.7 5.7 0 0 1-5.7-5.7z"/><path d="M16.5 10.5h1.3a2.4 2.4 0 0 1 0 4.8h-1.6M8.5 3.5c0 1.4 1 1.6 1 3M12.5 3.5c0 1.4 1 1.6 1 3"/>',
  odorat: '<path d="M12 21v-7M8.5 21h7M12 14c-2.6-1.4-2.6-4 0-5.4s2.6-4 0-5.6"/>',
  toucher: '<path d="M7.2 18.5A11 11 0 0 1 6 13a6 6 0 0 1 12 0c0 1.2-.1 2.4-.4 3.5M9.6 20.2A15 15 0 0 1 8.7 13a3.3 3.3 0 0 1 6.6 0c0 2.2-.3 4.3-.9 6.3M12 13c0 3.1.5 5.8 1.4 8"/>',
  ouie: '<path d="M4 9.5v5h3.5L12.5 18V6L7.5 9.5z"/><path d="M15.8 9.2a4 4 0 0 1 0 5.6M18.4 6.6a7.6 7.6 0 0 1 0 10.8"/>',
  vue: '<path d="M2.5 12S6 5.8 12 5.8 21.5 12 21.5 12 18 18.2 12 18.2 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/>',
  audela: '<path d="M12 12c-1.9-2.6-3.5-4-5.7-4a4 4 0 0 0 0 8c2.2 0 3.8-1.4 5.7-4zm0 0c1.9 2.6 3.5 4 5.7 4a4 4 0 0 0 0-8c-2.2 0-3.8 1.4-5.7 4z"/>',
  mouvement: '<path d="M3 12h3.5L9 5.5l4.5 13 2.6-6.5H21"/>',
  soin: '<path d="M5.5 18.5C5.5 10.5 10.5 4.8 19.5 4.5c0 9.2-5.6 14.5-13.5 14.3zM5.5 18.5c2.8-4.4 5.9-7.2 9.5-9"/>',
  point: '<circle cx="12" cy="12" r="3"/>',
  informer: '<path d="M5 6h11v12.5H6.8A1.8 1.8 0 0 1 5 16.7z"/><path d="M16 9h3v7.7a1.8 1.8 0 0 1-3.6 0M8 9.5h5M8 12.5h5M8 15.5h3"/>',
  eduquer: '<path d="M2.5 9 12 4.5 21.5 9 12 13.5z"/><path d="M6.5 11v4.6c3 2.4 8 2.4 11 0V11M21.5 9v5"/>',
  pratique: '<path d="M12 21v-7M12 14c0-3.5 2.5-6 6.5-6 0 3.5-2.5 6-6.5 6zM12 12c0-3-2.2-5.2-5.6-5.2 0 3 2.2 5.2 5.6 5.2z"/>',
  play: '<circle cx="12" cy="12" r="8.5"/><path d="M10.2 8.8v6.4l5.2-3.2z" class="fill"/>',
  externe: '<path d="M14 4.5h5.5V10M19.5 4.5 11 13M17 14v4.2a1.3 1.3 0 0 1-1.3 1.3H5.8a1.3 1.3 0 0 1-1.3-1.3V8.3A1.3 1.3 0 0 1 5.8 7H10"/>',
  lien: '<path d="M10 14a4 4 0 0 0 5.7 0l3-3A4 4 0 0 0 13 5.3l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3A4 4 0 0 0 11 18.7l1-1"/>',
  soleil: '<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"/>',
  lune: '<path d="M19.5 14.5A8 8 0 1 1 9.5 4.5a6.3 6.3 0 0 0 10 10z"/>',
  idee: '<path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-3.6 10.8c.7.6 1.1 1.3 1.1 2.2h5c0-.9.4-1.6 1.1-2.2A6 6 0 0 0 12 3z"/>',
  partager: '<circle cx="18" cy="5.5" r="2.5"/><circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="18.5" r="2.5"/><path d="M8.2 10.8l7.6-4.1M8.2 13.2l7.6 4.1"/>',
  plein: '<path d="M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5"/>',
  info: '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5.5"/><circle cx="12" cy="7.8" r="1" class="fill"/>',
  chevron: '<path d="M6 9l6 6 6-6"/>',
  region: '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.4 2.3 3.6 5.1 3.6 8.5s-1.2 6.2-3.6 8.5c-2.4-2.3-3.6-5.1-3.6-8.5S9.6 5.8 12 3.5z"/>',
  mission: '<path d="M5 21V4h11l-2 4 2 4H5"/>',
  x: '<path d="M6 6l12 12M18 6 6 18"/>',
};
const icon = (name, cls = "") => `<svg class="ico ${cls}" viewBox="0 0 24 24" aria-hidden="true">${ICONS[name] || ICONS.point}</svg>`;
const esc = s => String(s ?? "").replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const $ = id => document.getElementById(id);

/* ——— Arbre ——— */
const root = DATA.arbre;
const nodes = [], byId = new Map();
(function flatten(n, parent, depth) {
  const isCard = depth > 0 && !Array.isArray(n.children) && !n.verrou;
  n.children = n.children || [];
  n.parent = parent; n.depth = depth;
  n.kind = depth === 0 ? "racine" : isCard ? "carte" : depth === 1 ? "bloc" : "branche";
  n.couleur = n.couleur || (parent ? parent.couleur : "racine");
  n.icon = n.icon || (parent && parent.icon) || "point";
  n.size = SIZE[n.kind];
  n.ancestors = parent ? [...parent.ancestors, parent] : [];
  if (byId.has(n.id)) n.id += "-" + depth;
  n.expanded = false; n.vis = false;
  n.x = n.y = n.tx = n.ty = 0; n.s = n.ts = 0.3; n.o = n.to = 0;
  nodes.push(n); byId.set(n.id, n);
  n.children.forEach(c => flatten(c, n, depth + 1));
  n.leaves = isCard ? 1 : n.children.reduce((s, c) => s + c.leaves, 0);
})(root, null, 0);
const cards = nodes.filter(n => n.kind === "carte");
const canOpen = n => n.kind !== "carte" && n.children.length > 0;
const cardFan = n => n.children[0] && n.children[0].kind === "carte";

/* ——— Placement ——— */
function measure(n) {
  const own = n.depth ? (n.size + GAP) / ringR(n.depth) : 0;
  if (!n.expanded || !canOpen(n)) return (n.need = own);
  if (cardFan(n)) {
    const k = n.children.length;
    n.rows = Math.min(MAX_ROWS, Math.ceil(k / PER_ROW));
    n.perRow = Math.ceil(k / n.rows);
    n.step = PITCH / ringR(n.depth + 1);
    return (n.need = Math.max(own, (n.perRow + (n.rows > 1 ? 0.5 : 0)) * n.step));
  }
  return (n.need = Math.max(own, n.children.reduce((s, c) => s + measure(c), 0)));
}

/* Parts égales pour tous, sauf pour qui a besoin de plus : les secteurs restent stables
   tant qu'une branche ouverte ne réclame pas davantage de place. */
function share(needs, total) {
  const fixed = new Set();
  for (;;) {
    const free = needs.map((_, i) => i).filter(i => !fixed.has(i));
    if (!free.length) {
      const sum = needs.reduce((s, v) => s + v, 0) || 1;
      return needs.map(v => v * total / sum);
    }
    const each = (total - [...fixed].reduce((s, i) => s + needs[i], 0)) / free.length;
    const over = free.filter(i => needs[i] > each + 1e-9);
    if (!over.length) return needs.map((v, i) => fixed.has(i) ? v : each);
    over.forEach(i => fixed.add(i));
  }
}

function place(n, a0, a1) {
  n.angle = (a0 + a1) / 2;
  const r = ringR(n.depth);
  n.tx = r * Math.cos(n.angle); n.ty = r * Math.sin(n.angle);
  if (!n.expanded || !canOpen(n)) return;
  if (cardFan(n)) return placeCards(n);
  const parts = share(n.children.map(c => c.need), a1 - a0);
  let a = a0;
  n.children.forEach((c, i) => { place(c, a, a + parts[i]); a += parts[i]; });
}

function placeCards(n) {
  const k = n.children.length, r0 = ringR(n.depth + 1), stagger = n.rows > 1 ? 0.25 : 0;
  n.children.forEach((c, i) => {
    const row = Math.floor(i / n.perRow), col = i % n.perRow;
    const inRow = Math.min(n.perRow, k - row * n.perRow);
    c.angle = n.angle + (col - (inRow - 1) / 2 + (row % 2 ? stagger : -stagger)) * n.step;
    const r = r0 + row * ROW_GAP;
    c.tx = r * Math.cos(c.angle); c.ty = r * Math.sin(c.angle);
  });
}

function layout() {
  nodes.forEach(n => { n.vis = !n.parent || (n.parent.vis && n.parent.expanded); });
  ringScale = 1;
  const room = Math.PI * 2 * 0.96;
  const need = measure(root);
  if (need > room) { ringScale = need / room; measure(root); }
  root.tx = root.ty = 0;
  if (root.expanded) {
    const parts = share(root.children.map(c => c.need), Math.PI * 2);
    let a = -Math.PI / 2 - parts[0] / 2;              // le premier bloc trône en haut
    root.children.forEach((c, i) => { place(c, a, a + parts[i]); a += parts[i]; });
  }
  // Une bulle cachée se replie dans son plus proche parent visible.
  nodes.forEach(n => {
    if (n.vis) { n.ts = 1; n.to = 1; return; }
    let a = n.parent;
    while (!a.vis) a = a.parent;
    n.tx = a.tx; n.ty = a.ty; n.ts = 0.3; n.to = 0;
  });
}

/* ——— DOM ——— */
const $viewport = $("viewport"), $world = $("world"), $links = $("linkLayer"), $tips = $("tipLayer"), $orbits = $("orbits");

function ariaOf(n) {
  if (n.kind === "carte") return `${n.label}. Ouvrir la fiche.`;
  if (n.verrou) return `${n.label}, fermé. ${n.verrou}`;
  if (n.aVenir) return `${n.label}, à venir.`;
  if (n.kind === "racine") return `${n.label} : ${n.sousTitre}`;
  return `${n.label}, ${n.leaves} fiche${n.leaves > 1 ? "s" : ""}`;
}

function makeNode(n) {
  const el = document.createElement("div");
  el.className = `node k-${n.kind}${n.verrou ? " is-locked" : ""}${n.aVenir ? " is-soon" : ""} is-gone`;
  el.dataset.id = n.id;
  el.dataset.c = n.couleur;
  el.style.setProperty("--size", n.size + "px");
  const label = esc(n.kind === "carte" ? n.court || n.label : n.label);
  let inner;
  if (n.kind === "racine") {
    inner = `<svg class="enso" viewBox="0 0 120 120" aria-hidden="true"><path class="enso-stroke draw" d="M101.4 45 A44 44 0 1 0 103.3 67.6" pathLength="100"/></svg>`
      + `<span class="root-dot"></span><span class="root-word">${label}</span><span class="root-tag">${esc(n.sousTitre)}</span>`;
  } else if (n.kanji) {
    inner = `<span class="n-kanji" aria-hidden="true">${esc(n.kanji)}</span><span class="n-label">${label}</span>`;
  } else {
    const sub = n.verrou ? n.sousTitre || "Fermé" : n.aVenir ? "À venir" : n.sousTitre;
    inner = `<span class="n-icon">${icon(n.verrou ? "verrou" : n.icon)}</span><span class="n-label">${label}</span>`
      + (sub ? `<span class="n-sub">${esc(sub)}</span>` : "");
  }
  const title = n.kind === "carte" && n.court !== n.label ? ` title="${esc(n.label)}"` : "";
  el.innerHTML = `<div class="bubble" role="button" tabindex="-1" aria-label="${esc(ariaOf(n))}"${title}>${inner}</div>`
    + (canOpen(n) ? `<span class="badge" aria-hidden="true"></span>` : "");
  n.el = el;
  n.bubble = el.firstElementChild;
  n.badge = el.querySelector(".badge");
  $world.appendChild(el);
  paint(n);
}

function makeLink(n) {
  const p = document.createElementNS(SVGNS, "path");
  p.setAttribute("pathLength", "1");
  p.setAttribute("d", "M0 0");
  p.dataset.c = n.couleur;
  p.classList.add("is-gone");
  n.link = p;
  $links.appendChild(p);
}

function paint(n) {
  n.el.style.transform = `translate(${n.x.toFixed(1)}px,${n.y.toFixed(1)}px) scale(${n.s.toFixed(3)})`;
  n.el.style.opacity = n.o.toFixed(3);
}

const unit = (x, y) => { const l = Math.hypot(x, y) || 1; return [x / l, y / l]; };
const r1 = v => Math.round(v * 10) / 10;
/* Trait courbe : il quitte la bulle mère dans l'axe du rayonnement et rejoint la fille par l'intérieur. */
function linkPath(p, c) {
  const dx = c.x - p.x, dy = c.y - p.y, L = Math.hypot(dx, dy);
  const rp = p.size / 2 * p.s * bs + 4, rc = c.size / 2 * c.s * bs + 4;
  if (L < rp + rc + 2) return "M0 0";
  const ux = dx / L, uy = dy / L;
  const x1 = p.x + ux * rp, y1 = p.y + uy * rp, x2 = c.x - ux * rc, y2 = c.y - uy * rc;
  const k = (L - rp - rc) * 0.42;
  const [px, py] = p.depth ? unit(p.x, p.y) : [ux, uy];
  const [cx, cy] = unit(c.x, c.y);
  return `M${r1(x1)} ${r1(y1)}C${r1(x1 + px * k)} ${r1(y1 + py * k)} ${r1(x2 - cx * k)} ${r1(y2 - cy * k)} ${r1(x2)} ${r1(y2)}`;
}

/* ——— Animation : une seule boucle pour les bulles, les traits, les orbites et la caméra ——— */
const moving = new Set(), drawing = new Set();
let orbits = [], cam = null, raf = 0;
const kick = () => { if (!raf) raf = requestAnimationFrame(frame); };

function tween(n, delay, now) {
  const showing = n.to === 1 && n.o < 0.02;
  if (!n.anim && n.x === n.tx && n.y === n.ty && n.s === n.ts && n.o === n.to) return;
  n.anim = { fx: n.x, fy: n.y, fs: n.s, fo: n.o, t0: now + delay };
  moving.add(n);
  if (n.to > 0) n.el.classList.remove("is-gone");
  if (!n.link) return;
  if (showing) startDraw(n, delay, now);
  else if (n.to === 0) stopDraw(n, true);
}

function startDraw(n, delay, now) {
  stopDraw(n, false);
  const L = Math.max(0, Math.hypot(n.tx - n.parent.tx, n.ty - n.parent.ty) - (n.size + n.parent.size) / 2);
  n.draw = { t0: now + delay + 60, dur: REDUCED ? 1 : Math.min(900, 420 + L * 0.35), tip: null };
  n.link.style.strokeDasharray = "1 1";
  n.link.style.strokeDashoffset = "1";
  n.link.classList.remove("is-gone");
  drawing.add(n);
}

function stopDraw(n, hide) {
  if (n.draw) {
    if (n.draw.tip) n.draw.tip.remove();
    n.draw = null;
    drawing.delete(n);
  }
  n.link.style.strokeDasharray = "";
  n.link.style.strokeDashoffset = "";
  if (hide) n.link.classList.add("is-gone");
}

function frame(now) {
  raf = 0;
  for (const n of moving) {
    const a = n.anim;
    const t = Math.min(1, Math.max(0, (now - a.t0) / DUR));
    const e = ease(t);
    n.x = a.fx + (n.tx - a.fx) * e;
    n.y = a.fy + (n.ty - a.fy) * e;
    n.s = a.fs + (n.ts - a.fs) * e;
    n.o = a.fo + (n.to - a.fo) * Math.min(1, t * (n.to ? 1.6 : 2.2));
    paint(n);
    if (t >= 1) {
      moving.delete(n);
      n.anim = null;
      if (n.to === 0) n.el.classList.add("is-gone");
    }
  }
  for (const n of nodes) {
    if (n.link && (n.o > 0 || n.anim)) n.link.setAttribute("d", linkPath(n.parent, n));
  }
  for (const n of drawing) {
    const d = n.draw;
    const t = Math.min(1, Math.max(0, (now - d.t0) / d.dur));
    const e = ease3(t);
    n.link.style.strokeDashoffset = String(1 - e);
    if (t > 0 && !d.tip) {
      d.tip = document.createElementNS(SVGNS, "circle");
      d.tip.setAttribute("class", "tip");
      d.tip.dataset.c = n.couleur;
      $tips.appendChild(d.tip);
    }
    if (d.tip) {
      const len = n.link.getTotalLength();
      const pt = len ? n.link.getPointAtLength(len * e) : { x: n.x, y: n.y };
      d.tip.setAttribute("cx", r1(pt.x));
      d.tip.setAttribute("cy", r1(pt.y));
      d.tip.setAttribute("r", r1(4.5 / view.z));
    }
    if (t >= 1) {
      const tip = d.tip;
      drawing.delete(n);
      n.draw = null;
      n.link.style.strokeDasharray = "";
      n.link.style.strokeDashoffset = "";
      if (tip) { tip.classList.add("is-out"); setTimeout(() => tip.remove(), 500); }
    }
  }
  let orbitMoving = false;
  for (const o of orbits) {
    const t = Math.min(1, Math.max(0, (now - o.t0) / DUR));
    o.r = o.fr + (o.tr - o.fr) * ease(t);
    o.el.setAttribute("r", r1(o.r));
    if (t < 1) orbitMoving = true;
  }
  if (cam) {
    const t = Math.min(1, (now - cam.t0) / cam.dur);
    const e = ease(t);
    const z = Math.exp(Math.log(cam.fz) + (Math.log(cam.tz) - Math.log(cam.fz)) * e);
    const cx = cam.fc[0] + (cam.tc[0] - cam.fc[0]) * e, cy = cam.fc[1] + (cam.tc[1] - cam.fc[1]) * e;
    view.z = z; view.x = cam.sx - cx * z; view.y = cam.sy - cy * z;
    applyView();
    if (t >= 1) cam = null;
  }
  if (moving.size || drawing.size || orbitMoving || cam) kick();
}

/* ——— Rendu après chaque changement d'ouverture ——— */
function render(cascade) {
  layout();
  const now = performance.now();
  const order = new Map();
  nodes.forEach(n => {
    let delay = 0;
    if (cascade) delay = cascade(n, order);
    else if (n.to === 1 && n.o < 0.02 && n.parent) delay = Math.min(280, n.parent.children.indexOf(n) * 24);
    tween(n, delay, now);
    n.bubble.tabIndex = n.vis ? 0 : -1;
    if (canOpen(n)) {
      n.bubble.setAttribute("aria-expanded", String(n.expanded));
      n.el.classList.toggle("is-open", n.expanded);
      if (n.badge) n.badge.textContent = n.expanded ? "−" : n.leaves ? String(n.leaves) : "à venir";
    }
  });
  updateOrbits(now);
  updateActionButtons();
  if (filter) paintFilter();
  kick();
}

function updateOrbits(now) {
  const depths = new Set(nodes.filter(n => n.vis && n.depth && n.kind !== "carte").map(n => n.depth));
  const want = [...depths].sort((a, b) => a - b).map(ringR);
  while (orbits.length < want.length) {
    const el = document.createElementNS(SVGNS, "circle");
    el.setAttribute("cx", 0); el.setAttribute("cy", 0); el.setAttribute("r", 0);
    $orbits.appendChild(el);
    orbits.push({ el, r: 0, fr: 0, tr: 0, t0: now });
  }
  orbits.forEach((o, i) => {
    o.fr = o.r; o.tr = want[i] || 0; o.t0 = now;
    o.el.style.opacity = want[i] ? "" : "0";
  });
}

/* ——— Caméra ——— */
const view = { x: 0, y: 0, z: 1 };
let bs = 1, userMoved = false;

function applyView() {
  $world.style.transform = `translate(${view.x.toFixed(1)}px,${view.y.toFixed(1)}px) scale(${view.z.toFixed(4)})`;
  const nbs = Math.round(Math.min(BS_MAX, Math.max(1, Math.sqrt(BS_REF / view.z))) * 100) / 100;
  if (nbs !== bs) {
    bs = nbs;
    $world.style.setProperty("--bs", bs);
    nodes.forEach(n => { if (n.link && n.o > 0) n.link.setAttribute("d", linkPath(n.parent, n)); });
  }
  $links.style.strokeWidth = (1.6 / view.z).toFixed(2) + "px";
  $orbits.style.strokeWidth = (1 / view.z).toFixed(2) + "px";
  $orbits.style.strokeDasharray = `${(1.5 / view.z).toFixed(2)} ${(9 / view.z).toFixed(2)}`;
}

function area() {
  const top = document.querySelector(".topbar").getBoundingClientRect().bottom + 18;
  const narrow = innerWidth <= 720;
  return { l: 16, t: top, r: innerWidth - (narrow ? 64 : 82), b: innerHeight - (narrow ? 70 : 86) };
}
const clampZ = z => Math.min(Z_MAX, Math.max(Z_MIN, z));

function camTo(x, y, z, animate = true) {
  z = clampZ(z);
  if (!animate || REDUCED) { cam = null; view.x = x; view.y = y; view.z = z; applyView(); return; }
  const A = area(), sx = (A.l + A.r) / 2, sy = (A.t + A.b) / 2;
  cam = {
    t0: performance.now(), dur: 760, sx, sy, fz: view.z, tz: z,
    fc: [(sx - view.x) / view.z, (sy - view.y) / view.z],
    tc: [(sx - x) / z, (sy - y) / z],
  };
  kick();
}

function bbox(list) {
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  list.forEach(n => {
    const r = n.size / 2 * BS_MAX + 14;
    x0 = Math.min(x0, n.tx - r); x1 = Math.max(x1, n.tx + r);
    y0 = Math.min(y0, n.ty - r); y1 = Math.max(y1, n.ty + r);
  });
  return { x0, y0, x1, y1 };
}

function fitTo(list, animate = true, maxZ = Z_FIT_MAX) {
  if (!list.length) return;
  const b = bbox(list), A = area();
  const z = clampZ(Math.min((A.r - A.l) / (b.x1 - b.x0), (A.b - A.t) / (b.y1 - b.y0), maxZ));
  camTo((A.l + A.r) / 2 - (b.x0 + b.x1) / 2 * z, (A.t + A.b) / 2 - (b.y0 + b.y1) / 2 * z, z, animate);
}
const fitVisible = (animate = true) => fitTo(nodes.filter(n => n.to === 1), animate);

/* Après une ouverture : glisser juste ce qu'il faut pour voir la bulle et ses filles, ou dézoomer si besoin. */
function ensureVisible(n) {
  const list = [n, ...n.children.filter(c => c.to === 1)];
  const b = bbox(list), A = area();
  const v = cam ? { z: cam.tz, x: cam.sx - cam.tc[0] * cam.tz, y: cam.sy - cam.tc[1] * cam.tz } : view;
  const sx0 = b.x0 * v.z + v.x, sx1 = b.x1 * v.z + v.x, sy0 = b.y0 * v.z + v.y, sy1 = b.y1 * v.z + v.y;
  if (sx1 - sx0 > A.r - A.l || sy1 - sy0 > A.b - A.t) return fitTo(list);
  let dx = 0, dy = 0;
  if (sx0 < A.l) dx = A.l - sx0; else if (sx1 > A.r) dx = A.r - sx1;
  if (sy0 < A.t) dy = A.t - sy0; else if (sy1 > A.b) dy = A.b - sy1;
  if (dx || dy) camTo(v.x + dx, v.y + dy, v.z);
}

function zoomAt(sx, sy, factor) {
  cam = null;
  const z = clampZ(view.z * factor);
  view.x = sx - (sx - view.x) * z / view.z;
  view.y = sy - (sy - view.y) * z / view.z;
  view.z = z;
  userMoved = true;
  applyView();
}
function zoomBy(factor) {
  const A = area(), sx = (A.l + A.r) / 2, sy = (A.t + A.b) / 2;
  const z = clampZ(view.z * factor);
  userMoved = true;
  camTo(sx - (sx - view.x) * z / view.z, sy - (sy - view.y) * z / view.z, z);
}

/* ——— Glisser, pincer, molette ——— */
const pointers = new Map();
let dragMoved = 0, pinch = null;

$viewport.addEventListener("pointerdown", e => {
  if (e.pointerType === "mouse" && e.button !== 0) return;
  try { $viewport.setPointerCapture(e.pointerId); } catch (_) { /* pointeur déjà relâché */ }
  pointers.set(e.pointerId, { x: e.clientX, y: e.clientY, target: e.target });
  if (pointers.size === 1) { dragMoved = 0; cam = null; }
  if (pointers.size === 2) {
    const [a, b] = [...pointers.values()];
    pinch = { d: Math.hypot(a.x - b.x, a.y - b.y), mx: (a.x + b.x) / 2, my: (a.y + b.y) / 2 };
    dragMoved = 99;
  }
});
$viewport.addEventListener("pointermove", e => {
  const p = pointers.get(e.pointerId);
  if (!p) return;
  const dx = e.clientX - p.x, dy = e.clientY - p.y;
  p.x = e.clientX; p.y = e.clientY;
  if (pointers.size === 1) {
    dragMoved += Math.abs(dx) + Math.abs(dy);
    if (dragMoved > 4) {
      $viewport.classList.add("is-dragging");
      view.x += dx; view.y += dy; userMoved = true;
      applyView();
    }
  } else if (pointers.size === 2 && pinch) {
    const [a, b] = [...pointers.values()];
    const d = Math.hypot(a.x - b.x, a.y - b.y), mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2;
    view.x += mx - pinch.mx; view.y += my - pinch.my;
    zoomAt(mx, my, d / (pinch.d || d));
    pinch = { d, mx, my };
  }
});
function endPointer(e) {
  const p = pointers.get(e.pointerId);
  pointers.delete(e.pointerId);
  if (pointers.size < 2) pinch = null;
  $viewport.classList.remove("is-dragging");
  if (!p || pointers.size > 0) return;
  if (dragMoved <= 4 && e.type === "pointerup") {
    const el = p.target.closest && p.target.closest(".node");
    if (el) onNodeClick(byId.get(el.dataset.id));
  }
}
$viewport.addEventListener("pointerup", endPointer);
$viewport.addEventListener("pointercancel", endPointer);

let wheelAcc = 0, wheelX = 0, wheelY = 0, wheelRaf = 0;
$viewport.addEventListener("wheel", e => {
  e.preventDefault();
  const unitPx = e.deltaMode === 1 ? 32 : e.deltaMode === 2 ? innerHeight : 1;
  wheelAcc += e.deltaY * unitPx * (e.ctrlKey ? 6 : 1);    // pincement du pavé tactile : ctrlKey
  wheelX = e.clientX; wheelY = e.clientY;
  if (!wheelRaf) wheelRaf = requestAnimationFrame(() => {
    zoomAt(wheelX, wheelY, Math.exp(-wheelAcc * 0.0016));
    wheelAcc = 0; wheelRaf = 0;
  });
}, { passive: false });

$viewport.addEventListener("keydown", e => {
  const b = e.target.closest && e.target.closest(".bubble");
  if (b && (e.key === "Enter" || e.key === " ")) {
    e.preventDefault();
    onNodeClick(byId.get(b.parentElement.dataset.id));
  }
});
$viewport.addEventListener("focusin", e => {
  const b = e.target.closest && e.target.closest(".bubble");
  if (b && e.target.matches(":focus-visible")) ensureVisible(byId.get(b.parentElement.dataset.id));
});

/* ——— Clic sur une bulle ——— */
function onNodeClick(n) {
  if (!n) return;
  hideHint();
  if (n.kind === "carte") return openCard(n);
  if (n.verrou) return toast(`${n.label} · ${n.verrou}`);
  if (n.aVenir) return toast(`${n.label} · ${n.aVenir}`);
  clearFilter();
  n.expanded = !n.expanded;
  if (!n.expanded) n.children.forEach(function close(c) { c.expanded = false; c.children.forEach(close); });
  render();
  if (n.expanded) ensureVisible(n);
}

function setInitialOpen() {
  nodes.forEach(n => { n.expanded = false; });
  root.expanded = true;
  if (innerWidth > 720) root.children.forEach(b => { b.expanded = true; });
}

const $openAll = $("openAll"), $closeAll = $("closeAll");
$openAll.addEventListener("click", () => {
  clearFilter();
  nodes.forEach(n => { if (canOpen(n)) n.expanded = true; });
  render(); fitVisible();
});
$closeAll.addEventListener("click", () => {
  clearFilter();
  setInitialOpen();
  render(); fitVisible();
});
function updateActionButtons() {
  const allOpen = nodes.every(n => !canOpen(n) || n.expanded);
  $openAll.hidden = allOpen;
  $closeAll.hidden = !allOpen;
}
$("zoomIn").addEventListener("click", () => zoomBy(1.4));
$("zoomOut").addEventListener("click", () => zoomBy(1 / 1.4));
$("recenter").addEventListener("click", () => { userMoved = false; fitVisible(); });

/* ——— Aide en bas ——— */
const $hint = $("hint");
const nbSalons = nodes.filter(n => n.kind === "branche" && n.children.length && cardFan(n)).length;
$("hintText").textContent = `${cards.length} fiches · ${nbSalons} salons · Cliquez sur une bulle pour explorer · glissez pour vous déplacer · molette pour zoomer`;
function hideHint() { $hint.classList.add("is-hidden"); }
$("hintClose").addEventListener("click", hideHint);

/* ——— Petites notifications ——— */
const $toast = $("toast");
let toastT = 0;
function toast(msg) {
  $toast.textContent = msg;
  $toast.classList.add("is-on");
  clearTimeout(toastT);
  toastT = setTimeout(() => $toast.classList.remove("is-on"), 3600);
}

/* ——— Fenêtres ——— */
let openOv = null, lastFocus = null;
function openOverlay(o) {
  if (openOv && openOv !== o) closeOverlay(openOv, true);
  closeMenu();
  lastFocus = document.activeElement;
  o.hidden = false;
  o.classList.remove("is-closing");
  const sheet = o.querySelector(".sheet");
  sheet.scrollTop = 0;
  (o.querySelector("[data-autofocus]") || sheet).focus({ preventScroll: true });
  openOv = o;
}
function closeOverlay(o = openOv, instant = false) {
  if (!o || o.hidden) return;
  if (o === $cardOverlay) setHash(null);
  if (openOv === o) openOv = null;
  const done = () => { o.hidden = true; o.classList.remove("is-closing"); };
  if (instant || REDUCED) done();
  else { o.classList.add("is-closing"); setTimeout(done, 190); }
  if (!instant && lastFocus && document.contains(lastFocus)) lastFocus.focus({ preventScroll: true });
}
document.querySelectorAll(".overlay").forEach(o => {
  o.addEventListener("click", e => {
    if (e.target === o || e.target.closest("[data-close]")) closeOverlay(o);
  });
});
document.addEventListener("keydown", e => {
  if (!openOv || e.key !== "Tab") return;
  const f = [...openOv.querySelectorAll("button, a[href], input, textarea, select, [tabindex='0']")].filter(x => !x.hidden && x.offsetParent);
  if (!f.length) return;
  const first = f[0], last = f[f.length - 1];
  if (e.shiftKey && (document.activeElement === first || !openOv.contains(document.activeElement))) { e.preventDefault(); last.focus(); }
  else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
});

function setHash(id) {
  try { history.replaceState(null, "", id ? `#fiche=${encodeURIComponent(id)}` : location.pathname + location.search); } catch (_) { /* page locale */ }
}
async function copyText(text, input) {
  try { await navigator.clipboard.writeText(text); toast("Lien copié."); }
  catch (_) {
    if (input) { input.select(); toast("Sélectionnez le lien puis copiez-le."); }
    else toast(text);
  }
}

/* ——— Fiche ——— */
const $cardOverlay = $("cardOverlay"), $card = $cardOverlay.querySelector(".sheet");
const li = s => `<li>${esc(s)}</li>`;
function openCard(n) {
  const words = n.corps.join(" ").split(/\s+/).length;
  const min = Math.max(1, Math.round(words / 200));
  const dots = min <= 3 ? 1 : min <= 6 ? 2 : 3;
  const crumbs = n.ancestors.slice(1).map(a => a.label).join(" › ");
  const edu = n.mission === "Éduquer";
  const quote = n.citation ? n.citation.texte.replace(/^[«"\s]+|[»"\s]+$/g, "") : "";
  $card.dataset.c = n.couleur;
  $card.innerHTML = `
    <button class="sheet-close" data-close aria-label="Fermer la fiche">${icon("x")}</button>
    <header class="card-head">
      <div class="card-ico">${icon(n.icon)}</div>
      <div>
        <p class="eyebrow"><span class="mission ${edu ? "m-eduquer" : "m-informer"}">${esc(n.mission)}</span>${n.repere ? `<span class="repere">${esc(n.repere)}</span>` : ""}</p>
        <h2 id="cardTitle">${esc(n.label)}</h2>
        <p class="card-resume">${esc(n.resume)}</p>
      </div>
    </header>
    ${n.essentiel ? `<h3 class="kicker">L'essentiel</h3><ul class="essentiel">${n.essentiel.map(li).join("")}</ul>` : ""}
    ${n.plaisir ? `<h3 class="kicker">Pourquoi c'est un plaisir</h3><p class="plaisir">${esc(n.plaisir)}</p>` : ""}
    ${quote ? `<blockquote class="citation"><p>«&nbsp;${esc(quote)}&nbsp;»</p><footer>${esc(n.citation.auteur)}${n.citation.source ? `, <cite>${esc(n.citation.source)}</cite>` : ""}</footer></blockquote>` : ""}
    <button class="btn-primary" data-read aria-expanded="false" aria-controls="cardArticle">Lire l'article · ${min} min ${icon("chevron")}</button>
    <div class="article" id="cardArticle" hidden>${n.corps.map(p => `<p>${esc(p)}</p>`).join("")}</div>
    <h3 class="kicker">À essayer</h3>
    <ol class="steps">${n.pratique.map(li).join("")}</ol>
    <div class="tiles">
      <div class="tile"><div class="tile-viz">${icon(edu ? "eduquer" : "informer")}</div><span class="tile-label">Mission</span><span class="tile-value">${esc(n.mission)}</span></div>
      <div class="tile"><div class="tile-viz">${[1, 2, 3].map(i => `<span class="dot${i <= dots ? " on" : ""}"></span>`).join("")}</div><span class="tile-label">Lecture</span><span class="tile-value">${min} min</span></div>
      <div class="tile"><div class="tile-viz">${icon("pratique")}</div><span class="tile-label">À essayer</span><span class="tile-value">${n.pratique.length} étape${n.pratique.length > 1 ? "s" : ""}</span></div>
    </div>
    ${n.videos && n.videos.length ? `<h3 class="kicker">À regarder</h3><div class="chips">${n.videos.map((v, i) =>
      `<a class="chip${i ? "" : " primary"}" href="${esc(v.url)}" target="_blank" rel="noopener">${icon("play")}<span>${esc(v.title)} <small>· ${esc(v.channel)}</small></span></a>`).join("")}</div>` : ""}
    <h3 class="kicker">Sources</h3>
    <div class="chips">${n.sources.map(s => `<a class="chip" href="${esc(s.url)}" target="_blank" rel="noopener"><span>${esc(s.ref)}</span>${icon("externe")}</a>`).join("")}</div>
    <footer class="card-foot"><span class="crumbs">${esc(crumbs)}</span><button class="link-btn" data-copy>${icon("lien")}Copier le lien</button></footer>`;
  openOverlay($cardOverlay);
  setHash(n.id);
}
$card.addEventListener("click", e => {
  const read = e.target.closest("[data-read]");
  if (read) {
    const open = read.getAttribute("aria-expanded") !== "true";
    read.setAttribute("aria-expanded", String(open));
    $("cardArticle").hidden = !open;
  }
  if (e.target.closest("[data-copy]")) copyText(location.href);
});

/* ——— Recherche tolérante (sans accents, une faute de frappe permise) ——— */
const STOP = new Set("le la les de des du un une et en au aux que qui quoi pour par sur avec est ce ces son sa ses mon ma mes comment pourquoi".split(" "));
const norm = s => String(s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/œ/g, "oe").replace(/æ/g, "ae");
const words = s => norm(s).split(/[^a-z0-9]+/).filter(w => w.length > 1);
const pathOf = n => n.ancestors.slice(1).map(a => a.label).join(" › ");
const index = nodes.filter(n => n.depth > 0).map(n => ({
  n, path: pathOf(n), title: words(n.label),
  hay: words([n.resume, n.repere, pathOf(n), n.sousTitre].filter(Boolean).join(" ")),
}));
function oneEdit(a, b) {
  if (a === b) return true;
  const la = a.length, lb = b.length;
  if (Math.abs(la - lb) > 1) return false;
  let i = 0, j = 0, edits = 0;
  while (i < la && j < lb) {
    if (a[i] === b[j]) { i++; j++; continue; }
    if (++edits > 1) return false;
    if (la > lb) i++; else if (lb > la) j++; else { i++; j++; }
  }
  return edits + (la - i) + (lb - j) <= 1;
}
function tokenScore(t, e) {
  let best = 0;
  for (const w of e.title) {
    if (w === t) return 8;
    if (w.startsWith(t)) best = Math.max(best, 6);
    else if (t.length >= 4 && (oneEdit(t, w) || oneEdit(t, w.slice(0, t.length)))) best = Math.max(best, 4);
  }
  if (best) return best;
  for (const w of e.hay) {
    if (w.startsWith(t)) best = Math.max(best, w === t ? 3 : 2);
    else if (t.length >= 5 && oneEdit(t, w)) best = Math.max(best, 1);
  }
  return best;
}
function search(q) {
  const toks = words(q).filter(t => !STOP.has(t));
  if (!toks.length) return [];
  const out = [];
  for (const e of index) {
    let s = 0;
    for (const t of toks) {
      const v = tokenScore(t, e);
      if (!v) { s = 0; break; }
      s += v;
    }
    if (s) out.push({ e, s: s + (e.n.kind === "carte" ? 0 : 1) });
  }
  return out.sort((a, b) => b.s - a.s || a.e.n.label.localeCompare(b.e.n.label, "fr")).slice(0, 8);
}

const $search = $("searchInput"), $results = $("searchResults");
let results = [], sel = -1;
function showResults() {
  const q = $search.value.trim();
  results = q ? search(q) : [];
  sel = results.length ? 0 : -1;
  if (!q) { $results.hidden = true; $search.setAttribute("aria-expanded", "false"); return; }
  $results.innerHTML = results.length
    ? results.map(({ e }, i) => `<button class="result" role="option" id="res-${i}" data-c="${e.n.couleur}" aria-selected="${i === sel}" data-i="${i}">
        <span class="r-ico">${icon(e.n.kind === "carte" ? e.n.icon : e.n.verrou ? "verrou" : e.n.icon)}</span>
        <span><span class="r-title">${esc(e.n.label)}</span><span class="r-path">${esc(e.path || "Guà Wàn")}</span></span></button>`).join("")
    : `<p class="search-empty">Rien de ce côté-là. Essayez un autre mot, ou explorez la carte.</p>`;
  $results.hidden = false;
  $search.setAttribute("aria-expanded", "true");
  $search.setAttribute("aria-activedescendant", sel >= 0 ? `res-${sel}` : "");
}
function moveSel(d) {
  if (!results.length) return;
  sel = (sel + d + results.length) % results.length;
  $results.querySelectorAll(".result").forEach((b, i) => b.setAttribute("aria-selected", String(i === sel)));
  $results.querySelector(`#res-${sel}`).scrollIntoView({ block: "nearest" });
  $search.setAttribute("aria-activedescendant", `res-${sel}`);
}
function closeSearch() { $results.hidden = true; $search.setAttribute("aria-expanded", "false"); }
function choose(i) {
  const r = results[i];
  if (!r) return;
  $search.value = "";
  closeSearch();
  $search.blur();
  reveal(r.e.n);
}
$search.addEventListener("input", showResults);
$search.addEventListener("focus", () => { if ($search.value.trim()) showResults(); });
$search.addEventListener("keydown", e => {
  if (e.key === "ArrowDown") { e.preventDefault(); moveSel(1); }
  else if (e.key === "ArrowUp") { e.preventDefault(); moveSel(-1); }
  else if (e.key === "Enter") { e.preventDefault(); choose(sel); }
  else if (e.key === "Escape") { e.stopPropagation(); if ($search.value) { $search.value = ""; closeSearch(); } else $search.blur(); }
});
$results.addEventListener("mousedown", e => e.preventDefault());
$results.addEventListener("click", e => { const b = e.target.closest(".result"); if (b) choose(+b.dataset.i); });
document.addEventListener("pointerdown", e => { if (!e.target.closest(".search")) closeSearch(); });

/* Ouvre le chemin jusqu'à une bulle, l'amène à l'écran et, pour une fiche, l'ouvre. */
function reveal(n) {
  clearFilter();
  hideHint();
  n.ancestors.forEach(a => { a.expanded = true; });
  if (canOpen(n)) n.expanded = true;
  render();
  ping(n);
  if (n.kind === "carte") {
    fitTo([n.parent, ...n.parent.children]);
    setTimeout(() => openCard(n), REDUCED ? 0 : 950);
  } else ensureVisible(n);
}
function ping(n) {
  n.el.classList.remove("is-ping");
  void n.el.offsetWidth;
  n.el.classList.add("is-ping");
  setTimeout(() => n.el.classList.remove("is-ping"), 3400);
}

/* ——— Filtres : mettre en évidence toutes les fiches d'une région ou d'une mission ——— */
const $filterOverlay = $("filterOverlay"), $filterSheet = $filterOverlay.querySelector(".sheet");
const $clear = $("clearFilter");
let filter = null;
const $actions = $("topActions");
DATA.filtres.slice().reverse().forEach(f => {
  const b = document.createElement("button");
  b.className = "pill";
  b.dataset.filter = f.id;
  b.innerHTML = `<span class="long">${esc(f.bouton)}</span><span class="short">${esc(f.court || f.bouton)}</span>`;
  b.addEventListener("click", () => openFilter(f.id));
  $actions.prepend(b);
});

function openFilter(fid) {
  const f = DATA.filtres.find(x => x.id === fid);
  const counts = new Map();
  cards.forEach(c => ((c.tags || {})[fid] || []).forEach(v => counts.set(v, (counts.get(v) || 0) + 1)));
  const items = [...counts].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0], "fr"));
  $filterSheet.innerHTML = `
    <button class="sheet-close" data-close aria-label="Fermer">${icon("x")}</button>
    <h2 id="filterTitle">${esc(f.titre)}</h2>
    <p class="lead">${esc(f.intro)}</p>
    ${DATA.filtres.length > 1 ? `<div class="tabs" role="tablist">${DATA.filtres.map(x =>
      `<button class="tab" role="tab" data-tab="${esc(x.id)}" aria-selected="${x.id === fid}">${esc(x.court || x.bouton)}</button>`).join("")}</div>` : ""}
    <ul class="filter-list">${items.map(([v, c], i) =>
      `<li><button class="filter-item" data-value="${esc(v)}"${i ? "" : " data-autofocus"}><span>${esc(v)}</span><span class="count">${c}</span></button></li>`).join("")}</ul>`;
  $filterSheet.dataset.filter = fid;
  if ($filterOverlay.hidden) openOverlay($filterOverlay);
  else $filterSheet.querySelector(`[data-tab="${fid}"]`).focus();
}
$filterSheet.addEventListener("click", e => {
  const tab = e.target.closest("[data-tab]");
  if (tab) return openFilter(tab.dataset.tab);
  const item = e.target.closest("[data-value]");
  if (item) applyFilter($filterSheet.dataset.filter, item.dataset.value);
});

function applyFilter(fid, value) {
  closeOverlay($filterOverlay, true);
  hideHint();
  const matches = new Set(cards.filter(c => ((c.tags || {})[fid] || []).includes(value)));
  nodes.forEach(n => { n.expanded = n === root; });
  matches.forEach(c => c.ancestors.forEach(a => { a.expanded = true; }));
  filter = { matches, keep: new Set([...matches].flatMap(c => c.ancestors)) };
  render();
  fitTo([...matches, ...filter.keep]);
  const f = DATA.filtres.find(x => x.id === fid);
  $clear.innerHTML = `<span>${esc(f.court || f.bouton)} : ${esc(value)} · ${matches.size} fiche${matches.size > 1 ? "s" : ""}</span><span class="x">${icon("x")}</span>`;
  $clear.setAttribute("aria-label", `Effacer le filtre ${f.court || f.bouton} : ${value}`);
  $clear.hidden = false;
}
function paintFilter() {
  nodes.forEach(n => {
    const m = !!filter && filter.matches.has(n), keep = !!filter && filter.keep.has(n);
    n.el.classList.toggle("is-match", m);
    n.el.classList.toggle("is-dim", !!filter && !m && !keep);
    if (n.link) n.link.classList.toggle("is-dim", !!filter && !m && !keep);
  });
}
function clearFilter() {
  if (!filter) return;
  filter = null;
  paintFilter();
  $clear.hidden = true;
}
$clear.addEventListener("click", clearFilter);

/* ——— Menu ——— */
const $menuBtn = $("menuBtn"), $menu = $("menu");
const docEl = document.documentElement;
const darkMQ = matchMedia("(prefers-color-scheme: dark)");
const isDark = () => { const t = docEl.getAttribute("data-theme"); return t ? t === "dark" : darkMQ.matches; };
function buildMenu() {
  const items = [
    ["theme", isDark() ? "soleil" : "lune", isDark() ? "Mode clair" : "Mode sombre"],
    ["suggest", "idee", "Proposer une fiche"],
    ["share", "partager", "Partager la carte"],
    docEl.requestFullscreen ? ["full", "plein", document.fullscreenElement ? "Quitter le plein écran" : "Plein écran"] : null,
    ["about", "info", "À propos de L'Univers"],
  ].filter(Boolean);
  $menu.innerHTML = items.map(([act, ic, label]) => `<button role="menuitem" data-act="${act}">${icon(ic)}<span>${label}</span></button>`).join("");
}
function openMenu() {
  buildMenu();
  $menu.hidden = false;
  $menuBtn.setAttribute("aria-expanded", "true");
  $menu.querySelector("button").focus();
}
function closeMenu() {
  if ($menu.hidden) return;
  $menu.hidden = true;
  $menuBtn.setAttribute("aria-expanded", "false");
}
$menuBtn.addEventListener("click", () => ($menu.hidden ? openMenu() : closeMenu()));
document.addEventListener("pointerdown", e => { if (!e.target.closest(".menu-wrap")) closeMenu(); });
$menu.addEventListener("keydown", e => {
  if (e.key !== "ArrowDown" && e.key !== "ArrowUp") return;
  e.preventDefault();
  const items = [...$menu.querySelectorAll("button")];
  const i = items.indexOf(document.activeElement);
  items[(i + (e.key === "ArrowDown" ? 1 : -1) + items.length) % items.length].focus();
});
$menu.addEventListener("click", e => {
  const b = e.target.closest("[data-act]");
  if (!b) return;
  const act = b.dataset.act;
  closeMenu();
  if (act === "theme") toggleTheme();
  else if (act === "suggest") openSuggest();
  else if (act === "share") openShare();
  else if (act === "full") toggleFullscreen();
  else if (act === "about") openAbout();
});

function toggleTheme() {
  const next = isDark() ? "light" : "dark";
  docEl.setAttribute("data-theme", next);
  try { localStorage.setItem("gw-theme", next); } catch (_) { /* stockage indisponible */ }
}
function toggleFullscreen() {
  if (document.fullscreenElement) document.exitFullscreen();
  else docEl.requestFullscreen().catch(() => toast("Le plein écran n'est pas disponible ici."));
}

const $suggest = $("suggestOverlay"), $suggestSheet = $suggest.querySelector(".sheet");
function openSuggest() {
  $suggestSheet.innerHTML = `
    <button class="sheet-close" data-close aria-label="Fermer">${icon("x")}</button>
    <h2 id="suggestTitle">Proposer une fiche</h2>
    <p class="lead">Une sagesse, une pratique, une découverte qui mériterait sa place dans L'Univers ? Racontez-nous.</p>
    <form class="form" id="suggestForm">
      <label class="field">Votre idée<textarea name="idee" required data-autofocus placeholder="Par exemple : le shinrin-yoku, le bain de forêt japonais"></textarea></label>
      <label class="field">Dans quel bloc ?<select name="bloc">${root.children.map(b => `<option>${esc(b.label)}</option>`).join("")}<option>Je ne sais pas</option></select></label>
      <label class="field">Votre prénom (facultatif)<input name="prenom" autocomplete="given-name"></label>
      <button class="btn-accent" type="submit">Envoyer</button>
      <p class="note">Maquette : l'envoi n'est pas encore relié à la base de données.</p>
    </form>`;
  openOverlay($suggest);
}
$suggestSheet.addEventListener("submit", e => {
  e.preventDefault();
  $suggestSheet.innerHTML = `
    <button class="sheet-close" data-close aria-label="Fermer">${icon("x")}</button>
    <h2 id="suggestTitle">Merci, Humain.</h2>
    <p class="lead">Votre idée est notée. Elle rejoindra peut-être bientôt l'une des bulles de la carte.</p>
    <p class="note" style="margin-top:14px">Maquette : rien n'a été envoyé.</p>
    <button class="btn-accent" data-close data-autofocus style="margin-top:22px">Revenir à la carte</button>`;
  $suggestSheet.querySelector("[data-autofocus]").focus();
});

const $share = $("shareOverlay"), $shareSheet = $share.querySelector(".sheet");
function openShare() {
  const url = location.href.split("#")[0];
  $shareSheet.innerHTML = `
    <button class="sheet-close" data-close aria-label="Fermer">${icon("x")}</button>
    <h2 id="shareTitle">Partager la carte</h2>
    <p class="lead">Envoyez L'Univers à un Humain curieux. Pour une fiche précise, ouvrez-la et copiez son lien.</p>
    <div class="share-row"><input readonly value="${esc(url)}" aria-label="Lien de la carte"><button class="btn-accent" data-copy-map data-autofocus>Copier</button></div>
    ${navigator.share ? `<button class="chip" data-native style="margin-top:14px">${icon("partager")}Autres options de partage</button>` : ""}`;
  openOverlay($share);
}
$shareSheet.addEventListener("click", e => {
  if (e.target.closest("[data-copy-map]")) copyText($shareSheet.querySelector("input").value, $shareSheet.querySelector("input"));
  if (e.target.closest("[data-native]")) navigator.share({ title: document.title, url: location.href.split("#")[0] }).catch(() => {});
});

const $about = $("aboutOverlay"), $aboutSheet = $about.querySelector(".sheet");
function openAbout() {
  $aboutSheet.innerHTML = `
    <button class="sheet-close" data-close aria-label="Fermer">${icon("x")}</button>
    <h2 id="aboutTitle">À propos de L'Univers</h2>
    <p class="lead">Chaque humain est le centre de son propre univers. Cette carte part de vous et rayonne vers les trois blocs de Guà Wàn : L'Esprit, La Création et Le Corps.</p>
    <div class="about-stats">
      <div><b>${cards.length}</b><span>fiches</span></div>
      <div><b>${nbSalons}</b><span>salons ouverts</span></div>
      <div><b>${root.children.length}</b><span>blocs</span></div>
    </div>
    <ul class="legend">
      <li data-c="esprit"><span class="sw"></span>Une bulle ronde est un bloc, un groupe ou un salon : cliquez pour l'ouvrir.</li>
      <li data-c="corps"><span class="sw sq"></span>Un carré arrondi est une fiche : cliquez pour la lire.</li>
      <li data-c="creation"><span class="sw"></span>Chaque bloc a sa couleur : indigo pour L'Esprit, ambre pour La Création, rose sakura pour Le Corps.</li>
    </ul>
    <p class="note" style="margin-top:20px">Raccourcis : ⌘K ou / pour chercher · + et − pour zoomer · 0 pour recentrer · Échap pour fermer.</p>`;
  openOverlay($about);
}

/* ——— Clavier ——— */
document.addEventListener("keydown", e => {
  const typing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName);
  if ((e.key === "k" && (e.metaKey || e.ctrlKey)) || (e.key === "/" && !typing && !openOv)) {
    e.preventDefault();
    closeOverlay();
    $search.focus();
    $search.select();
    return;
  }
  if (e.key === "Escape") {
    if (!$menu.hidden) { closeMenu(); $menuBtn.focus(); }
    else if (openOv) closeOverlay();
    else if (filter) clearFilter();
    return;
  }
  if (typing || openOv || e.metaKey || e.ctrlKey || e.altKey) return;
  if (e.key === "+" || e.key === "=") zoomBy(1.4);
  else if (e.key === "-" || e.key === "_") zoomBy(1 / 1.4);
  else if (e.key === "0") { userMoved = false; fitVisible(); }
});

/* ——— Démarrage : l'ensō se trace, puis les blocs et leurs salons se déploient depuis le centre ——— */
nodes.forEach(makeNode);
nodes.forEach(n => { if (n.parent) makeLink(n); });
setInitialOpen();
root.s = 0.7;
layout();
fitVisible(false);
render((n, order) => {
  if (!n.vis || !n.depth) return 0;
  const i = order.get(n.depth) || 0;
  order.set(n.depth, i + 1);
  return n.depth === 1 ? 420 + i * 150 : 980 + i * 45;
});

addEventListener("resize", () => { if (!userMoved) fitVisible(false); });
document.addEventListener("fullscreenchange", () => { if (!userMoved) setTimeout(() => fitVisible(), 60); });

const deep = decodeURIComponent((location.hash.match(/^#fiche=(.+)$/) || [])[1] || "");
if (byId.has(deep)) setTimeout(() => reveal(byId.get(deep)), REDUCED ? 0 : 1300);
})();
