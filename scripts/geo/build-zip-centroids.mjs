#!/usr/bin/env node
/**
 * Builds functions/data/zip-centroids.json, the offline ZIP/place centroid table
 * used by provider search (functions/providerGeo.js) to compute distances.
 *
 * Source (public domain, US Census Bureau Gazetteer files):
 *   https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2023_Gazetteer/2023_Gaz_zcta_national.zip
 *   https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2023_Gazetteer/2023_Gaz_place_national.zip
 *
 * Coverage: every Ohio ZCTA (ZIP 430xx-459xx) plus ZCTAs and places in PA, WV,
 * KY, IN and MI that lie within MAX_MI of an Ohio ZCTA. Places are only used as a
 * fallback for ZIPs that have no ZCTA (PO boxes, single-building ZIPs such as 44195).
 *
 * Usage: node scripts/geo/build-zip-centroids.mjs <2023_Gaz_zcta_national.txt> <2023_Gaz_place_national.txt>
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [zctaFile, placeFile] = process.argv.slice(2);
if (!zctaFile || !placeFile) {
  console.error('usage: build-zip-centroids.mjs <zcta.txt> <place.txt>');
  process.exit(1);
}
const MAX_MI = 80;
// ZIPs with no ZCTA (single-building / PO box ZIPs) that providers use often. Coordinates are
// street-level points from the US Census geocoder (public domain) for the main address in the ZIP.
const OVERRIDES = {
  44195: [41.5033, -81.6229], // Cleveland Clinic main campus, 9500 Euclid Ave, Cleveland
};
const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', '..', 'functions', 'data', 'zip-centroids.json');

const hav = (a, b) => {
  const R = 3958.8, r = (d) => (d * Math.PI) / 180;
  const h = Math.sin(r(b[0] - a[0]) / 2) ** 2 + Math.cos(r(a[0])) * Math.cos(r(b[0])) * Math.sin(r(b[1] - a[1]) / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
};
const rows = (f) => fs.readFileSync(f, 'utf8').split(/\r?\n/).slice(1).filter(Boolean).map((l) => l.split('\t').map((s) => s.trim()));
const inRange = (z, lo, hi) => { const p = +z.slice(0, 3); return p >= lo && p <= hi; };
const NEIGHBOUR_RANGES = [[150, 196], [247, 268], [400, 427], [460, 479], [480, 499]];

const ohio = [];
const other = [];
for (const r of rows(zctaFile)) {
  const zip = r[0];
  const pt = [+r[5], +r[6]];
  if (inRange(zip, 430, 459)) ohio.push([zip, pt]);
  else if (NEIGHBOUR_RANGES.some(([lo, hi]) => inRange(zip, lo, hi))) other.push([zip, pt]);
}
const nearOhio = (pt) => ohio.some(([, o]) => Math.abs(o[0] - pt[0]) < 1.3 && hav(o, pt) <= MAX_MI);
const round = (pt) => [+pt[0].toFixed(4), +pt[1].toFixed(4)];
const zips = {};
for (const [z, pt] of ohio) zips[z] = round(pt);
for (const [z, pt] of other) if (nearOhio(pt)) zips[z] = round(pt);
for (const [z, pt] of Object.entries(OVERRIDES)) zips[z] = pt;

const places = {};
const STATES = new Set(['OH', 'PA', 'WV', 'KY', 'IN', 'MI']);
for (const r of rows(placeFile)) {
  const [st, , , name] = r;
  if (!STATES.has(st)) continue;
  const pt = [+r[10], +r[11]];
  if (st !== 'OH' && !nearOhio(pt)) continue;
  const key = `${st}|${name.replace(/\s+(city|village|CDP|town|borough|municipality|charter township|township)$/i, '').toLowerCase().replace(/\./g, '').replace(/\s+/g, ' ')}`;
  if (!places[key]) places[key] = round(pt);
}
const out = {
  source: 'US Census Bureau 2023 Gazetteer (ZCTA and Place internal points), public domain. Built by scripts/geo/build-zip-centroids.mjs',
  zips,
  places,
};
fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(out));
console.log(`wrote ${OUT}: ${Object.keys(zips).length} ZIPs (${ohio.length} Ohio), ${Object.keys(places).length} places, ${fs.statSync(OUT).size} bytes`);
