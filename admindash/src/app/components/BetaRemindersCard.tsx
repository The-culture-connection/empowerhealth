import { useEffect, useState } from "react";
import { BellRing, Loader2 } from "lucide-react";
import { format } from "date-fns";
import {
  getBetaPushSettings,
  runBetaRemindersNow,
  setBetaPushEnabled,
  type BetaPushRunStats,
  type BetaPushSettings,
} from "../../lib/notifications";

const SOURCE_LABELS: Record<string, string> = {
  schedule: "Scheduled run",
  schedule_skipped_off: "Scheduled run skipped (reminders off)",
  manual: "Sent manually",
};

function statsLine(s: BetaPushRunStats) {
  return `${s.testers} testers · ${s.eligible} with tasks left · ${s.notified} notified · ${s.noTokens} without a device · ${s.failed} failed`;
}

/** On/off switch and manual controls for the daily beta checklist reminder. */
export function BetaRemindersCard() {
  const [settings, setSettings] = useState<BetaPushSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<"" | "toggle" | "preview" | "send">("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function refresh() {
    try {
      setSettings(await getBetaPushSettings());
    } catch (e: any) {
      setError(e?.message || "Could not load beta reminder settings");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
  }, []);

  async function toggle() {
    if (!settings) return;
    setBusy("toggle");
    setError("");
    setMessage("");
    try {
      setSettings(await setBetaPushEnabled(!settings.enabled));
    } catch (e: any) {
      setError(e?.message || "Could not update the setting");
    } finally {
      setBusy("");
    }
  }

  async function preview() {
    setBusy("preview");
    setError("");
    setMessage("");
    try {
      const r = await runBetaRemindersNow(true);
      setMessage(`Right now ${r.eligible} of ${r.testers} testers have beta tasks left and would get a reminder.`);
    } catch (e: any) {
      setError(e?.message || "Preview failed");
    } finally {
      setBusy("");
    }
  }

  async function sendNow() {
    if (!window.confirm("Send the beta checklist reminder now to every tester with tasks left?")) return;
    setBusy("send");
    setError("");
    setMessage("");
    try {
      const r = await runBetaRemindersNow(false);
      setMessage(`Sent: ${statsLine(r)}.`);
      await refresh();
    } catch (e: any) {
      setError(e?.message || "Sending failed");
    } finally {
      setBusy("");
    }
  }

  const enabled = settings?.enabled ?? false;
  const lastRun = settings?.lastRun;

  return (
    <div
      className="mb-8 p-6 rounded-2xl border"
      style={{ backgroundColor: "white", borderColor: "var(--lavender-200)" }}
    >
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="flex items-start gap-3">
          <BellRing className="w-6 h-6 mt-1" style={{ color: "var(--lavender-500)" }} />
          <div>
            <h2 style={{ color: "var(--warm-600)" }}>Beta tester reminders</h2>
            <p className="text-sm mt-1" style={{ color: "var(--warm-500)" }}>
              Reminds each beta tester who still has checklist items, or hasn't used the app for 10 minutes
              today, to finish their tasks. {settings?.schedule ?? "Daily at 6:00 PM Eastern"}.
            </p>
          </div>
        </div>

        {loading ? (
          <Loader2 className="w-5 h-5 animate-spin" style={{ color: "var(--lavender-500)" }} />
        ) : (
          <button
            type="button"
            role="switch"
            aria-checked={enabled}
            aria-label="Daily beta reminders"
            disabled={!settings || busy !== ""}
            onClick={toggle}
            className="flex items-center gap-3 disabled:opacity-60"
          >
            <span className="text-sm" style={{ color: "var(--warm-600)" }}>
              {enabled ? "On" : "Off"}
            </span>
            <span
              className="relative inline-flex h-7 w-12 rounded-full transition-colors"
              style={{ backgroundColor: enabled ? "var(--lavender-500)" : "var(--warm-200, #e7e5e4)" }}
            >
              <span
                className="absolute top-1 h-5 w-5 rounded-full bg-white transition-all"
                style={{ left: enabled ? "1.5rem" : "0.25rem" }}
              />
            </span>
          </button>
        )}
      </div>

      {settings?.updatedAt && (
        <p className="text-xs mt-3" style={{ color: "var(--warm-400)" }}>
          Turned {enabled ? "on" : "off"} {format(new Date(settings.updatedAt), "MMM d, yyyy h:mm a")}
          {settings.updatedBy ? ` by ${settings.updatedBy}` : ""}
        </p>
      )}

      <div className="mt-4 p-4 rounded-xl text-sm" style={{ backgroundColor: "var(--warm-50)", color: "var(--warm-600)" }}>
        {lastRun ? (
          <>
            <div>
              Last run: {SOURCE_LABELS[lastRun.source] ?? lastRun.source}
              {lastRun.at ? `, ${format(new Date(lastRun.at), "MMM d, yyyy h:mm a")}` : ""}
            </div>
            {lastRun.source !== "schedule_skipped_off" && (
              <div className="mt-1" style={{ color: "var(--warm-500)" }}>{statsLine(lastRun)}</div>
            )}
          </>
        ) : (
          <span style={{ color: "var(--warm-500)" }}>No reminders recorded yet.</span>
        )}
      </div>

      <div className="mt-4 flex flex-wrap gap-3">
        <button
          type="button"
          onClick={preview}
          disabled={busy !== ""}
          className="px-4 py-2 rounded-xl border text-sm flex items-center gap-2 disabled:opacity-60"
          style={{ borderColor: "var(--lavender-300, var(--lavender-200))", color: "var(--lavender-600, var(--warm-600))" }}
        >
          {busy === "preview" && <Loader2 className="w-4 h-4 animate-spin" />}
          Preview who would get it
        </button>
        <button
          type="button"
          onClick={sendNow}
          disabled={busy !== ""}
          className="px-4 py-2 rounded-xl text-sm text-white flex items-center gap-2 disabled:opacity-60"
          style={{ backgroundColor: "var(--lavender-500)" }}
        >
          {busy === "send" && <Loader2 className="w-4 h-4 animate-spin" />}
          Send reminder now
        </button>
      </div>

      {message && (
        <div className="mt-4 p-3 rounded-xl text-sm" style={{ backgroundColor: "#d1fae5", color: "#065f46" }}>
          {message}
        </div>
      )}
      {error && (
        <div className="mt-4 p-3 rounded-xl text-sm" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
          {error}
        </div>
      )}
    </div>
  );
}
