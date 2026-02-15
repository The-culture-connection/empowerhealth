import { Heart, Users, Home, Pill, AlertTriangle, Share2, Download } from "lucide-react";
import { useState, useEffect } from "react";
import { authService } from "../../services/authService";
import { databaseService, BirthPlan as BirthPlanType } from "../../services/databaseService";

export function BirthPlan() {
  const [plan, setPlan] = useState<BirthPlanType | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [supportTeam, setSupportTeam] = useState({
    whoWithYou: "",
    doula: "",
  });
  const [environment, setEnvironment] = useState<string[]>([]);
  const [painManagement, setPainManagement] = useState<string[]>([]);
  const [afterBirth, setAfterBirth] = useState({
    skinToSkin: "",
    feeding: "",
  });
  const [emergencyDecisionMaker, setEmergencyDecisionMaker] = useState("");
  const [additionalNotes, setAdditionalNotes] = useState("");

  useEffect(() => {
    const user = authService.currentUser;
    if (!user) return;

    databaseService.getBirthPlans(user.uid).then((plans) => {
      if (plans.length > 0) {
        const latestPlan = plans[0];
        setPlan(latestPlan);
        setSupportTeam(latestPlan.supportTeam || { whoWithYou: "", doula: "" });
        setEnvironment(latestPlan.environment || []);
        setPainManagement(latestPlan.painManagement || []);
        setAfterBirth(latestPlan.afterBirth || { skinToSkin: "", feeding: "" });
        setEmergencyDecisionMaker(latestPlan.emergencyDecisionMaker || "");
        setAdditionalNotes(latestPlan.additionalNotes || "");
      }
      setLoading(false);
    });
  }, []);

  const toggleEnvironment = (item: string) => {
    setEnvironment((prev) =>
      prev.includes(item) ? prev.filter((i) => i !== item) : [...prev, item]
    );
  };

  const togglePainManagement = (item: string) => {
    setPainManagement((prev) =>
      prev.includes(item) ? prev.filter((i) => i !== item) : [...prev, item]
    );
  };

  const handleSave = async () => {
    const user = authService.currentUser;
    if (!user) return;

    setSaving(true);
    try {
      await databaseService.saveBirthPlan({
        id: plan?.id,
        userId: user.uid,
        supportTeam,
        environment,
        painManagement,
        afterBirth,
        emergencyDecisionMaker,
        additionalNotes,
      });
      alert("Birth plan saved successfully!");
    } catch (error: any) {
      alert(`Error saving birth plan: ${error.message}`);
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="p-5">
        <div className="flex items-center justify-center h-64">
          <div className="text-gray-500">Loading...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-5">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl mb-2">Birth Plan Builder</h1>
        <p className="text-gray-600">Share your preferences with your care team</p>
      </div>

      {/* Intro */}
      <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] rounded-3xl p-6 text-white shadow-md mb-6">
        <h2 className="text-lg mb-2">Your Voice Matters</h2>
        <p className="text-white/90 text-sm">
          This plan helps you communicate your wishes. Remember: plans can change, and that's okay. This is about starting a conversation with your care team.
        </p>
      </div>

      {/* Support Team */}
      <section className="mb-6">
        <div className="flex items-center gap-2 mb-3">
          <Users className="w-5 h-5 text-[#663399]" />
          <h2>My Support Team</h2>
        </div>
        <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
          <div className="space-y-3">
            <div>
              <label className="text-sm text-gray-600 mb-2 block">Who do you want with you?</label>
              <input
                type="text"
                value={supportTeam.whoWithYou}
                onChange={(e) => setSupportTeam({ ...supportTeam, whoWithYou: e.target.value })}
                placeholder="Partner, family, doula..."
                className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20"
              />
            </div>
            <div>
              <label className="text-sm text-gray-600 mb-2 block">Doula or birth coach</label>
              <input
                type="text"
                value={supportTeam.doula}
                onChange={(e) => setSupportTeam({ ...supportTeam, doula: e.target.value })}
                placeholder="Name and contact (optional)"
                className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Birth Environment */}
      <section className="mb-6">
        <div className="flex items-center gap-2 mb-3">
          <Home className="w-5 h-5 text-[#663399]" />
          <h2>My Birth Environment</h2>
        </div>
        <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
          <p className="text-sm text-gray-600 mb-4">What helps you feel calm and safe?</p>
          <div className="space-y-2">
            {["Dim lighting", "Music playing", "Quiet room", "Freedom to move around", "Minimal interruptions"].map(
              (item) => (
                <button
                  key={item}
                  onClick={() => toggleEnvironment(item)}
                  className={`w-full text-left px-4 py-3 rounded-2xl transition-colors ${
                    environment.includes(item)
                      ? "bg-[#663399] text-white"
                      : "bg-gray-50 text-gray-700 hover:bg-gray-100"
                  }`}
                >
                  {item} {environment.includes(item) && "✓"}
                </button>
              )
            )}
          </div>
        </div>
      </section>

      {/* Pain Management */}
      <section className="mb-6">
        <div className="flex items-center gap-2 mb-3">
          <Heart className="w-5 h-5 text-[#663399]" />
          <h2>Pain Management Preferences</h2>
        </div>
        <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
          <p className="text-sm text-gray-600 mb-4">What options are you considering?</p>
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
                onClick={() => togglePainManagement(item)}
                className={`w-full text-left px-4 py-3 rounded-2xl transition-colors ${
                  painManagement.includes(item)
                    ? "bg-[#663399] text-white"
                    : "bg-gray-50 text-gray-700 hover:bg-gray-100"
                }`}
              >
                {item} {painManagement.includes(item) && "✓"}
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* After Birth */}
      <section className="mb-6">
        <div className="flex items-center gap-2 mb-3">
          <Pill className="w-5 h-5 text-[#663399]" />
          <h2>After Baby Arrives</h2>
        </div>
        <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
          <div className="space-y-4">
            <div>
              <label className="text-sm text-gray-600 mb-2 block">Skin-to-skin contact</label>
              <select
                value={afterBirth.skinToSkin}
                onChange={(e) => setAfterBirth({ ...afterBirth, skinToSkin: e.target.value })}
                className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20"
              >
                <option value="">Select an option</option>
                <option>Yes, immediately if possible</option>
                <option>Yes, after cleaning</option>
                <option>I'd like to decide in the moment</option>
              </select>
            </div>
            <div>
              <label className="text-sm text-gray-600 mb-2 block">Feeding preference</label>
              <select
                value={afterBirth.feeding}
                onChange={(e) => setAfterBirth({ ...afterBirth, feeding: e.target.value })}
                className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20"
              >
                <option value="">Select an option</option>
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
      <section className="mb-6">
        <div className="flex items-center gap-2 mb-3">
          <AlertTriangle className="w-5 h-5 text-amber-600" />
          <h2>If Things Change</h2>
        </div>
        <div className="bg-gradient-to-br from-[#fef3f3] to-[#fff0f8] rounded-3xl p-5 shadow-sm border border-pink-100">
          <p className="text-sm text-gray-600 mb-3">
            If an emergency happens, who should make decisions with your medical team?
          </p>
          <input
            type="text"
            value={emergencyDecisionMaker}
            onChange={(e) => setEmergencyDecisionMaker(e.target.value)}
            placeholder="Name of decision-maker"
            className="w-full px-4 py-3 rounded-2xl bg-white border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20"
          />
        </div>
      </section>

      {/* Notes */}
      <section className="mb-6">
        <h2 className="mb-3">Additional Notes</h2>
        <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
          <textarea
            rows={4}
            value={additionalNotes}
            onChange={(e) => setAdditionalNotes(e.target.value)}
            placeholder="Anything else you'd like your care team to know..."
            className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 resize-none"
          ></textarea>
        </div>
      </section>

      {/* Actions */}
      <div className="flex gap-3 mb-6">
        <button
          onClick={() => {
            // TODO: Implement PDF download
            alert("PDF download coming soon!");
          }}
          className="flex-1 py-3 px-4 rounded-2xl border border-[#663399] text-[#663399] hover:bg-[#663399]/5 transition-colors flex items-center justify-center gap-2"
        >
          <Download className="w-4 h-4" />
          Download PDF
        </button>
        <button
          onClick={handleSave}
          disabled={saving}
          className="flex-1 py-3 px-4 rounded-2xl bg-[#663399] text-white hover:bg-[#552288] transition-colors flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Share2 className="w-4 h-4" />
          {saving ? "Saving..." : "Save Plan"}
        </button>
      </div>
    </div>
  );
}
