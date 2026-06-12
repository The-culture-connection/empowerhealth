import { useEffect, useMemo, useState } from "react";
import {
  collection,
  deleteDoc,
  doc,
  onSnapshot,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  Timestamp,
} from "firebase/firestore";
import { auth, firestore } from "../../firebase/firebase";
import { Loader2, Ban, ShieldCheck } from "lucide-react";

/**
 * Reported & blocked users (App Store Guideline 1.2).
 *
 * Aggregates three report sources by the offending user:
 *  - `moderation_reports` (type "user_blocked") — created when an app user
 *    blocks someone; carries the offending content snapshot.
 *  - `post_reports` — flagged community posts (now carry reportedUserId).
 *  - `reply_reports` — flagged community replies.
 *
 * Moderators can ban a user (writes `banned_users/{uid}`, which Firestore rules
 * use to block all further posting) or resolve the reports.
 */

type ReportRef = { collection: string; id: string };

type RawReport = {
  id: string;
  collection: "moderation_reports" | "post_reports" | "reply_reports";
  offenderUid: string | null;
  offenderName: string | null;
  reason: string | null;
  snippet: string | null;
  reporterUid: string | null;
  status: string;
  createdAt: Timestamp | null;
};

type Offender = {
  uid: string;
  name: string | null;
  blocks: number;
  postReports: number;
  replyReports: number;
  reasons: string[];
  snippets: { kind: string; text: string; when: string }[];
  reports: ReportRef[];
  latest: number;
};

function useCollection(
  name: RawReport["collection"],
  mapper: (id: string, x: Record<string, unknown>) => RawReport,
) {
  const [rows, setRows] = useState<RawReport[]>([]);
  const [error, setError] = useState("");
  const [loaded, setLoaded] = useState(false);
  useEffect(() => {
    const unsub = onSnapshot(
      query(collection(firestore, name)),
      (snap) => {
        const next: RawReport[] = [];
        snap.forEach((d) => next.push(mapper(d.id, d.data())));
        setRows(next);
        setLoaded(true);
        setError("");
      },
      (err) => {
        console.error(`[${name}]`, err);
        setError(err.message || `Failed to load ${name}`);
        setLoaded(true);
      },
    );
    return () => unsub();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [name]);
  return { rows, error, loaded };
}

const s = (v: unknown): string | null => (v == null ? null : String(v));

export function UserModerationAdmin() {
  const blocks = useCollection("moderation_reports", (id, x) => ({
    id,
    collection: "moderation_reports",
    offenderUid: s(x.blockedUid),
    offenderName: s(x.blockedName),
    reason: s(x.reason) ?? "Blocked by a user",
    snippet: s(x.contentSnapshot),
    reporterUid: s(x.reportedByUid),
    status: s(x.status) ?? "open",
    createdAt: (x.createdAt as Timestamp) ?? null,
  }));

  const postReports = useCollection("post_reports", (id, x) => ({
    id,
    collection: "post_reports",
    offenderUid: s(x.reportedUserId),
    offenderName: s(x.reportedUserName),
    reason: s(x.reason),
    snippet: s(x.postTitle) ?? s(x.details),
    reporterUid: s(x.userId),
    status: s(x.status) ?? "open",
    createdAt: (x.createdAt as Timestamp) ?? null,
  }));

  const replyReports = useCollection("reply_reports", (id, x) => ({
    id,
    collection: "reply_reports",
    offenderUid: s(x.reportedUserId),
    offenderName: s(x.reportedUserName),
    reason: s(x.reason),
    snippet: s(x.content),
    reporterUid: s(x.userId),
    status: s(x.status) ?? "open",
    createdAt: (x.createdAt as Timestamp) ?? null,
  }));

  const [banned, setBanned] = useState<Set<string>>(new Set());
  const [bannedLoaded, setBannedLoaded] = useState(false);
  useEffect(() => {
    const unsub = onSnapshot(
      collection(firestore, "banned_users"),
      (snap) => {
        setBanned(new Set(snap.docs.map((d) => d.id)));
        setBannedLoaded(true);
      },
      (err) => {
        console.error("[banned_users]", err);
        setBannedLoaded(true);
      },
    );
    return () => unsub();
  }, []);

  const [busyUid, setBusyUid] = useState<string | null>(null);
  const [actionError, setActionError] = useState("");

  const all = useMemo(
    () => [...blocks.rows, ...postReports.rows, ...replyReports.rows],
    [blocks.rows, postReports.rows, replyReports.rows],
  );

  // Group attributable reports by offender uid.
  const { offenders, unattributed } = useMemo(() => {
    const map = new Map<string, Offender>();
    const orphan: RawReport[] = [];
    for (const r of all) {
      if (r.status === "resolved") continue;
      if (!r.offenderUid) {
        orphan.push(r);
        continue;
      }
      const cur =
        map.get(r.offenderUid) ??
        ({
          uid: r.offenderUid,
          name: null,
          blocks: 0,
          postReports: 0,
          replyReports: 0,
          reasons: [],
          snippets: [],
          reports: [],
          latest: 0,
        } as Offender);
      if (r.offenderName && !cur.name) cur.name = r.offenderName;
      if (r.collection === "moderation_reports") cur.blocks++;
      else if (r.collection === "post_reports") cur.postReports++;
      else cur.replyReports++;
      if (r.reason && !cur.reasons.includes(r.reason)) cur.reasons.push(r.reason);
      if (r.snippet) {
        cur.snippets.push({
          kind:
            r.collection === "moderation_reports"
              ? "blocked content"
              : r.collection === "post_reports"
                ? "post"
                : "reply",
          text: r.snippet,
          when: r.createdAt?.toDate?.()?.toLocaleString?.() ?? "—",
        });
      }
      cur.reports.push({ collection: r.collection, id: r.id });
      cur.latest = Math.max(cur.latest, r.createdAt?.toMillis?.() ?? 0);
      map.set(r.offenderUid, cur);
    }
    const offenders = [...map.values()].sort((a, b) => b.latest - a.latest);
    return { offenders, unattributed: orphan };
  }, [all]);

  async function banUser(o: Offender) {
    if (
      !window.confirm(
        `Ban ${o.name ?? o.uid}?\n\nThey will be blocked from posting, replying, ` +
          `or reviewing in the app. You can unban them later.`,
      )
    )
      return;
    setBusyUid(o.uid);
    setActionError("");
    try {
      await setDoc(doc(firestore, "banned_users", o.uid), {
        uid: o.uid,
        name: o.name ?? null,
        bannedBy: auth.currentUser?.uid ?? null,
        bannedAt: serverTimestamp(),
        reason: o.reasons.join(", "),
      });
    } catch (e) {
      console.error(e);
      setActionError(e instanceof Error ? e.message : "Ban failed");
    } finally {
      setBusyUid(null);
    }
  }

  async function unbanUser(uid: string) {
    setBusyUid(uid);
    setActionError("");
    try {
      await deleteDoc(doc(firestore, "banned_users", uid));
    } catch (e) {
      console.error(e);
      setActionError(e instanceof Error ? e.message : "Unban failed");
    } finally {
      setBusyUid(null);
    }
  }

  async function resolveReports(o: Offender) {
    setBusyUid(o.uid);
    setActionError("");
    try {
      await Promise.all(
        o.reports.map((r) =>
          updateDoc(doc(firestore, r.collection, r.id), {
            status: "resolved",
            resolvedAt: serverTimestamp(),
            resolvedBy: auth.currentUser?.uid ?? null,
          }),
        ),
      );
    } catch (e) {
      console.error(e);
      setActionError(e instanceof Error ? e.message : "Resolve failed");
    } finally {
      setBusyUid(null);
    }
  }

  const loading =
    !blocks.loaded || !postReports.loaded || !replyReports.loaded || !bannedLoaded;
  const loadError = blocks.error || postReports.error || replyReports.error;

  if (loading) {
    return (
      <div className="p-8 flex items-center gap-2" style={{ color: "var(--warm-500)" }}>
        <Loader2 className="h-5 w-5 animate-spin" />
        Loading reported users…
      </div>
    );
  }

  return (
    <div className="p-8 max-w-5xl">
      <h1 className="text-2xl font-semibold mb-2" style={{ color: "var(--warm-600)" }}>
        Reported &amp; blocked users
      </h1>
      <p className="text-sm mb-6" style={{ color: "var(--warm-500)" }}>
        Users blocked or flagged in the app, grouped by person. <strong>Ban</strong> writes{" "}
        <code className="text-xs">banned_users/&#123;uid&#125;</code>, which Firestore rules use to
        block all further posting. <strong>Resolve</strong> clears the open reports for that user.
      </p>

      {loadError ? (
        <div className="mb-4 p-4 rounded-xl text-sm bg-red-50 text-red-700">{loadError}</div>
      ) : null}
      {actionError ? (
        <div className="mb-4 p-4 rounded-xl text-sm bg-red-50 text-red-700">{actionError}</div>
      ) : null}

      {offenders.length === 0 ? (
        <p style={{ color: "var(--warm-500)" }}>No open reports. 🎉</p>
      ) : (
        <ul className="space-y-4">
          {offenders.map((o) => {
            const busy = busyUid === o.uid;
            const isBanned = banned.has(o.uid);
            const total = o.blocks + o.postReports + o.replyReports;
            return (
              <li
                key={o.uid}
                className="rounded-2xl border p-5"
                style={{
                  backgroundColor: "white",
                  borderColor: isBanned ? "#fecaca" : "var(--lavender-200)",
                }}
              >
                <div className="flex flex-wrap justify-between gap-4">
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <span className="font-medium" style={{ color: "var(--warm-600)" }}>
                        {o.name ?? "Unknown user"}
                      </span>
                      {isBanned ? (
                        <span className="text-xs px-2 py-0.5 rounded-full bg-red-100 text-red-700">
                          Banned
                        </span>
                      ) : null}
                    </div>
                    <div className="text-xs mt-1 opacity-70">
                      UID: <code>{o.uid}</code>
                    </div>
                    <div className="text-sm mt-2" style={{ color: "var(--warm-500)" }}>
                      {total} open report{total === 1 ? "" : "s"} · {o.blocks} block
                      {o.blocks === 1 ? "" : "s"} · {o.postReports} post · {o.replyReports} reply
                    </div>
                    {o.reasons.length ? (
                      <div className="text-sm mt-2" style={{ color: "var(--warm-600)" }}>
                        <strong>Reasons:</strong> {o.reasons.join(", ")}
                      </div>
                    ) : null}
                    {o.snippets.length ? (
                      <div className="mt-3 space-y-2">
                        {o.snippets.slice(0, 5).map((sn, i) => (
                          <div
                            key={i}
                            className="text-sm rounded-lg p-3"
                            style={{ backgroundColor: "var(--warm-50, #faf7f0)" }}
                          >
                            <span className="text-xs uppercase opacity-60">{sn.kind}</span>
                            <div style={{ color: "var(--warm-600)" }}>"{sn.text}"</div>
                            <span className="text-xs opacity-50">{sn.when}</span>
                          </div>
                        ))}
                        {o.snippets.length > 5 ? (
                          <div className="text-xs opacity-60">
                            +{o.snippets.length - 5} more…
                          </div>
                        ) : null}
                      </div>
                    ) : null}
                  </div>
                  <div className="flex flex-col gap-2 shrink-0">
                    {isBanned ? (
                      <button
                        type="button"
                        disabled={busy}
                        onClick={() => void unbanUser(o.uid)}
                        className="px-3 py-2 rounded-xl text-sm border disabled:opacity-50 inline-flex items-center gap-1.5 justify-center"
                        style={{ borderColor: "var(--lavender-300)", color: "var(--lavender-700)" }}
                      >
                        {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <ShieldCheck className="h-4 w-4" />}
                        Unban
                      </button>
                    ) : (
                      <button
                        type="button"
                        disabled={busy}
                        onClick={() => void banUser(o)}
                        className="px-3 py-2 rounded-xl text-sm disabled:opacity-50 inline-flex items-center gap-1.5 justify-center"
                        style={{
                          borderColor: "#fecaca",
                          color: "#b91c1c",
                          backgroundColor: "#fef2f2",
                          borderWidth: 1,
                          borderStyle: "solid",
                        }}
                      >
                        {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Ban className="h-4 w-4" />}
                        Ban user
                      </button>
                    )}
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => void resolveReports(o)}
                      className="px-3 py-2 rounded-xl text-sm text-white disabled:opacity-50"
                      style={{ backgroundColor: "var(--lavender-600)" }}
                    >
                      Resolve reports
                    </button>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      )}

      {unattributed.length ? (
        <div className="mt-10">
          <h2 className="text-lg font-semibold mb-2" style={{ color: "var(--warm-600)" }}>
            Reports without a linked user ({unattributed.length})
          </h2>
          <p className="text-sm mb-4" style={{ color: "var(--warm-500)" }}>
            Older reports submitted before the app recorded the reported user. Triage in the
            relevant content collection.
          </p>
          <ul className="space-y-2">
            {unattributed.slice(0, 50).map((r) => (
              <li
                key={`${r.collection}-${r.id}`}
                className="rounded-xl border p-3 text-sm"
                style={{ backgroundColor: "white", borderColor: "var(--lavender-200)" }}
              >
                <span className="text-xs uppercase opacity-60">{r.collection}</span> ·{" "}
                {r.reason ?? "—"} {r.snippet ? `· "${r.snippet}"` : ""}
              </li>
            ))}
          </ul>
        </div>
      ) : null}
    </div>
  );
}
