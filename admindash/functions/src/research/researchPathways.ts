/**
 * Configurable recruitment pathways (numeric codes for exports & cohort summaries).
 * Stored at `research_config/recruitment_pathways`.
 */
import * as admin from 'firebase-admin';
import { RECRUITMENT_PATHWAY_CODES } from './researchFieldSpec';

const db = admin.firestore();

export const RESEARCH_CONFIG_PATHWAYS_DOC = 'research_config/recruitment_pathways';

export type RecruitmentPathwayEntry = { code: number; label: string };

export const DEFAULT_RECRUITMENT_PATHWAYS: RecruitmentPathwayEntry[] = [
  { code: RECRUITMENT_PATHWAY_CODES.navigator_supported, label: 'Navigator-supported cohort' },
  { code: RECRUITMENT_PATHWAY_CODES.self_directed, label: 'Self-directed cohort' },
];

const MIN_PATHWAY_CODE = 1;
const MAX_PATHWAY_CODE = 99;
const MAX_PATHWAYS = 24;

function normalizeEntry(raw: unknown): RecruitmentPathwayEntry | null {
  if (!raw || typeof raw !== 'object') return null;
  const o = raw as Record<string, unknown>;
  const code = typeof o.code === 'number' ? Math.floor(o.code) : parseInt(String(o.code ?? ''), 10);
  const label = typeof o.label === 'string' ? o.label.trim() : '';
  if (!Number.isFinite(code) || code < MIN_PATHWAY_CODE || code > MAX_PATHWAY_CODE) return null;
  if (!label || label.length > 120) return null;
  return { code, label };
}

export function normalizePathwayList(raw: unknown): RecruitmentPathwayEntry[] {
  if (!Array.isArray(raw)) return [];
  const out: RecruitmentPathwayEntry[] = [];
  const seen = new Set<number>();
  for (const item of raw) {
    const e = normalizeEntry(item);
    if (!e || seen.has(e.code)) continue;
    seen.add(e.code);
    out.push(e);
  }
  return out.sort((a, b) => a.code - b.code);
}

export async function getRecruitmentPathways(): Promise<RecruitmentPathwayEntry[]> {
  const ref = db.doc(RESEARCH_CONFIG_PATHWAYS_DOC);
  const snap = await ref.get();
  if (!snap.exists) {
    await ref.set(
      {
        pathways: DEFAULT_RECRUITMENT_PATHWAYS,
        seeded: true,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return [...DEFAULT_RECRUITMENT_PATHWAYS];
  }
  const list = normalizePathwayList(snap.data()?.pathways);
  return list.length ? list : [...DEFAULT_RECRUITMENT_PATHWAYS];
}

export async function getAllowedPathwayCodes(): Promise<Set<number>> {
  const pathways = await getRecruitmentPathways();
  return new Set(pathways.map((p) => p.code));
}

export async function isValidRecruitmentPathwayCode(code: number): Promise<boolean> {
  return (await getAllowedPathwayCodes()).has(code);
}

export async function pathwayLabelForCode(code: number): Promise<string> {
  const pathways = await getRecruitmentPathways();
  return pathways.find((p) => p.code === code)?.label ?? `Pathway ${code}`;
}

export async function requireResearchAdmin(uid: string): Promise<void> {
  const adminDoc = await db.collection('ADMIN').doc(uid).get();
  if (!adminDoc.exists) {
    throw new Error('admin_required');
  }
}

export async function countParticipantsWithPathway(code: number): Promise<number> {
  const snap = await db
    .collection('research_participants')
    .where('recruitment_pathway', '==', code)
    .limit(1)
    .get();
  return snap.size;
}

export function validateNewPathwayInput(code: unknown, label: unknown, existing: RecruitmentPathwayEntry[]): string | null {
  const c = typeof code === 'number' ? Math.floor(code) : parseInt(String(code ?? ''), 10);
  if (!Number.isFinite(c) || c < MIN_PATHWAY_CODE || c > MAX_PATHWAY_CODE) {
    return 'code_must_be_integer_1_to_99';
  }
  if (existing.some((p) => p.code === c)) return 'code_already_exists';
  if (existing.length >= MAX_PATHWAYS) return 'max_pathways_reached';
  const lab = typeof label === 'string' ? label.trim() : '';
  if (!lab) return 'label_required';
  if (lab.length > 120) return 'label_too_long';
  return null;
}
