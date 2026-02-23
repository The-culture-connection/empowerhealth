import { Heart, Users, Home, Pill, AlertTriangle, Share2, Download, Sparkles } from "lucide-react";
import { useState } from "react";
import { PHIBoundaryNotice, SecureIndicator, EmergencyFooter } from "./PrivacyComponents";

export function BirthPlan() {
  const [preferences, setPreferences] = useState({
    support: [] as string[],
    environment: [] as string[],
    pain: [] as string[],
  });

  const togglePreference = (category: keyof typeof preferences, item: string) => {
    setPreferences((prev) => ({
      ...prev,
      [category]: prev[category].includes(item)
        ? prev[category].filter((i) => i !== item)
        : [...prev[category], item],
    }));
  };

  return (
    <div className="p-6 pb-24">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl mb-2 text-[#4a3f52] font-normal">Birth plan</h1>
        <p className="text-[#8b7a95] font-light">Share your preferences with your care team</p>
      </div>

      {/* PHI Boundary Notice */}
      <div className="mb-4">
        <PHIBoundaryNotice />
      </div>

      {/* Intro */}
      <div className="bg-gradient-to-br from-[#ebe4f3] via-[#e0d5eb] to-[#e8dfe8] rounded-[32px] p-7 shadow-[0_4px_24px_rgba(0,0,0,0.06)] mb-8 relative overflow-hidden">
        {/* Subtle background pattern */}
        <div className="absolute inset-0 opacity-5">
          <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-white blur-3xl"></div>
          <div className="absolute bottom-0 left-0 w-40 h-40 rounded-full bg-[#d4c5e0] blur-3xl"></div>
        </div>
        
        <div className="relative">
          <h2 className="text-lg mb-2 text-[#4a3f52] font-normal">Your voice matters</h2>
          <p className="text-[#6b5c75] text-sm mb-4 font-light leading-relaxed">
            This plan helps you communicate your wishes. Remember: plans can change, and that's okay. This is about starting a conversation with your care team.
          </p>
          <SecureIndicator />
        </div>
      </div>

      {/* Support Team */}
      <section className="mb-8">
        <div className="flex items-center gap-2 mb-4">
          <Users className="w-5 h-5 text-[#a89cb5] stroke-[1.5]" />
          <h2 className="text-[#6b5c75] font-normal text-base tracking-wide">My support team</h2>
        </div>
        <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
          <div className="space-y-4">
            <div>
              <label className="text-sm text-[#8b7a95] mb-2 block font-light">Who do you want with you?</label>
              <input
                type="text"
                placeholder="Partner, family, doula..."
                className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] placeholder:text-[#b5a8c2] font-light"
              />
            </div>
            <div>
              <label className="text-sm text-[#8b7a95] mb-2 block font-light">Doula or birth coach</label>
              <input
                type="text"
                placeholder="Name and contact (optional)"
                className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] placeholder:text-[#b5a8c2] font-light"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Birth Environment */}
      <section className="mb-8">
        <div className="flex items-center gap-2 mb-4">
          <Home className="w-5 h-5 text-[#a89cb5] stroke-[1.5]" />
          <h2 className="text-[#6b5c75] font-normal text-base tracking-wide">My birth environment</h2>
        </div>
        <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
          <p className="text-sm text-[#8b7a95] mb-4 font-light">What helps you feel calm and safe?</p>
          <div className="space-y-2">
            {["Dim lighting", "Music playing", "Quiet room", "Freedom to move around", "Minimal interruptions"].map(
              (item) => (
                <button
                  key={item}
                  onClick={() => togglePreference("environment", item)}
                  className={`w-full text-left px-5 py-3.5 rounded-[20px] transition-all font-light ${
                    preferences.environment.includes(item)
                      ? "bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] text-white shadow-[0_2px_12px_rgba(168,156,181,0.2)]"
                      : "bg-[#f7f5f9] text-[#6b5c75] hover:bg-[#ede7f3]/50"
                  }`}
                >
                  {item} {preferences.environment.includes(item) && "✓"}
                </button>
              )
            )}
          </div>
        </div>
      </section>

      {/* Pain Management */}
      <section className="mb-8">
        <div className="flex items-center gap-2 mb-4">
          <Heart className="w-5 h-5 text-[#c9a9c0] stroke-[1.5]" />
          <h2 className="text-[#6b5c75] font-normal text-base tracking-wide">Pain management preferences</h2>
        </div>
        <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
          <p className="text-sm text-[#8b7a95] mb-4 font-light">What options are you considering?</p>
          <div className="space-y-2">
            {[
              "Epidural",
              "Breathing techniques",
              "Movement and positioning",
              "Water therapy",
              "Massage",
              "I'm still deciding",
            ].map((item) => (
              <button
                key={item}
                onClick={() => togglePreference("pain", item)}
                className={`w-full text-left px-5 py-3.5 rounded-[20px] transition-all font-light ${
                  preferences.pain.includes(item)
                    ? "bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] text-white shadow-[0_2px_12px_rgba(168,156,181,0.2)]"
                    : "bg-[#f7f5f9] text-[#6b5c75] hover:bg-[#ede7f3]/50"
                }`}
              >
                {item} {preferences.pain.includes(item) && "✓"}
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* After Birth */}
      <section className="mb-8">
        <div className="flex items-center gap-2 mb-4">
          <Sparkles className="w-5 h-5 text-[#c9b087] stroke-[1.5]" />
          <h2 className="text-[#6b5c75] font-normal text-base tracking-wide">After baby arrives</h2>
        </div>
        <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
          <div className="space-y-4">
            <div>
              <label className="text-sm text-[#8b7a95] mb-2 block font-light">Skin-to-skin contact</label>
              <select className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] font-light">
                <option>Yes, immediately if possible</option>
                <option>Yes, after cleaning</option>
                <option>I'd like to decide in the moment</option>
              </select>
            </div>
            <div>
              <label className="text-sm text-[#8b7a95] mb-2 block font-light">Feeding preference</label>
              <select className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] font-light">
                <option>Breastfeeding</option>
                <option>Formula feeding</option>
                <option>Combination</option>
                <option>Still exploring options</option>
              </select>
            </div>
          </div>
        </div>
      </section>

      {/* Emergency Wishes */}
      <section className="mb-8">
        <div className="flex items-center gap-2 mb-4">
          <AlertTriangle className="w-5 h-5 text-[#c9b087] stroke-[1.5]" />
          <h2 className="text-[#6b5c75] font-normal text-base tracking-wide">If things change</h2>
        </div>
        <div className="bg-gradient-to-br from-[#faf7fb] to-[#f9f5fb] rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#f0e8f3]/50">
          <p className="text-sm text-[#6b5c75] mb-3 font-light leading-relaxed">
            If an emergency happens, who should make decisions with your medical team?
          </p>
          <input
            type="text"
            placeholder="Name of decision-maker"
            className="w-full px-5 py-3.5 rounded-[20px] bg-white/80 backdrop-blur-sm border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] placeholder:text-[#b5a8c2] font-light"
          />
        </div>
      </section>

      {/* Notes */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#6b5c75] font-normal text-base tracking-wide">Additional notes</h2>
        <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
          <textarea
            rows={4}
            placeholder="Anything else you'd like your care team to know..."
            className="w-full px-5 py-4 rounded-[20px] bg-[#f7f5f9] border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 resize-none text-[#4a3f52] placeholder:text-[#b5a8c2] font-light"
          ></textarea>
        </div>
      </section>

      {/* Actions */}
      <div className="flex gap-3 mb-8">
        <button className="flex-1 py-3.5 px-4 rounded-[24px] border border-[#d4c5e0]/50 text-[#8b7a95] hover:bg-[#f7f5f9] transition-all flex items-center justify-center gap-2 font-light shadow-[0_2px_12px_rgba(0,0,0,0.03)]">
          <Download className="w-4 h-4 stroke-[1.5]" />
          Download PDF
        </button>
        <button className="flex-1 py-3.5 px-4 rounded-[24px] bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] text-white hover:shadow-[0_4px_20px_rgba(168,156,181,0.25)] transition-all flex items-center justify-center gap-2 font-light shadow-[0_2px_12px_rgba(168,156,181,0.15)]">
          <Share2 className="w-4 h-4 stroke-[1.5]" />
          Share with team
        </button>
      </div>

      {/* Emergency Footer */}
      <div className="mt-6">
        <EmergencyFooter />
      </div>
    </div>
  );
}
