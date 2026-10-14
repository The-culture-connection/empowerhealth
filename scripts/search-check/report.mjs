// Turns a check-search.mjs results file into a readable Markdown report.
//
//   node scripts/search-check/report.mjs [results.json] [out.md]
//
// Defaults: the newest file in scripts/search-check/results/ and
// docs/search-check/<date>-<target>.md.

import fs from 'node:fs';
import path from 'node:path';

const here = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const resultsDir = path.join(here, 'results');
const input = process.argv[2] || path.join(resultsDir, fs.readdirSync(resultsDir).filter((f) => f.endsWith('.json')).sort().at(-1));
const r = JSON.parse(fs.readFileSync(input, 'utf8'));

const target = r.options.FN_BASE.includes('127.0.0.1') || r.options.FN_BASE.includes('localhost') ? 'emulator' : 'production';
const day = r.startedAt.slice(0, 10);
const out = process.argv[3] || path.join(here, '..', '..', 'docs', 'search-check', `${day}-${target}${r.options.QUICK ? '-quick' : ''}.md`);

const s = r.summary;
const fails = r.checks.filter((c) => c.status === 'FAIL');
const warns = r.checks.filter((c) => c.status === 'WARN');
const secs = (ms) => (ms / 1000).toFixed(1) + ' s';
const esc = (t) => String(t ?? '').replace(/\|/g, '\\|').replace(/\n/g, ' ');
const mi = (d) => (d == null || !Number.isFinite(d) ? 'n/a' : d.toFixed(1) + ' mi');
// Street-address distance when the check confirmed one, else ZIP-centroid distance.
const dist = (p) => (Number.isFinite(p.addrDist) ? p.addrDist : p.minDist);

const WHAT = {
  'radius OMX': 'Every provider from OhioMaximusSearch has a location within the radius (independent geocode, small tolerance).',
  'radius SP': 'Same radius check for searchProviders (Medicaid + national NPI list + directory).',
  'zip-centred': 'The nearest result is close to the searched ZIP.',
  'npi-zip': 'National (NPI) providers are near the searched ZIP, not out of state.',
  'distance-field OMX': 'Each provider includes a distance from the searched ZIP.',
  'distance-field SP': 'Same, for searchProviders.',
  'omx dedupe': 'One row per provider (no duplicates per address).',
  'plan-param': 'The plan the user picked is the plan sent to the state directory.',
  'plan-in-response': 'Providers list which plans they accept.',
  'plan-upstream': 'Upstream plan data matches the plan searched.',
  'plan counts': 'Provider counts per plan option.',
  'plan-filter-effective': 'Different plans return different providers (the filter works).',
  'all-plans': '"All plans" is not just CareSource.',
  'all-plans networks': '"All plans" returns providers from many plans.',
  'all-plans coverage': 'How much of the individual plan results "All plans" covers.',
  'not-listed': '"Not listed / not sure" behaves like "All plans".',
  'monotonic OMX': 'A bigger radius never returns fewer providers.',
  'superset OMX': 'A bigger radius still includes everyone from a smaller radius.',
  'monotonic SP medicaid': 'Same, for searchProviders Medicaid results.',
  'superset SP medicaid': 'Same, for searchProviders Medicaid results.',
  'monotonic app-merged': 'Same, for the merged list the app shows.',
  'superset app-merged': 'Same, for the merged list the app shows.',
  'type-crowding': 'Providers found by a single-type search (e.g. midwives) also appear in the all-types search.',
  'expanded-vs-standard': 'Differences between standard and Expanded search.',
  'expanded non-NPI parity': 'Standard and Expanded return the same Medicaid/directory providers (only the national list differs).',
  'upstream-cap': 'Whether the state directory hit its 100-per-query cap (handled by the radius ladder).',
  'upstream types': 'Provider types returned by the state directory.',
  'partial OhioMaximusSearch': 'The server stopped at its 25 s deadline and returned partial results.',
  counts: 'Provider counts per function.',
};

const lines = [];
const P = (...l) => lines.push(...l);

P(`# Provider search live check: ${target} ${day}`, '');
P(fails.length === 0
  ? `**Result: PASS.** ${s.PASS} checks passed, ${s.FAIL || 0} failed, ${s.WARN || 0} warnings, across ${r.callsMade} real searches.`
  : `**Result: FAIL.** ${fails.length} checks failed (${s.PASS} passed, ${s.WARN || 0} warnings) across ${r.callsMade} real searches.`, '');
P('| | |', '|---|---|',
  `| Target | ${r.options.FN_BASE} |`,
  `| Started / finished | ${r.startedAt} / ${r.finishedAt} |`,
  `| Searches (function calls) | ${r.callsMade} |`,
  `| ZIP codes | ${r.options.ZIPS.join(', ')} |`,
  `| Radius tolerance | ${r.options.TOL_ABS} mi + ${r.options.TOL_PCT}% (ZIP-centroid geocoding is approximate) |`,
  `| Results file | ${path.basename(input)} |`, '');

P('## Summary', '', '| Status | Count |', '|---|---|');
for (const k of ['PASS', 'FAIL', 'WARN', 'INFO', 'SKIP']) if (s[k] != null || k === 'FAIL') P(`| ${k} | ${s[k] || 0} |`);
P('', 'INFO lines are measurements (counts, coverage), not pass/fail checks.', '');

const L = r.latency;
P('## Speed', '', '| Function | Calls | Median | 90th percentile | Slowest |', '|---|---|---|---|---|',
  `| OhioMaximusSearch | ${L.omx.calls} | ${secs(L.omx.median)} | ${secs(L.omx.p90)} | ${secs(L.omx.max)} |`,
  `| searchProviders | ${L.sp.calls} | ${secs(L.sp.median)} | ${secs(L.sp.p90)} | ${secs(L.sp.max)} |`, '',
  'The app runs both calls for one search. A first search of an area is slow because each provider type is queried at the state directory; results are cached for 12 hours, so repeat searches are much faster.', '');

P('## Results by search', '',
  'Distances are measured independently by the check script, not taken from the server: street address when it was checked, otherwise the centre of the provider\'s ZIP code (so providers in the searched ZIP show 0.0 mi). "Farthest" is the farthest provider returned; it must be within the radius plus tolerance.', '',
  '| Search | Radius | Providers (app list) | Medicaid | National (NPI) | Nearest | Farthest | Checks |',
  '|---|---|---|---|---|---|---|---|');
for (const run of r.runs.filter((x) => !x.skipped)) {
  const sp = run.spProviders || [];
  const dists = sp.map(dist).filter((d) => Number.isFinite(d));
  const cs = r.checks.filter((c) => c.caseId === run.id);
  const n = (st) => cs.filter((c) => c.status === st).length;
  const medicaid = sp.filter((p) => p.source !== 'npi').length;
  const npi = sp.filter((p) => p.source === 'npi').length;
  const tally = `${n('PASS')} pass${n('FAIL') ? `, **${n('FAIL')} fail**` : ''}${n('WARN') ? `, ${n('WARN')} warn` : ''}`;
  P(`| ${esc(run.id.replace(/ r=\d+.*$/, '') + (run.plan && run.plan !== 'All plans' ? ` · ${run.plan}` : '') + (run.mode && run.mode !== 'standard' ? ` · ${run.mode}` : '') + (run.spPayload?.providerTypeIds?.length === 1 ? ` · type ${run.spPayload.providerTypeIds[0]}` : ''))} | ${run.radius} mi | ${sp.length} | ${medicaid} | ${npi} | ${mi(dists.length ? Math.min(...dists) : null)} | ${mi(dists.length ? Math.max(...dists) : null)} | ${tally} |`);
}
P('');

const planRuns = r.runs.filter((x) => !x.skipped && x.zip === '43215' && x.radius === 10 && x.mode === 'standard' && (x.spPayload?.providerTypeIds?.length || 0) > 1);
if (planRuns.length > 1) {
  P('## Plans (Columbus 43215, 10 mi)', '', '| Plan chosen | Providers | Plans seen on results |', '|---|---|---|');
  for (const run of planRuns) {
    const plans = new Map();
    for (const p of run.spProviders || []) for (const h of p.healthPlans || []) plans.set(h, (plans.get(h) || 0) + 1);
    P(`| ${esc(run.plan)} | ${(run.spProviders || []).length} | ${esc([...plans.entries()].sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k} (${v})`).join(', ') || 'n/a')} |`);
  }
  P('');
}

const sampleIds = [
  r.runs.find((x) => x.zip === '43215' && x.radius === 10 && x.plan === 'All plans' && x.mode === 'standard' && (x.spPayload?.providerTypeIds?.length || 0) > 1),
  r.runs.find((x) => (x.spPayload?.providerTypeIds?.length || 0) === 1),
  r.runs.find((x) => x.zip === '43756' && x.radius === 25 && x.mode === 'standard'),
].filter(Boolean);
if (sampleIds.length) {
  P('## Example results (nearest 10)', '', 'Spot-check these against the app: run the same search in Find Your Care and compare.', '');
  for (const run of sampleIds) {
    P(`### ${run.id}`, '', '| Provider | Source | Distance | Plans |', '|---|---|---|---|');
    const nearest = [...(run.spProviders || [])].filter((p) => Number.isFinite(dist(p))).sort((a, b) => dist(a) - dist(b)).slice(0, 10);
    for (const p of nearest) P(`| ${esc(p.name)} | ${p.source === 'npi' ? 'National (NPI)' : p.source === 'firestore' ? 'Directory' : 'Medicaid'} | ${mi(dist(p))} | ${esc((p.healthPlans || []).join(', ') || '')} |`);
    P('');
  }
}

P('## Failures', '', fails.length ? '' : 'None.');
for (const c of fails) P(`- **${esc(c.caseId)}**: ${esc(c.check)}: ${esc(c.detail)}`);
P('', '## Warnings', '', warns.length ? '' : 'None.');
for (const c of warns) P(`- **${esc(c.caseId)}**: ${esc(c.check)}: ${esc(String(c.detail).slice(0, 600))}`);
P('');

P('## What each check means', '', '| Check | Meaning |', '|---|---|');
for (const name of [...new Set(r.checks.map((c) => c.check))]) P(`| ${esc(name)} | ${esc(WHAT[name] || '')} |`);
P('');

P('## Every check', '', '| Search | Check | Status | Detail |', '|---|---|---|---|');
for (const c of r.checks) P(`| ${esc(c.caseId)} | ${esc(c.check)} | ${c.status} | ${esc(String(c.detail).slice(0, 220))} |`);
P('', '---', '', `Generated by scripts/search-check/report.mjs from ${path.basename(input)}. Re-run the check with \`node scripts/search-check/check-search.mjs\`, then \`node scripts/search-check/report.mjs\`.`);

fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, lines.join('\n') + '\n');
console.log(`Report: ${out}`);
console.log(`Result: ${fails.length ? 'FAIL' : 'PASS'} | PASS ${s.PASS} | FAIL ${s.FAIL || 0} | WARN ${s.WARN || 0} | calls ${r.callsMade}`);
