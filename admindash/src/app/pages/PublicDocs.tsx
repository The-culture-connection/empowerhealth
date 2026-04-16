import { useEffect, useState } from "react";
import { Calendar, FileText, Mail } from "lucide-react";
import { getDocument, type DocumentType } from "../../lib/documentation";
import { MarkdownRenderer } from "../../components/MarkdownRenderer";

type TabKey = "privacy" | "terms" | "support";

const tabToDocType: Record<TabKey, DocumentType> = {
  privacy: "privacy_policy",
  terms: "terms_of_service",
  support: "contact_support",
};

export function PublicDocs() {
  const [activeTab, setActiveTab] = useState<TabKey>("privacy");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [docs, setDocs] = useState<Record<TabKey, any>>({
    privacy: null,
    terms: null,
    support: null,
  });

  useEffect(() => {
    void loadDoc(activeTab);
  }, [activeTab]);

  async function loadDoc(tab: TabKey) {
    if (docs[tab]) return;
    setLoading(true);
    setError("");
    try {
      const doc = await getDocument(tabToDocType[tab]);
      setDocs((prev) => ({ ...prev, [tab]: doc }));
    } catch (e: any) {
      setError(e?.message || "Unable to load document.");
    } finally {
      setLoading(false);
    }
  }

  const currentDoc = docs[activeTab];
  const title =
    activeTab === "privacy"
      ? "Privacy Policy"
      : activeTab === "terms"
      ? "Terms & Conditions / EULA"
      : "Contact & Support";

  return (
    <div className="min-h-screen bg-[var(--warm-50)] flex items-start justify-center py-10 px-4">
      <div className="w-full max-w-4xl bg-white rounded-3xl shadow-lg border border-[var(--lavender-100)] overflow-hidden">
        <header className="px-8 pt-8 pb-4 border-b border-[var(--lavender-100)]">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 rounded-2xl bg-[var(--lavender-100)] flex items-center justify-center">
              <FileText className="w-5 h-5" style={{ color: "var(--lavender-600)" }} />
            </div>
            <div>
              <h1 className="text-2xl font-semibold" style={{ color: "var(--warm-700)" }}>
                EmpowerHealth Watch — Legal & Privacy
              </h1>
              <p className="text-sm" style={{ color: "var(--warm-500)" }}>
                Transparent information about how we protect your data and how to reach us.
              </p>
            </div>
          </div>

          <nav className="mt-4 flex gap-2">
            <button
              onClick={() => setActiveTab("privacy")}
              className={`px-4 py-2 rounded-full text-sm border ${
                activeTab === "privacy" ? "bg-[var(--lavender-500)] text-white" : "bg-[var(--warm-50)]"
              }`}
              style={{
                borderColor: activeTab === "privacy" ? "var(--lavender-500)" : "var(--lavender-200)",
              }}
            >
              Privacy Policy
            </button>
            <button
              onClick={() => setActiveTab("terms")}
              className={`px-4 py-2 rounded-full text-sm border ${
                activeTab === "terms" ? "bg-[var(--lavender-500)] text-white" : "bg-[var(--warm-50)]"
              }`}
              style={{
                borderColor: activeTab === "terms" ? "var(--lavender-500)" : "var(--lavender-200)",
              }}
            >
              Terms & Conditions / EULA
            </button>
            <button
              onClick={() => setActiveTab("support")}
              className={`px-4 py-2 rounded-full text-sm border ${
                activeTab === "support" ? "bg-[var(--lavender-500)] text-white" : "bg-[var(--warm-50)]"
              }`}
              style={{
                borderColor: activeTab === "support" ? "var(--lavender-500)" : "var(--lavender-200)",
              }}
            >
              Contact & Support
            </button>
          </nav>
        </header>

        <main className="px-8 py-6">
          {error && (
            <div className="mb-4 p-3 rounded-xl text-sm" style={{ backgroundColor: "#fee2e2", color: "#b91c1c" }}>
              {error}
            </div>
          )}

          {loading && !currentDoc && (
            <p className="text-sm" style={{ color: "var(--warm-500)" }}>
              Loading…
            </p>
          )}

          {!loading && !currentDoc && !error && (
            <p className="text-sm" style={{ color: "var(--warm-500)" }}>
              This section has not been published yet. Please check back soon.
            </p>
          )}

          {currentDoc && (
            <>
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-semibold" style={{ color: "var(--warm-700)" }}>
                  {title}
                </h2>
                {currentDoc.updatedAt && (
                  <div className="flex items-center gap-2 text-xs" style={{ color: "var(--warm-500)" }}>
                    <Calendar className="w-3 h-3" />
                    <span>
                      Last updated:{" "}
                      {currentDoc.updatedAt.toLocaleDateString(undefined, {
                        year: "numeric",
                        month: "short",
                        day: "numeric",
                      })}
                    </span>
                  </div>
                )}
              </div>

              {activeTab === "support" && (
                <div className="mb-6 rounded-2xl border border-[var(--lavender-100)] bg-[var(--warm-50)] p-4 flex items-start gap-3">
                  <div className="w-9 h-9 rounded-2xl bg-white flex items-center justify-center shadow-sm">
                    <Mail className="w-4 h-4" style={{ color: "var(--lavender-600)" }} />
                  </div>
                  <div className="text-sm" style={{ color: "var(--warm-600)" }}>
                    <p className="font-medium mb-1">Need help or have a privacy question?</p>
                    <p className="mb-1">
                      You can reach the EmpowerHealth team using the contact details published below. Please do not
                      include personal medical details in email.
                    </p>
                  </div>
                </div>
              )}

              {currentDoc.contentType === "file" && currentDoc.publicUrl ? (
                <p className="text-sm" style={{ color: "var(--warm-600)" }}>
                  This document is available as a file.{" "}
                  <a
                    href={currentDoc.publicUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="underline"
                    style={{ color: "var(--lavender-600)" }}
                  >
                    Open document
                  </a>
                  .
                </p>
              ) : (
                <MarkdownRenderer content={currentDoc.content || ""} />
              )}
            </>
          )}
        </main>

        <footer className="px-8 py-4 border-t border-[var(--lavender-100)] text-xs text-center">
          <p style={{ color: "var(--warm-500)" }}>
            EmpowerHealth Watch is an educational and support tool and does not replace professional medical advice,
            diagnosis, or treatment. If you are experiencing an emergency, call 911 or your local emergency number.
          </p>
        </footer>
      </div>
    </div>
  );
}

