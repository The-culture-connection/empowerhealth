import { Shield, Lock, Heart, Download, Trash2, Eye, UserCheck } from "lucide-react";
import { useState } from "react";

export function ConsentModal({ onAccept }: { onAccept: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5">
      <div className="bg-white rounded-3xl max-w-md w-full shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] p-6 text-white">
          <div className="w-14 h-14 rounded-2xl bg-white/20 flex items-center justify-center mb-4">
            <Heart className="w-7 h-7" />
          </div>
          <h2 className="text-xl mb-2">Your health story belongs to you</h2>
          <p className="text-white/90 text-sm">
            We keep it safe and only use it to support your pregnancy journey.
          </p>
        </div>

        {/* Content */}
        <div className="p-6 space-y-4">
          <div className="flex items-start gap-3">
            <div className="w-8 h-8 rounded-xl bg-purple-50 flex items-center justify-center flex-shrink-0">
              <Lock className="w-4 h-4 text-[#663399]" />
            </div>
            <div>
              <h3 className="text-sm font-medium mb-1">Secure & Private</h3>
              <p className="text-sm text-gray-600">
                Your information is encrypted and stored securely. We never sell your data.
              </p>
            </div>
          </div>

          <div className="flex items-start gap-3">
            <div className="w-8 h-8 rounded-xl bg-purple-50 flex items-center justify-center flex-shrink-0">
              <UserCheck className="w-4 h-4 text-[#663399]" />
            </div>
            <div>
              <h3 className="text-sm font-medium mb-1">You're in Control</h3>
              <p className="text-sm text-gray-600">
                Choose what to share and with whom. You can change your mind anytime.
              </p>
            </div>
          </div>

          <div className="flex items-start gap-3">
            <div className="w-8 h-8 rounded-xl bg-purple-50 flex items-center justify-center flex-shrink-0">
              <Shield className="w-4 h-4 text-[#663399]" />
            </div>
            <div>
              <h3 className="text-sm font-medium mb-1">Here to Support</h3>
              <p className="text-sm text-gray-600">
                This app helps you understand and advocate for your care. It doesn't replace your provider.
              </p>
            </div>
          </div>

          {/* Research Opt-in */}
          <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl p-4 border border-blue-100">
            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                className="mt-1 w-5 h-5 rounded border-gray-300 text-[#663399] focus:ring-[#663399]/20"
              />
              <div>
                <span className="block text-sm font-medium mb-1">Help improve care for others</span>
                <span className="text-xs text-gray-600">
                  You can help improve maternal healthcare by sharing anonymous insights with research partners. You can opt out anytime.
                </span>
              </div>
            </label>
          </div>

          <p className="text-xs text-gray-500 leading-relaxed">
            By continuing, you agree that you understand how we protect your information and that this app is a tool for support and education—not medical advice.
          </p>
        </div>

        {/* Actions */}
        <div className="p-6 pt-0">
          <button
            onClick={onAccept}
            className="w-full py-3.5 px-4 rounded-2xl bg-[#663399] text-white hover:bg-[#552288] transition-colors shadow-sm"
          >
            Continue with understanding
          </button>
        </div>
      </div>
    </div>
  );
}

export function PHIBoundaryNotice() {
  return (
    <div className="bg-gradient-to-br from-[#cbbec9]/20 to-[#cbbec9]/10 rounded-2xl p-4 border border-[#cbbec9]/30">
      <div className="flex items-start gap-3">
        <div className="w-8 h-8 rounded-xl bg-white flex items-center justify-center flex-shrink-0">
          <Heart className="w-4 h-4 text-[#663399]" />
        </div>
        <div>
          <p className="text-sm text-gray-700">
            This tool helps you understand your care. It does not replace your provider.
          </p>
        </div>
      </div>
    </div>
  );
}

export function SecureIndicator() {
  return (
    <div className="inline-flex items-center gap-1.5 text-xs text-gray-500">
      <Lock className="w-3 h-3" />
      <span>Private and encrypted</span>
    </div>
  );
}

export function EmergencyFooter() {
  return (
    <div className="text-center py-4 border-t border-gray-100">
      <p className="text-sm text-gray-600 mb-1">
        For urgent concerns, contact your care provider
      </p>
      <p className="text-xs text-gray-500">
        Or call the National Maternal Mental Health Hotline:{" "}
        <a href="tel:1-833-943-5746" className="text-[#663399] font-medium">
          1-833-9-HELP4MOMS
        </a>
      </p>
    </div>
  );
}

export function PrivacySettings() {
  const [researchOptIn, setResearchOptIn] = useState(false);
  const [shareWithProviders, setShareWithProviders] = useState(true);

  return (
    <div className="space-y-4">
      {/* Data Usage Card */}
      <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100">
        <div className="flex items-start gap-3 mb-4">
          <div className="w-10 h-10 rounded-2xl bg-purple-50 flex items-center justify-center flex-shrink-0">
            <Shield className="w-5 h-5 text-[#663399]" />
          </div>
          <div>
            <h3 className="mb-1">How Your Data Is Used</h3>
            <p className="text-sm text-gray-600">
              We take your privacy seriously. Here's how we protect your information.
            </p>
          </div>
        </div>

        <div className="space-y-3 mb-4">
          <div className="flex items-start gap-2">
            <div className="w-5 h-5 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0 mt-0.5">
              <span className="text-green-600 text-xs">✓</span>
            </div>
            <p className="text-sm text-gray-700">Stored securely with encryption</p>
          </div>
          <div className="flex items-start gap-2">
            <div className="w-5 h-5 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0 mt-0.5">
              <span className="text-green-600 text-xs">✓</span>
            </div>
            <p className="text-sm text-gray-700">Never sold to third parties</p>
          </div>
          <div className="flex items-start gap-2">
            <div className="w-5 h-5 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0 mt-0.5">
              <span className="text-green-600 text-xs">✓</span>
            </div>
            <p className="text-sm text-gray-700">Only shared with your permission</p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <button className="py-2.5 px-4 rounded-2xl bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30 transition-colors flex items-center justify-center gap-2 text-sm">
            <Download className="w-4 h-4" />
            <span>Download</span>
          </button>
          <button className="py-2.5 px-4 rounded-2xl bg-gray-50 text-gray-700 border border-gray-200 hover:border-rose-300 hover:text-rose-600 transition-colors flex items-center justify-center gap-2 text-sm">
            <Trash2 className="w-4 h-4" />
            <span>Delete</span>
          </button>
        </div>
      </div>

      {/* Privacy Controls */}
      <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100">
        <h3 className="mb-4">Privacy Controls</h3>

        <div className="space-y-4">
          {/* Provider Sharing */}
          <div className="flex items-start justify-between gap-3">
            <div className="flex-1">
              <h4 className="text-sm font-medium mb-1">Share with my care team</h4>
              <p className="text-xs text-gray-600">
                Allow your birth plan and visit summaries to be shared with providers you choose
              </p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer flex-shrink-0">
              <input
                type="checkbox"
                checked={shareWithProviders}
                onChange={(e) => setShareWithProviders(e.target.checked)}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-[#663399]/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#663399]"></div>
            </label>
          </div>

          {/* Research Participation */}
          <div className="flex items-start justify-between gap-3 pt-4 border-t border-gray-100">
            <div className="flex-1">
              <h4 className="text-sm font-medium mb-1">Help improve maternal care</h4>
              <p className="text-xs text-gray-600">
                Share anonymous insights with research partners to improve care for others
              </p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer flex-shrink-0">
              <input
                type="checkbox"
                checked={researchOptIn}
                onChange={(e) => setResearchOptIn(e.target.checked)}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-[#663399]/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#663399]"></div>
            </label>
          </div>
        </div>
      </div>

      {/* View Privacy Policy */}
      <button className="w-full py-3 px-4 rounded-2xl bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30 transition-colors flex items-center justify-center gap-2 text-sm">
        <Eye className="w-4 h-4" />
        <span>View full privacy policy</span>
      </button>
    </div>
  );
}

export function ExplanationDisclaimer() {
  return (
    <p className="text-xs text-gray-500 text-center py-3 border-t border-gray-100">
      This explanation is for understanding only
    </p>
  );
}

export function ProviderReviewBoundary() {
  return (
    <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl p-4 border border-blue-100 mb-5">
      <p className="text-sm text-gray-700">
        <span className="font-medium">Reviews reflect personal experiences.</span> Every pregnancy journey is unique. Use these insights to guide your choice, and trust your own needs.
      </p>
    </div>
  );
}