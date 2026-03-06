import { Save, Calendar, Loader2, FileText, Edit2, Eye } from "lucide-react";
import { useState, useEffect } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { 
  saveDocument, 
  getDocument, 
  getDocumentHistory,
  DocumentType 
} from "../../lib/documentation";
import { format } from "date-fns";
import { MarkdownRenderer } from "../../components/MarkdownRenderer";
import { Textarea } from "../components/ui/textarea";

export function Documentation() {
  const { userProfile, isAdmin } = useAuth();
  const [activeTab, setActiveTab] = useState<"privacy" | "terms" | "support">("privacy");
  const [documents, setDocuments] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [editing, setEditing] = useState(false);
  const [editContent, setEditContent] = useState("");
  const [editNotes, setEditNotes] = useState("");

  const documentTypes: Record<string, DocumentType> = {
    privacy: 'privacy_policy',
    terms: 'terms_of_service',
    support: 'contact_support',
  };

  useEffect(() => {
    loadDocuments();
  }, []);

  useEffect(() => {
    // Load content when switching tabs or when document loads
    const currentDoc = documents[activeTab];
    if (currentDoc && currentDoc.content) {
      setEditContent(currentDoc.content);
    } else {
      setEditContent("");
    }
    setEditing(false);
  }, [activeTab, documents]);

  async function loadDocuments() {
    setLoading(true);
    try {
      const docs: Record<string, any> = {};
      for (const [key, docType] of Object.entries(documentTypes)) {
        const doc = await getDocument(docType);
        if (doc) {
          docs[key] = doc;
        }
      }
      setDocuments(docs);
    } catch (err: any) {
      setError(err.message || "Failed to load documents");
    } finally {
      setLoading(false);
    }
  }

  function handleStartEdit() {
    const currentDoc = documents[activeTab];
    setEditContent(currentDoc?.content || "");
    setEditNotes("");
    setEditing(true);
  }

  function handleCancelEdit() {
    const currentDoc = documents[activeTab];
    setEditContent(currentDoc?.content || "");
    setEditNotes("");
    setEditing(false);
  }

  async function handleSave() {
    if (!userProfile || !editContent.trim()) {
      setError("Content cannot be empty");
      return;
    }

    setError("");
    setSuccess("");
    setSaving(true);

    try {
      const docType = documentTypes[activeTab];
      await saveDocument(
        docType,
        editContent.trim(),
        userProfile.uid,
        editNotes.trim() || undefined
      );
      setSuccess("Document saved successfully");
      setEditing(false);
      await loadDocuments();
    } catch (err: any) {
      setError(err.message || "Failed to save document");
    } finally {
      setSaving(false);
    }
  }

  const currentDoc = documents[activeTab];
  const hasContent = currentDoc?.content && currentDoc.content.trim().length > 0;
  const isFileBased = currentDoc?.contentType === 'file';

  return (
    <div className="p-8">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl mb-2" style={{ color: 'var(--warm-600)' }}>
            Documentation
          </h1>
          <p style={{ color: 'var(--warm-400)' }}>
            Manage platform documentation and legal resources
          </p>
        </div>

        {error && (
          <div className="mb-4 p-4 rounded-xl" style={{ 
            backgroundColor: '#fee2e2',
            color: '#dc2626',
          }}>
            {error}
          </div>
        )}

        {success && (
          <div className="mb-4 p-4 rounded-xl" style={{ 
            backgroundColor: '#d1fae5',
            color: '#065f46',
          }}>
            {success}
          </div>
        )}

        {/* Tab Navigation */}
        <div className="flex gap-2 mb-6 border-b" style={{ borderColor: 'var(--lavender-200)' }}>
          <button
            onClick={() => setActiveTab("privacy")}
            className={`px-6 py-3 transition-all border-b-2 ${
              activeTab === "privacy" ? "border-lavender-500" : "border-transparent"
            }`}
            style={{
              color: activeTab === "privacy" ? 'var(--lavender-600)' : 'var(--warm-500)',
              borderBottomColor: activeTab === "privacy" ? 'var(--lavender-500)' : 'transparent',
            }}
          >
            Privacy Policy
          </button>
          <button
            onClick={() => setActiveTab("terms")}
            className={`px-6 py-3 transition-all border-b-2 ${
              activeTab === "terms" ? "border-lavender-500" : "border-transparent"
            }`}
            style={{
              color: activeTab === "terms" ? 'var(--lavender-600)' : 'var(--warm-500)',
              borderBottomColor: activeTab === "terms" ? 'var(--lavender-500)' : 'transparent',
            }}
          >
            Terms & Conditions
          </button>
          <button
            onClick={() => setActiveTab("support")}
            className={`px-6 py-3 transition-all border-b-2 ${
              activeTab === "support" ? "border-lavender-500" : "border-transparent"
            }`}
            style={{
              color: activeTab === "support" ? 'var(--lavender-600)' : 'var(--warm-500)',
              borderBottomColor: activeTab === "support" ? 'var(--lavender-500)' : 'transparent',
            }}
          >
            Contact / Support
          </button>
        </div>

        {/* Tab Content */}
        <div
          className="p-8 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: 'var(--lavender-200)',
          }}
        >
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="w-8 h-8 animate-spin" style={{ color: 'var(--lavender-500)' }} />
            </div>
          ) : (
            <>
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h2 className="mb-2" style={{ color: 'var(--warm-600)' }}>
                    {activeTab === "privacy" && "Privacy Policy"}
                    {activeTab === "terms" && "Terms & Conditions"}
                    {activeTab === "support" && "Contact / Support"}
                  </h2>
                  {currentDoc && (
                    <div className="flex items-center gap-2 text-sm" style={{ color: 'var(--warm-400)' }}>
                      <Calendar className="w-4 h-4" />
                      <span>
                        Last updated: {currentDoc.updatedAt ? format(currentDoc.updatedAt, 'MMMM d, yyyy') : 'Unknown'}
                      </span>
                      <span>•</span>
                      <span>Version {currentDoc.version || 1}</span>
                    </div>
                  )}
                </div>
                {isAdmin() && !editing && (
                  <button
                    onClick={handleStartEdit}
                    className="flex items-center gap-2 px-4 py-2 rounded-xl transition-all hover:shadow-sm"
                    style={{
                      backgroundColor: 'var(--lavender-200)',
                      color: 'var(--lavender-600)',
                    }}
                  >
                    <Edit2 className="w-4 h-4" />
                    {hasContent ? "Edit Document" : "Create Document"}
                  </button>
                )}
              </div>

              {editing ? (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm mb-2 font-medium" style={{ color: 'var(--warm-600)' }}>
                      Document Content (Markdown supported)
                    </label>
                    <Textarea
                      value={editContent}
                      onChange={(e) => setEditContent(e.target.value)}
                      placeholder="Enter document content here...&#10;&#10;You can use Markdown formatting:&#10;# Heading&#10;## Subheading&#10;**Bold text**&#10;*Italic text*&#10;- List item&#10;1. Numbered item"
                      rows={20}
                      className="w-full font-mono text-sm"
                      style={{
                        backgroundColor: 'var(--warm-50)',
                        borderColor: 'var(--lavender-200)',
                        color: 'var(--warm-700)',
                      }}
                    />
                    <p className="text-xs mt-2" style={{ color: 'var(--warm-500)' }}>
                      Supports Markdown: **bold**, *italic*, # headings, - lists, [links](url)
                    </p>
                  </div>

                  <div>
                    <label className="block text-sm mb-2 font-medium" style={{ color: 'var(--warm-600)' }}>
                      Change Notes (Optional)
                    </label>
                    <input
                      type="text"
                      value={editNotes}
                      onChange={(e) => setEditNotes(e.target.value)}
                      placeholder="Brief description of changes..."
                      className="w-full px-4 py-2 rounded-xl border"
                      style={{
                        backgroundColor: 'var(--warm-50)',
                        borderColor: 'var(--lavender-200)',
                      }}
                    />
                  </div>

                  <div className="flex gap-3">
                    <button
                      onClick={handleSave}
                      disabled={saving || !editContent.trim()}
                      className="flex items-center gap-2 px-6 py-3 rounded-xl transition-all hover:shadow-md disabled:opacity-50"
                      style={{
                        backgroundColor: 'var(--lavender-500)',
                        color: 'white',
                      }}
                    >
                      <Save className="w-4 h-4" />
                      {saving ? "Saving..." : "Save Document"}
                    </button>
                    <button
                      onClick={handleCancelEdit}
                      disabled={saving}
                      className="px-6 py-3 rounded-xl transition-all"
                      style={{
                        backgroundColor: 'var(--warm-100)',
                        color: 'var(--warm-600)',
                      }}
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              ) : (
                <>
                  {hasContent && !isFileBased ? (
                    <div className="space-y-4">
                      <div className="prose max-w-none p-6 rounded-xl border" style={{
                        backgroundColor: 'var(--lavender-50)',
                        borderColor: 'var(--lavender-200)',
                      }}>
                        <MarkdownRenderer content={currentDoc.content} />
                      </div>
                    </div>
                  ) : isFileBased && currentDoc?.publicUrl ? (
                    <div className="space-y-4">
                      <div className="p-4 rounded-xl border" style={{
                        backgroundColor: 'var(--lavender-50)',
                        borderColor: 'var(--lavender-200)',
                      }}>
                        <div className="flex items-center gap-2 mb-2">
                          <FileText className="w-5 h-5" style={{ color: 'var(--lavender-600)' }} />
                          <a
                            href={currentDoc.publicUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-sm flex items-center gap-1 hover:underline"
                            style={{ color: 'var(--lavender-600)' }}
                          >
                            View Document
                          </a>
                        </div>
                        <p className="text-xs" style={{ color: 'var(--warm-500)' }}>
                          This document is file-based. To edit, delete and recreate as text-based.
                        </p>
                      </div>
                    </div>
                  ) : (
                    <div className="text-center py-12" style={{ color: 'var(--warm-500)' }}>
                      {isAdmin() ? (
                        <>
                          <p className="mb-4">No document created yet.</p>
                          <p className="text-sm">Click "Create Document" to add content.</p>
                        </>
                      ) : (
                        <p>No document available.</p>
                      )}
                    </div>
                  )}
                </>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
