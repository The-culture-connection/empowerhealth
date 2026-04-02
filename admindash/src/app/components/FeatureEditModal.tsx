import { X, Save } from "lucide-react";
import { useState, useEffect } from "react";
import { TechnologyFeature, updateFeature, FeatureUpdate } from "../../lib/features";
import { useAuth } from "../../contexts/AuthContext";

interface FeatureEditModalProps {
  feature: TechnologyFeature;
  onClose: () => void;
  onSave: () => void;
}

export function FeatureEditModal({ feature, onClose, onSave }: FeatureEditModalProps) {
  const { isAdmin } = useAuth();
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [formData, setFormData] = useState<FeatureUpdate>({
    name: feature.name,
    description: feature.description,
    updateHighlight: feature.updateHighlight || "",
    domain: feature.domain,
    category: feature.category,
    tags: feature.tags || [],
    implementation: feature.implementation ? {
      architecture: feature.implementation.architecture,
      components: feature.implementation.components,
      dataFlow: feature.implementation.dataFlow,
    } : undefined,
    visible: feature.visible,
    displayOrder: feature.displayOrder,
  });

  useEffect(() => {
    if (!isAdmin()) {
      onClose();
    }
  }, [isAdmin, onClose]);

  async function handleSave() {
    if (!isAdmin()) {
      setError("Only admins can edit features");
      return;
    }

    setSaving(true);
    setError(null);

    try {
      await updateFeature(feature.id, formData);
      onSave();
      onClose();
    } catch (err: any) {
      console.error("Failed to update feature:", err);
      setError(err.message || "Failed to update feature");
    } finally {
      setSaving(false);
    }
  }

  if (!isAdmin()) {
    return null;
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0"
        style={{ backgroundColor: 'rgba(0, 0, 0, 0.5)' }}
        onClick={onClose}
      />

      {/* Modal */}
      <div
        className="relative w-full max-w-4xl max-h-[90vh] overflow-y-auto rounded-2xl shadow-2xl"
        style={{ backgroundColor: 'white' }}
      >
        {/* Modal Header */}
        <div
          className="sticky top-0 p-6 border-b flex items-center justify-between"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
            zIndex: 10,
          }}
        >
          <h2 className="text-2xl" style={{ color: '#424242' }}>
            Edit Feature: {feature.name}
          </h2>
          <button
            onClick={onClose}
            className="p-2 rounded-lg transition-colors"
            style={{ color: '#757575' }}
            onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
            onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Modal Content */}
        <div className="p-6">
          {error && (
            <div
              className="mb-6 p-4 rounded-lg"
              style={{
                backgroundColor: '#fff3e0',
                borderColor: '#ff9800',
                border: '1px solid #ff9800',
              }}
            >
              <p style={{ color: '#e65100' }}>{error}</p>
            </div>
          )}

          <div className="space-y-6">
            {/* Basic Information */}
            <div>
              <label className="block text-sm mb-2" style={{ color: '#424242' }}>
                Feature Name *
              </label>
              <input
                type="text"
                value={formData.name || ""}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full px-4 py-2 rounded-xl border"
                style={{
                  backgroundColor: 'white',
                  borderColor: '#e0e0e0',
                  color: '#424242',
                }}
              />
            </div>

            <div>
              <label className="block text-sm mb-2" style={{ color: '#424242' }}>
                Description *
              </label>
              <textarea
                value={formData.description || ""}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                rows={4}
                className="w-full px-4 py-2 rounded-xl border"
                style={{
                  backgroundColor: 'white',
                  borderColor: '#e0e0e0',
                  color: '#424242',
                }}
              />
            </div>

            <div>
              <label className="block text-sm mb-2" style={{ color: '#424242' }}>
                Update Highlight
              </label>
              <input
                type="text"
                value={formData.updateHighlight || ""}
                onChange={(e) => setFormData({ ...formData, updateHighlight: e.target.value })}
                placeholder="Brief highlight of latest update"
                className="w-full px-4 py-2 rounded-xl border"
                style={{
                  backgroundColor: 'white',
                  borderColor: '#e0e0e0',
                  color: '#424242',
                }}
              />
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <label className="block text-sm mb-2" style={{ color: '#424242' }}>
                  Domain *
                </label>
                <input
                  type="text"
                  value={formData.domain || ""}
                  onChange={(e) => setFormData({ ...formData, domain: e.target.value })}
                  className="w-full px-4 py-2 rounded-xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: '#e0e0e0',
                    color: '#424242',
                  }}
                />
              </div>

              <div>
                <label className="block text-sm mb-2" style={{ color: '#424242' }}>
                  Category *
                </label>
                <input
                  type="text"
                  value={formData.category || ""}
                  onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                  className="w-full px-4 py-2 rounded-xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: '#e0e0e0',
                    color: '#424242',
                  }}
                />
              </div>
            </div>

            {/* Implementation Details */}
            <div>
              <h3 className="text-lg mb-4" style={{ color: '#424242' }}>
                Implementation Details
              </h3>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm mb-2" style={{ color: '#424242' }}>
                    Architecture Overview
                  </label>
                  <textarea
                    value={formData.implementation?.architecture || ""}
                    onChange={(e) => setFormData({
                      ...formData,
                      implementation: {
                        ...formData.implementation,
                        architecture: e.target.value,
                        components: formData.implementation?.components || [],
                        dataFlow: formData.implementation?.dataFlow || "",
                      } as any,
                    })}
                    rows={3}
                    className="w-full px-4 py-2 rounded-xl border"
                    style={{
                      backgroundColor: 'white',
                      borderColor: '#e0e0e0',
                      color: '#424242',
                    }}
                  />
                </div>

                <div>
                  <label className="block text-sm mb-2" style={{ color: '#424242' }}>
                    Key Components (comma-separated)
                  </label>
                  <input
                    type="text"
                    value={formData.implementation?.components?.join(", ") || ""}
                    onChange={(e) => setFormData({
                      ...formData,
                      implementation: {
                        ...formData.implementation,
                        components: e.target.value.split(",").map(c => c.trim()).filter(c => c),
                        architecture: formData.implementation?.architecture || "",
                        dataFlow: formData.implementation?.dataFlow || "",
                      } as any,
                    })}
                    placeholder="Component 1, Component 2, Component 3"
                    className="w-full px-4 py-2 rounded-xl border"
                    style={{
                      backgroundColor: 'white',
                      borderColor: '#e0e0e0',
                      color: '#424242',
                    }}
                  />
                </div>

                <div>
                  <label className="block text-sm mb-2" style={{ color: '#424242' }}>
                    Data Flow
                  </label>
                  <textarea
                    value={formData.implementation?.dataFlow || ""}
                    onChange={(e) => setFormData({
                      ...formData,
                      implementation: {
                        ...formData.implementation,
                        dataFlow: e.target.value,
                        architecture: formData.implementation?.architecture || "",
                        components: formData.implementation?.components || [],
                      } as any,
                    })}
                    rows={2}
                    className="w-full px-4 py-2 rounded-xl border font-mono text-sm"
                    style={{
                      backgroundColor: 'white',
                      borderColor: '#e0e0e0',
                      color: '#424242',
                    }}
                  />
                </div>
              </div>
            </div>

            {/* Tags */}
            <div>
              <label className="block text-sm mb-2" style={{ color: '#424242' }}>
                Tags (comma-separated)
              </label>
              <input
                type="text"
                value={formData.tags?.join(", ") || ""}
                onChange={(e) => setFormData({
                  ...formData,
                  tags: e.target.value.split(",").map(t => t.trim()).filter(t => t),
                })}
                placeholder="tag1, tag2, tag3"
                className="w-full px-4 py-2 rounded-xl border"
                style={{
                  backgroundColor: 'white',
                  borderColor: '#e0e0e0',
                  color: '#424242',
                }}
              />
            </div>

            {/* Visibility and Order */}
            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={formData.visible !== false}
                    onChange={(e) => setFormData({ ...formData, visible: e.target.checked })}
                    className="w-4 h-4"
                  />
                  <span className="text-sm" style={{ color: '#424242' }}>Visible</span>
                </label>
              </div>

              <div>
                <label className="block text-sm mb-2" style={{ color: '#424242' }}>
                  Display Order
                </label>
                <input
                  type="number"
                  value={formData.displayOrder || 0}
                  onChange={(e) => setFormData({ ...formData, displayOrder: parseInt(e.target.value) || 0 })}
                  className="w-full px-4 py-2 rounded-xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: '#e0e0e0',
                    color: '#424242',
                  }}
                />
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-3 mt-8">
            <button
              onClick={handleSave}
              disabled={saving || !formData.name || !formData.description}
              className="px-6 py-2 rounded-xl transition-all flex items-center gap-2"
              style={{
                backgroundColor: saving ? '#bdbdbd' : '#9575cd',
                color: 'white',
              }}
            >
              <Save className="w-4 h-4" />
              {saving ? "Saving..." : "Save Changes"}
            </button>
            <button
              onClick={onClose}
              className="px-6 py-2 rounded-xl transition-all"
              style={{
                backgroundColor: '#f5f5f5',
                color: '#616161',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#eeeeee')}
              onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
