#!/usr/bin/env node
// Hearth restyle checks. One command per phase; exits non-zero when anything fails.
//
//   node scripts/hearth/verify.mjs baseline [--with-flutter]   record what must not change (run once, before any edit)
//   node scripts/hearth/verify.mjs phase <N|all> [--no-flutter] check a phase (phases 1..N are linted; "all" = whole app)
//   node scripts/hearth/verify.mjs deployed --url <https://…>   compare a deployed web build's commit with local HEAD
//
// What "phase" checks, in order:
//   1. history   - the baseline commit is still an ancestor of HEAD (today's work was not reset away)
//   2. protected - no edits under services, models, functions, rules, QA tooling, search-check, or existing tests;
//                  pubspec.yaml changes only inside the fonts block
//   3. strings   - every string literal that existed at baseline still exists (case, emoji and spacing ignored),
//                  so copy, labels, option lists, keys and routes were not rolled back
//   4. lint      - in the phase's files: no raw colours, gradients, old fonts, retired tokens, drop shadows or emoji
//   5. theme     - (phase >= 1) Hearth tokens and fonts are in place
//   6. flutter   - flutter analyze has no more errors than at baseline, and flutter test passes
//
// Requires Node 18+. Run from the repo root.

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.cwd();
const PHASES_FILE = path.join(ROOT, 'design/hearth/phases.json');
const BASELINE_FILE = path.join(ROOT, 'design/hearth/baseline.json');
const ALLOW_FILE = path.join(ROOT, 'design/hearth/string-allowlist.json');
const isWin = process.platform === 'win32';

const args = process.argv.slice(2);
const cmd = args[0];
const flag = (name) => args.includes(name);
const opt = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};

let failures = 0;
const fail = (msg) => { failures++; console.log(`  FAIL  ${msg}`); };
const ok = (msg) => console.log(`  ok    ${msg}`);
const info = (msg) => console.log(`  info  ${msg}`);
const section = (t) => console.log(`\n== ${t} ==`);

function run(bin, argv, opts = {}) {
  const r = spawnSync(bin, argv, { cwd: ROOT, encoding: 'utf8', shell: isWin, maxBuffer: 64 * 1024 * 1024, ...opts });
  return { code: r.status, out: (r.stdout || '') + (r.stderr || '') };
}
const git = (...a) => run('git', a);

// ---------- files ----------
const toPosix = (p) => p.split(path.sep).join('/');
function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if (e.name.endsWith('.dart')) out.push(toPosix(path.relative(ROOT, p)));
  }
  return out;
}
const read = (rel) => fs.readFileSync(path.join(ROOT, rel), 'utf8');

// ---------- Dart string literal extraction ----------
// Returns [{text, line}] for every string literal (single, double, triple, raw).
function dartStrings(src) {
  const out = [];
  let i = 0;
  let line = 1;
  const n = src.length;
  const adv = (k = 1) => { for (let j = 0; j < k; j++) { if (src[i] === '\n') line++; i++; } };

  function readString() {
    // at an optional r and a quote
    let raw = false;
    if (src[i] === 'r') { raw = true; adv(); }
    const q = src[i];
    const triple = src.substr(i, 3) === q.repeat(3);
    const startLine = line;
    adv(triple ? 3 : 1);
    let text = '';
    while (i < n) {
      if (triple ? src.substr(i, 3) === q.repeat(3) : src[i] === q) { adv(triple ? 3 : 1); break; }
      if (!triple && src[i] === '\n') break; // unterminated; stop
      if (!raw && src[i] === '\\') { text += src.substr(i, 2); adv(2); continue; }
      if (!raw && src[i] === '$' && src[i + 1] === '{') { text += '${'; adv(2); skipExpr(); text += '}'; continue; }
      text += src[i];
      adv();
    }
    out.push({ text, line: startLine });
  }
  function skipExpr() {
    let depth = 1;
    while (i < n && depth > 0) {
      const c = src[i];
      if (c === '{') { depth++; adv(); continue; }
      if (c === '}') { depth--; adv(); continue; }
      if (c === "'" || c === '"' || (c === 'r' && (src[i + 1] === "'" || src[i + 1] === '"') && !/[A-Za-z0-9_]/.test(src[i - 1] || ''))) { readString(); out.pop(); continue; }
      adv();
    }
  }
  while (i < n) {
    const c = src[i];
    if (c === '/' && src[i + 1] === '/') { while (i < n && src[i] !== '\n') adv(); continue; }
    if (c === '/' && src[i + 1] === '*') { adv(2); while (i < n && !(src[i] === '*' && src[i + 1] === '/')) adv(); adv(2); continue; }
    if (c === "'" || c === '"') { readString(); continue; }
    if (c === 'r' && (src[i + 1] === "'" || src[i + 1] === '"') && !/[A-Za-z0-9_]/.test(src[i - 1] || '')) { readString(); continue; }
    adv();
  }
  return out;
}

const EMOJI = /(?![©®™])\p{Extended_Pictographic}/gu;
function norm(s) {
  return s.replace(EMOJI, '').replace(/[️‍]/g, '').replace(/\s+/g, ' ').trim().toLowerCase();
}

function literalsOf(rel) {
  const src = read(rel);
  const lines = src.split('\n');
  const keep = new Set();
  for (const { text, line } of dartStrings(src)) {
    const l = lines[line - 1] || '';
    if (/^\s*(import|export|part)\b/.test(l)) continue;
    if (/\b(print|debugPrint|log)\s*\(/.test(l)) continue;
    if (/fontFamily\s*:/.test(l)) continue;
    const t = norm(text);
    if (t.length < 3 || !/\p{L}/u.test(t)) continue;
    keep.add(t);
  }
  return [...keep];
}

// ---------- config ----------
const phasesCfg = JSON.parse(fs.readFileSync(PHASES_FILE, 'utf8'));
const isExempt = (rel) => phasesCfg.exempt.some((e) => (e.endsWith('/') ? rel.startsWith(e) : e.startsWith('.') ? rel.endsWith(e) : rel === e));

// A legacy file is skipped only while nothing outside other unused legacy files refers to its class.
// (A static reference is not proof the screen is reachable, so referenced ones are restyled to be safe.)
function legacyStatus() {
  const all = walk(path.join(ROOT, 'lib'));
  const res = phasesCfg.legacy.map(({ file, class: cls }) => {
    if (!fs.existsSync(path.join(ROOT, file))) return { file, cls, state: 'missing', refs: [] };
    const re = new RegExp(`\\b${cls}\\b`);
    const defRe = new RegExp(`\\bclass\\s+${cls}\\b|\\b${cls}\\s*=`);
    if (!re.test(read(file))) return { file, cls, state: 'class-not-found', refs: [] };
    const refs = all.filter((f) => f !== file && !f.startsWith('lib/qa/') && re.test(read(f)) && !defRe.test(read(f)));
    return { file, cls, state: 'referenced', refs };
  });
  let changed = true;
  while (changed) {
    changed = false;
    const dead = new Set(res.filter((r) => r.state === 'unreferenced' || r.state === 'missing').map((r) => r.file));
    for (const r of res) {
      if (r.state !== 'referenced') continue;
      if (r.refs.every((f) => dead.has(f))) { r.state = 'unreferenced'; changed = true; }
    }
    if (!changed) {
      // break cycles: files referenced only by each other (and by nothing live) are dead together
      const live = res.filter((r) => r.state === 'referenced');
      const liveFiles = new Set(live.map((r) => r.file));
      for (const r of live) {
        const outside = r.refs.filter((f) => !dead.has(f) && !liveFiles.has(f));
        if (!outside.length && r.refs.length) {
          const reachable = r.refs.some((f) => res.find((x) => x.file === f && x.refs.some((g) => !dead.has(g) && !liveFiles.has(g))));
          if (!reachable) { r.state = 'unreferenced'; changed = true; }
        }
      }
    }
  }
  return res;
}

// ---------- baseline ----------
function cmdBaseline() {
  if (fs.existsSync(BASELINE_FILE) && !flag('--force')) {
    console.log('design/hearth/baseline.json already exists. Re-run with --force only before any restyle edit (see plan, Phase 0).');
    process.exit(1);
  }
  const head = git('rev-parse', 'HEAD').out.trim();
  const dirty = git('status', '--porcelain', '--', 'lib', 'pubspec.yaml').out.trim();
  if (dirty) {
    console.log('lib/ or pubspec.yaml has uncommitted changes. Commit or stash them first so the baseline matches a commit:\n' + dirty);
    process.exit(1);
  }
  const files = walk(path.join(ROOT, 'lib')).filter((f) => !f.startsWith('lib/qa/') && !f.endsWith('.g.dart'));
  const strings = {};
  let total = 0;
  for (const f of files) { strings[f] = literalsOf(f); total += strings[f].length; }
  const base = { commit: head, createdAt: new Date().toISOString(), strings };
  if (flag('--with-flutter')) {
    const a = run('flutter', ['analyze', '--no-fatal-infos', '--no-fatal-warnings']);
    base.analyzeErrors = (a.out.match(/^\s*error\s+•/gm) || []).length;
    const t = run('flutter', ['test']);
    base.testsPass = t.code === 0;
    console.log(`flutter analyze errors: ${base.analyzeErrors}; flutter test: ${base.testsPass ? 'pass' : 'FAIL'}`);
  }
  fs.mkdirSync(path.dirname(BASELINE_FILE), { recursive: true });
  fs.writeFileSync(BASELINE_FILE, JSON.stringify(base, null, 1));
  console.log(`baseline written: commit ${head.slice(0, 9)}, ${files.length} files, ${total} string literals`);
}

// ---------- phase checks ----------
const PROTECTED = ['lib/services', 'lib/models', 'functions', 'firestore.rules', 'firestore.indexes.json', 'storage.rules', 'scripts/search-check', 'deploy', 'lib/qa/qa_harness.dart', 'lib/qa/layout_auditor.dart', 'lib/qa/qa_bridge_stub.dart', 'lib/qa/qa_bridge_web.dart', 'tool'];

function checkHistory(base) {
  section('history');
  const r = git('merge-base', '--is-ancestor', base.commit, 'HEAD');
  if (r.code === 0) ok(`baseline commit ${base.commit.slice(0, 9)} is still in HEAD's history`);
  else fail(`baseline commit ${base.commit.slice(0, 9)} is no longer an ancestor of HEAD (was history rewritten?)`);
}

function checkProtected(base) {
  section('protected paths');
  const changed = git('diff', '--name-only', base.commit, '--', ...PROTECTED).out.trim().split('\n').filter(Boolean);
  changed.length ? changed.forEach((f) => fail(`protected file changed: ${f}`)) : ok('no protected files changed');
  const tests = git('diff', '--name-only', '--diff-filter=MD', base.commit, '--', 'test').out.trim().split('\n').filter(Boolean);
  tests.length ? tests.forEach((f) => fail(`existing test modified or deleted: ${f}`)) : ok('existing tests untouched (new tests are fine)');
  const diff = git('diff', '-U0', base.commit, '--', 'pubspec.yaml').out.split('\n');
  const bad = diff.filter((l) => /^[+-](?![+-])/.test(l)).filter((l) => !/^[+-]\s*($|#|fonts:|- family:\s*(YoungSerif|Figtree|Primary|Secondary)\b|- asset:\s*assets\/fonts\/|weight:\s*\d+|style:\s*\w+)/.test(l));
  bad.length ? bad.forEach((l) => fail(`pubspec.yaml change outside the fonts block: ${l.trim()}`)) : ok('pubspec.yaml: only font entries changed');
}

function checkStrings(base) {
  section('strings (no copy rolled back)');
  const allow = fs.existsSync(ALLOW_FILE) ? JSON.parse(fs.readFileSync(ALLOW_FILE, 'utf8')) : [];
  const allowed = new Set(allow.map((a) => `${a.file}::${norm(a.text)}`));
  const current = {};
  const global = new Set();
  for (const f of walk(path.join(ROOT, 'lib')).filter((f) => !f.startsWith('lib/qa/') && !f.endsWith('.g.dart'))) {
    current[f] = new Set(literalsOf(f));
    current[f].forEach((s) => global.add(s));
  }
  let missing = 0;
  let moved = 0;
  for (const [file, list] of Object.entries(base.strings)) {
    for (const s of list) {
      if (current[file]?.has(s)) continue;
      if (global.has(s)) { moved++; continue; }
      if (allowed.has(`${file}::${s}`)) continue;
      missing++;
      if (missing <= 60) fail(`${file}: string missing: "${s.slice(0, 90)}"`);
    }
  }
  if (missing > 60) fail(`…and ${missing - 60} more missing strings`);
  if (!missing) ok(`all baseline strings present (${moved} moved to another file)`);
}

const LINT = [
  ['raw colour', /\bColor\(\s*0x[0-9A-Fa-f]{6,8}\s*\)|\bColor\.from(ARGB|RGBO)\s*\(|\bColors\.(?!transparent\b)[A-Za-z]+/],
  ['gradient', /\b(LinearGradient|RadialGradient|SweepGradient)\s*\(/],
  ['old font', /fontFamily:\s*['"](Primary|Secondary)['"]|GoogleFonts\.(?!youngSerif|figtree)\w+/],
  ['retired token', /AppTheme\.(brandTurquoise|lightSecondary|primaryActionGradient|encouragementGradient|gradient[A-Z]\w*|ambientPurpleBlur|shadowSoft|shadowMedium|lightMuted)\b/],
  ['drop shadow', /\bBoxShadow\s*\(|\belevation:\s*[1-9]/],
  ['emoji', EMOJI],
];

function phaseFiles(upTo) {
  const legacy = legacyStatus();
  const skip = new Set(legacy.filter((l) => l.state === 'unreferenced' || l.state === 'missing').map((l) => l.file));
  if (upTo === 'all' || upTo >= 16) {
    return { files: walk(path.join(ROOT, 'lib')).filter((f) => !isExempt(f) && !skip.has(f)), legacy };
  }
  const files = new Set();
  for (const p of phasesCfg.phases) if (p.id <= upTo) p.files.filter((f) => f.endsWith('.dart')).forEach((f) => files.add(f));
  return { files: [...files].filter((f) => !isExempt(f) && fs.existsSync(path.join(ROOT, f))), legacy };
}

function checkLint(upTo) {
  section(`lint (${upTo === 'all' ? 'whole app' : `phases 1-${upTo}`})`);
  const { files, legacy } = phaseFiles(upTo);
  if (upTo === 'all' || upTo >= 16) {
    for (const l of legacy) {
      if (l.state === 'referenced') info(`legacy file is referenced now, so it is in scope: ${l.file} (via ${l.refs.join(', ')})`);
      if (l.state === 'class-not-found') info(`legacy check could not find ${l.cls} in ${l.file}; treating it as in scope`);
    }
  }
  let count = 0;
  for (const f of files) {
    const lines = read(f).split('\n');
    lines.forEach((l, idx) => {
      const t = l.trim();
      if (t.startsWith('//') || /\b(print|debugPrint|log)\s*\(/.test(l)) return;
      for (const [name, re] of LINT) {
        re.lastIndex = 0;
        if (re.test(l)) { count++; if (count <= 80) fail(`${f}:${idx + 1} ${name}: ${t.slice(0, 110)}`); }
      }
    });
  }
  if (count > 80) fail(`…and ${count - 80} more lint findings`);
  if (!count) ok(`${files.length} files clean`);
}

function checkTheme() {
  section('theme foundation');
  const theme = read('lib/cors/ui_theme.dart');
  const need = { F5F1E8: 'page ground', FAF8F4: 'card surface', E6D5B8: 'warm border', EFE0C6: 'warm tint', D4A574: 'gold', '663399': 'purple', EDE7F3: 'lavender', '2D2733': 'ink', '4A3F52': 'secondary text', '6B5C75': 'muted text' };
  for (const [hex, name] of Object.entries(need)) {
    new RegExp(`0x(FF)?${hex}\\b`, 'i').test(theme) ? ok(`token ${name} #${hex}`) : fail(`ui_theme.dart has no ${name} #${hex}`);
  }
  const pub = read('pubspec.yaml');
  for (const fam of ['YoungSerif', 'Figtree']) /- family:\s*/.test(pub) && new RegExp(`- family:\\s*${fam}\\b`).test(pub) ? ok(`pubspec declares ${fam}`) : fail(`pubspec.yaml does not declare font family ${fam}`);
  for (const f of ['YoungSerif-Regular.ttf', 'Figtree-Regular.ttf', 'Figtree-Medium.ttf', 'Figtree-SemiBold.ttf', 'Figtree-Bold.ttf']) {
    fs.existsSync(path.join(ROOT, 'assets/fonts/hearth', f)) ? ok(`font file ${f}`) : fail(`missing assets/fonts/hearth/${f}`);
  }
  /fontFamily:\s*['"]Figtree['"]|family:\s*['"]?Figtree/.test(theme) || /'Figtree'/.test(theme) ? ok('theme references Figtree') : fail('ui_theme.dart does not use Figtree');
  /'YoungSerif'/.test(theme) ? ok('theme references YoungSerif') : fail('ui_theme.dart does not use YoungSerif');
}

function checkFlutter(base) {
  section('flutter');
  const v = run('flutter', ['--version']);
  if (v.code !== 0) { fail('flutter is not on PATH'); return; }
  const a = run('flutter', ['analyze', '--no-fatal-infos', '--no-fatal-warnings']);
  const errs = (a.out.match(/^\s*error\s+•/gm) || []).length;
  const allowed = base.analyzeErrors ?? 0;
  errs <= allowed ? ok(`flutter analyze: ${errs} errors (baseline ${allowed})`) : fail(`flutter analyze: ${errs} errors, baseline was ${allowed}\n${a.out.split('\n').filter((l) => /error\s+•/.test(l)).slice(0, 20).join('\n')}`);
  const t = run('flutter', ['test']);
  t.code === 0 ? ok('flutter test passed') : fail(`flutter test failed\n${t.out.split('\n').slice(-30).join('\n')}`);
}

function cmdPhase() {
  const which = args[1];
  const upTo = which === 'all' ? 'all' : Number(which);
  if (which !== 'all' && !(upTo >= 0 && upTo <= 16)) { console.log('usage: verify.mjs phase <0-16|all>'); process.exit(2); }
  if (!fs.existsSync(BASELINE_FILE)) { console.log('No design/hearth/baseline.json. Run Phase 0 first: node scripts/hearth/verify.mjs baseline --with-flutter'); process.exit(2); }
  const base = JSON.parse(fs.readFileSync(BASELINE_FILE, 'utf8'));
  console.log(`Hearth verify: phase ${which}, baseline ${base.commit.slice(0, 9)}, HEAD ${git('rev-parse', '--short', 'HEAD').out.trim()}`);
  checkHistory(base);
  checkProtected(base);
  checkStrings(base);
  if (upTo === 'all' || upTo >= 1) { checkLint(upTo); checkTheme(); }
  if (!flag('--no-flutter')) checkFlutter(base);
  else info('flutter checks skipped (--no-flutter)');
  console.log(failures ? `\nRESULT: FAIL (${failures})` : '\nRESULT: PASS');
  process.exit(failures ? 1 : 0);
}

async function cmdDeployed() {
  const url = opt('--url');
  if (!url) { console.log('usage: verify.mjs deployed --url https://<qa-harness-host>'); process.exit(2); }
  const head = git('rev-parse', 'HEAD').out.trim();
  const res = await fetch(new URL('/build.json', url));
  if (!res.ok) { console.log(`GET /build.json -> HTTP ${res.status}`); process.exit(1); }
  const b = await res.json();
  console.log(`deployed: commit ${String(b.commit).slice(0, 9)} branch ${b.branch}\nlocal:    commit ${head.slice(0, 9)} branch ${git('branch', '--show-current').out.trim()}`);
  process.exit(b.commit === head ? 0 : 1);
}

if (cmd === 'baseline') cmdBaseline();
else if (cmd === 'phase') cmdPhase();
else if (cmd === 'deployed') await cmdDeployed();
else { console.log('usage: verify.mjs baseline [--with-flutter] [--force] | phase <0-16|all> [--no-flutter] | deployed --url <url>'); process.exit(2); }
