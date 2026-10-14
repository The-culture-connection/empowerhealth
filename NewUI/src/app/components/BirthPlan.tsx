import { Heart, Users, Home, Pill, AlertTriangle, Share2, Download, Sparkles, ChevronLeft, ChevronRight, ChevronDown, ChevronUp } from "lucide-react";
import { useState } from "react";
import { Link } from "react-router";
import { PHIBoundaryNotice, SecureIndicator, EmergencyFooter } from "./PrivacyComponents";

export function BirthPlan() {
  const [currentStep, setCurrentStep] = useState(0);
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>({});
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

  const toggleSection = (sectionId: string) => {
    setExpandedSections((prev) => ({
      ...prev,
      [sectionId]: !prev[sectionId],
    }));
  };

  const steps = [
    { id: "support", title: "Your Support Team", icon: Users },
    { id: "environment", title: "Your Birth Space", icon: Home },
    { id: "pain", title: "Comfort Options", icon: Heart },
    { id: "afterbirth", title: "After Baby Arrives", icon: Sparkles },
    { id: "emergency", title: "If Plans Change", icon: AlertTriangle },
  ];

  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] relative overflow-hidden transition-colors duration-500 p-6 pb-24">
      {/* Back Navigation */}
      <Link to="/birth-plan-builder" className="inline-flex items-center gap-2 mb-8 text-[#75657d] dark:text-[#cbbec9] hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors duration-300">
        <ChevronLeft className="w-4 h-4 stroke-[1.5]" />
        <span className="text-sm font-light tracking-wide">Birth Plans</span>
      </Link>

      {/* Header */}
      <div className="mb-6">
        <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-2 tracking-[-0.01em] transition-colors duration-300">My Birth Preferences</h1>
        <p className="text-[#75657d] dark:text-[#cbbec9] text-[15px] font-light leading-relaxed transition-colors duration-300">
          Your birth, your choices — one step at a time
        </p>
      </div>

      {/* Affirming Intro Card */}
      <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[24px] p-6 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-6 transition-all duration-500">
        {/* Warm gold glow */}
        <div className="absolute inset-0 opacity-[0.05] pointer-events-none rounded-[24px] overflow-hidden">
          <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-[#d4a574] blur-[60px]"></div>
        </div>

        <div className="relative flex items-start gap-4">
          <div className="w-12 h-12 rounded-[16px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
            <Heart className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
          </div>
          <div className="flex-1">
            <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-2 tracking-[-0.005em] transition-colors duration-300">You know what's right for you</h3>
            <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
              There's no right or wrong way to give birth. This plan helps you explore options and share what feels right with your care team. You can change your mind anytime.
            </p>
          </div>
        </div>
      </div>

      {/* Step Progress Indicator */}
      <div className="mb-8 overflow-x-auto pb-2">
        <div className="flex gap-2 min-w-max">
          {steps.map((step, index) => {
            const Icon = step.icon;
            const isActive = currentStep === index;
            const isComplete = currentStep > index;

            return (
              <button
                key={step.id}
                onClick={() => setCurrentStep(index)}
                className={`flex items-center gap-2 px-4 py-2.5 rounded-[18px] transition-all duration-300 whitespace-nowrap ${
                  isActive
                    ? "bg-gradient-to-br from-[#663399] to-[#8855bb] text-white shadow-[0_4px_16px_rgba(102,51,153,0.25)]"
                    : isComplete
                    ? "bg-gradient-to-br from-[#d4a574] to-[#e0b589] text-white shadow-[0_2px_12px_rgba(212,165,116,0.2)]"
                    : "bg-[#faf8f4] dark:bg-[#2a2435] text-[#75657d] dark:text-[#cbbec9] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50"
                }`}
              >
                <Icon className="w-4 h-4 stroke-[1.5]" />
                <span className="text-sm font-light">
                  {index + 1}. {step.title}
                </span>
                {isComplete && <span className="ml-1">✓</span>}
              </button>
            );
          })}
        </div>
      </div>

      {/* Step Content */}
      <div className="mb-8">
        {/* Step 0: Support Team */}
        {currentStep === 0 && (
          <section>
            <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[28px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 mb-4">
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[17px] font-[450] mb-3 tracking-[-0.005em] transition-colors duration-300">Who do you want with you?</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light mb-4 leading-relaxed">Choose the people who make you feel safe and supported.</p>

              <div className="space-y-4">
                <div>
                  <label className="text-sm text-[#75657d] dark:text-[#cbbec9] mb-2 block font-light">Birth partner(s)</label>
                  <input
                    type="text"
                    placeholder="Partner, family member, friend..."
                    className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] dark:text-[#f5f0f7] placeholder:text-[#b5a8c2] font-light"
                  />
                </div>
                <div>
                  <label className="text-sm text-[#75657d] dark:text-[#cbbec9] mb-2 block font-light">Doula or birth coach (optional)</label>
                  <input
                    type="text"
                    placeholder="Name and contact info"
                    className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] dark:text-[#f5f0f7] placeholder:text-[#b5a8c2] font-light"
                  />
                </div>
              </div>
            </div>

            {/* Why this matters */}
            <button
              onClick={() => toggleSection("support-why")}
              className="w-full flex items-center justify-between p-4 rounded-[20px] bg-gradient-to-br from-[#faf7f3] via-[#f5f0eb] to-[#f0ead8] dark:from-[#2d2438] dark:via-[#2a2435] dark:to-[#2f2638] border border-[#e8dfc8]/40 dark:border-[#3a3043]/40 transition-all duration-300 hover:shadow-[0_4px_20px_rgba(102,51,153,0.08)]"
            >
              <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">Why this matters</span>
              {expandedSections["support-why"] ? (
                <ChevronUp className="w-4 h-4 text-[#d4a574] stroke-[1.5]" />
              ) : (
                <ChevronDown className="w-4 h-4 text-[#d4a574] stroke-[1.5]" />
              )}
            </button>
            {expandedSections["support-why"] && (
              <div className="mt-2 p-5 rounded-[20px] bg-[#faf8f4] dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">
                  Having familiar faces around can help you feel calm and confident. Your support team can speak up for you, help you stay comfortable, and celebrate with you. A doula is a trained birth coach who provides physical and emotional support during labor.
                </p>
              </div>
            )}
          </section>
        )}

        {/* Step 1: Birth Environment */}
        {currentStep === 1 && (
          <section>
            <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[28px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 mb-4">
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[17px] font-[450] mb-3 tracking-[-0.005em] transition-colors duration-300">What helps you feel calm?</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light mb-4 leading-relaxed">Choose the settings that help you relax (select all that apply).</p>

              <div className="space-y-2">
                {["Dim lighting", "Music playing", "Quiet room", "Freedom to move around", "Minimal interruptions"].map((item) => (
                  <button
                    key={item}
                    onClick={() => togglePreference("environment", item)}
                    className={`w-full text-left px-5 py-3.5 rounded-[20px] transition-all font-light ${
                      preferences.environment.includes(item)
                        ? "bg-gradient-to-br from-[#663399] to-[#8855bb] text-white shadow-[0_2px_12px_rgba(102,51,153,0.2)]"
                        : "bg-[#f7f5f9] dark:bg-[#1a1520] text-[#75657d] dark:text-[#cbbec9] hover:bg-[#ede7f3]/50"
                    }`}
                  >
                    {item} {preferences.environment.includes(item) && "✓"}
                  </button>
                ))}
              </div>
            </div>

            {/* Why this matters */}
            <button
              onClick={() => toggleSection("environment-why")}
              className="w-full flex items-center justify-between p-4 rounded-[20px] bg-gradient-to-br from-[#faf7f3] via-[#f5f0eb] to-[#f0ead8] dark:from-[#2d2438] dark:via-[#2a2435] dark:to-[#2f2638] border border-[#e8dfc8]/40 dark:border-[#3a3043]/40 transition-all duration-300 hover:shadow-[0_4px_20px_rgba(102,51,153,0.08)]"
            >
              <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">Why this matters</span>
              {expandedSections["environment-why"] ? (
                <ChevronUp className="w-4 h-4 text-[#d4a574] stroke-[1.5]" />
              ) : (
                <ChevronDown className="w-4 h-4 text-[#d4a574] stroke-[1.5]" />
              )}
            </button>
            {expandedSections["environment-why"] && (
              <div className="mt-2 p-5 rounded-[20px] bg-[#faf8f4] dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">
                  Your surroundings can affect how you feel during labor. Creating a space that feels safe and comfortable can help your body relax and birth progress naturally. Your care team can work with you to make the room feel right for you.
                </p>
              </div>
            )}
          </section>
        )}

        {/* Step 2: Pain Management */}
        {currentStep === 2 && (
          <section>
            <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[28px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 mb-4">
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[17px] font-[450] mb-3 tracking-[-0.005em] transition-colors duration-300">How would you like to manage discomfort?</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light mb-4 leading-relaxed">There are many ways to stay comfortable. Choose what you're considering (you can pick more than one).</p>

              <div className="space-y-2">
                {[
                  { label: "Pain medicine through a small tube in your back", value: "Epidural" },
                  { label: "Breathing and relaxation techniques", value: "Breathing techniques" },
                  { label: "Moving and changing positions", value: "Movement and positioning" },
                  { label: "Using a tub or shower", value: "Water therapy" },
                  { label: "Massage and touch", value: "Massage" },
                  { label: "I'm still deciding", value: "I'm still deciding" },
                ].map((item) => (
                  <button
                    key={item.value}
                    onClick={() => togglePreference("pain", item.value)}
                    className={`w-full text-left px-5 py-3.5 rounded-[20px] transition-all font-light ${
                      preferences.pain.includes(item.value)
                        ? "bg-gradient-to-br from-[#663399] to-[#8855bb] text-white shadow-[0_2px_12px_rgba(102,51,153,0.2)]"
                        : "bg-[#f7f5f9] dark:bg-[#1a1520] text-[#75657d] dark:text-[#cbbec9] hover:bg-[#ede7f3]/50"
                    }`}
                  >
                    {item.label} {preferences.pain.includes(item.value) && "✓"}
                  </button>
                ))}
              </div>
            </div>

            {/* Why this matters */}
            <button
              onClick={() => toggleSection("pain-why")}
              className="w-full flex items-center justify-between p-4 rounded-[20px] bg-gradient-to-br from-[#faf7f3] via-[#f5f0eb] to-[#f0ead8] dark:from-[#2d2438] dark:via-[#2a2435] dark:to-[#2f2638] border border-[#e8dfc8]/40 dark:border-[#3a3043]/40 transition-all duration-300 hover:shadow-[0_4px_20px_rgba(102,51,153,0.08)]"
            >
              <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">Why this matters</span>
              {expandedSections["pain-why"] ? (
                <ChevronUp className="w-4 h-4 text-[#d4a574] stroke-[1.5]" />
              ) : (
                <ChevronDown className="w-4 h-4 text-[#d4a574] stroke-[1.5]" />
              )}
            </button>
            {expandedSections["pain-why"] && (
              <div className="mt-2 p-5 rounded-[20px] bg-[#faf8f4] dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">
                  Every person experiences birth differently. Some prefer medicine that blocks pain, while others use breathing, movement, or water to stay comfortable. There's no right choice—just what feels right for you. You can always change your mind during labor.
                </p>
              </div>
            )}
          </section>
        )}

        {/* Step 3: After Baby Arrives */}
        {currentStep === 3 && (
          <section>
            <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[28px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 mb-4">
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[17px] font-[450] mb-3 tracking-[-0.005em] transition-colors duration-300">First moments with your baby</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light mb-4 leading-relaxed">These choices are about the first hour after birth.</p>

              <div className="space-y-4">
                <div>
                  <label className="text-sm text-[#75657d] dark:text-[#cbbec9] mb-2 block font-light">Holding baby right away (skin-to-skin)</label>
                  <select className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] dark:text-[#f5f0f7] font-light">
                    <option>Yes, right away if possible</option>
                    <option>Yes, after baby is cleaned</option>
                    <option>I'll decide in the moment</option>
                  </select>
                </div>
                <div>
                  <label className="text-sm text-[#75657d] dark:text-[#cbbec9] mb-2 block font-light">How you plan to feed your baby</label>
                  <select className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] dark:text-[#f5f0f7] font-light">
                    <option>Nursing (breastfeeding)</option>
                    <option>Formula feeding</option>
                    <option>Both nursing and formula</option>
                    <option>Still exploring options</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Why this matters */}
            <button
              onClick={() => toggleSection("afterbirth-why")}
              className="w-full flex items-center justify-between p-4 rounded-[20px] bg-gradient-to-br from-[#faf7f3] via-[#f5f0eb] to-[#f0ead8] dark:from-[#2d2438] dark:via-[#2a2435] dark:to-[#2f2638] border border-[#e8dfc8]/40 dark:border-[#3a3043]/40 transition-all duration-300 hover:shadow-[0_4px_20px_rgba(102,51,153,0.08)]"
            >
              <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">Why this matters</span>
              {expandedSections["afterbirth-why"] ? (
                <ChevronUp className="w-4 h-4 text-[#d4a574] stroke-[1.5]" />
              ) : (
                <ChevronDown className="w-4 h-4 text-[#d4a574] stroke-[1.5]" />
              )}
            </button>
            {expandedSections["afterbirth-why"] && (
              <div className="mt-2 p-5 rounded-[20px] bg-[#faf8f4] dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">
                  Skin-to-skin contact (holding baby against your chest) helps regulate baby's temperature and can support bonding and feeding. However baby is fed—whether nursing, formula, or both—what matters most is that baby is fed and you feel supported in your choice.
                </p>
              </div>
            )}
          </section>
        )}

        {/* Step 4: If Plans Change */}
        {currentStep === 4 && (
          <section>
            <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[28px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 mb-4">
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[17px] font-[450] mb-3 tracking-[-0.005em] transition-colors duration-300">If something unexpected happens</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light mb-4 leading-relaxed">Most births go as planned, but it helps to be prepared just in case.</p>

              <div>
                <label className="text-sm text-[#75657d] dark:text-[#cbbec9] mb-2 block font-light">Who should help make decisions with your medical team?</label>
                <input
                  type="text"
                  placeholder="Name of your decision-maker"
                  className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] dark:text-[#f5f0f7] placeholder:text-[#b5a8c2] font-light"
                />
              </div>

              <div className="mt-4">
                <label className="text-sm text-[#75657d] dark:text-[#cbbec9] mb-2 block font-light">Any other wishes or concerns? (optional)</label>
                <textarea
                  rows={4}
                  placeholder="Anything else you'd like your care team to know..."
                  className="w-full px-5 py-4 rounded-[20px] bg-[#f7f5f9] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 resize-none text-[#4a3f52] dark:text-[#f5f0f7] placeholder:text-[#b5a8c2] font-light leading-relaxed"
                ></textarea>
              </div>
            </div>

            {/* Why this matters */}
            <button
              onClick={() => toggleSection("emergency-why")}
              className="w-full flex items-center justify-between p-4 rounded-[20px] bg-gradient-to-br from-[#faf7f3] via-[#f5f0eb] to-[#f0ead8] dark:from-[#2d2438] dark:via-[#2a2435] dark:to-[#2f2638] border border-[#e8dfc8]/40 dark:border-[#3a3043]/40 transition-all duration-300 hover:shadow-[0_4px_20px_rgba(102,51,153,0.08)]"
            >
              <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">Why this matters</span>
              {expandedSections["emergency-why"] ? (
                <ChevronUp className="w-4 h-4 text-[#d4a574] stroke-[1.5]" />
              ) : (
                <ChevronDown className="w-4 h-4 text-[#d4a574] stroke-[1.5]" />
              )}
            </button>
            {expandedSections["emergency-why"] && (
              <div className="mt-2 p-5 rounded-[20px] bg-[#faf8f4] dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">
                  If you're unable to make decisions during birth (which is rare), your care team needs to know who can speak for you. This person should know your values and wishes, and work with your medical team to make the best decisions for you and baby.
                </p>
              </div>
            )}
          </section>
        )}
      </div>

      {/* Navigation Buttons */}
      <div className="flex gap-3 mb-8">
        {currentStep > 0 && (
          <button
            onClick={() => setCurrentStep(currentStep - 1)}
            className="flex-1 py-3.5 px-4 rounded-[24px] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50 text-[#75657d] dark:text-[#cbbec9] hover:bg-[#f7f5f9] dark:hover:bg-[#2a2435] transition-all flex items-center justify-center gap-2 font-light shadow-[0_2px_12px_rgba(0,0,0,0.03)]"
          >
            <ChevronLeft className="w-4 h-4 stroke-[1.5]" />
            Previous
          </button>
        )}
        {currentStep < steps.length - 1 && (
          <button
            onClick={() => setCurrentStep(currentStep + 1)}
            className="flex-1 py-3.5 px-4 rounded-[24px] bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] text-white hover:shadow-[0_4px_20px_rgba(102,51,153,0.3)] transition-all flex items-center justify-center gap-2 font-light shadow-[0_2px_12px_rgba(102,51,153,0.2)]"
          >
            Next Step
            <ChevronRight className="w-4 h-4 stroke-[1.5]" />
          </button>
        )}
      </div>

      {/* Actions - Only show on last step */}
      {currentStep === steps.length - 1 && (
        <>
          <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[24px] p-5 shadow-[0_8px_32px_rgba(102,51,153,0.1)] dark:shadow-[0_8px_32px_rgba(0,0,0,0.3)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-4 transition-all duration-300">
            <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-2">You're done! 🎉</p>
            <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">
              You can download your birth plan as a PDF or share it directly with your care team.
            </p>
          </div>

          <div className="flex gap-3 mb-8">
            <button className="flex-1 py-3.5 px-4 rounded-[24px] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50 text-[#75657d] dark:text-[#cbbec9] hover:bg-[#f7f5f9] dark:hover:bg-[#2a2435] transition-all flex items-center justify-center gap-2 font-light shadow-[0_2px_12px_rgba(0,0,0,0.03)]">
              <Download className="w-4 h-4 stroke-[1.5]" />
              Download PDF
            </button>
            <button className="flex-1 py-3.5 px-4 rounded-[24px] bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] text-white hover:shadow-[0_4px_20px_rgba(102,51,153,0.3)] transition-all flex items-center justify-center gap-2 font-light shadow-[0_2px_12px_rgba(102,51,153,0.2)]">
              <Share2 className="w-4 h-4 stroke-[1.5]" />
              Share with team
            </button>
          </div>
        </>
      )}
    </div>
  );
}
