import { useState } from "react";
import { ChevronLeft, ChevronRight, Check, Heart, Sparkles } from "lucide-react";
import { Link } from "react-router";

type CareNeed = {
  id: string;
  label: string;
};

type AccessResponse = "yes" | "partly" | "no" | "didnt-try" | "didnt-know" | "couldnt-access";

const careNeeds: CareNeed[] = [
  { id: "prenatal-postpartum", label: "Prenatal or postpartum medical care" },
  { id: "labor-delivery", label: "Labor & delivery preparation" },
  { id: "blood-pressure", label: "Blood pressure or medical condition follow-up" },
  { id: "mental-health", label: "Mental health support" },
  { id: "lactation", label: "Lactation/feeding support" },
  { id: "infant-pediatric", label: "Infant/pediatric care" },
  { id: "benefits", label: "Benefits/resources (WIC, Medicaid, crib, car seat)" },
  { id: "transportation", label: "Transportation/logistics" },
  { id: "other", label: "Other" },
];

const accessOptions = [
  { value: "yes", label: "Yes", color: "from-[#5a9d7d] to-[#6aad8d]" },
  { value: "partly", label: "Partly", color: "from-[#d4a574] to-[#e0b589]" },
  { value: "no", label: "No", color: "from-[#c47b7b] to-[#d48b8b]" },
  { value: "didnt-try", label: "Didn't try", color: "from-[#9b8ba5] to-[#ab9bb5]" },
  { value: "didnt-know", label: "Didn't know how", color: "from-[#9b8ba5] to-[#ab9bb5]" },
  { value: "couldnt-access", label: "Couldn't access", color: "from-[#c47b7b] to-[#d48b8b]" },
];

export function CareNavigationSurvey() {
  const [step, setStep] = useState<"intro" | "needs" | "access" | "complete">("intro");
  const [selectedNeeds, setSelectedNeeds] = useState<string[]>([]);
  const [accessResponses, setAccessResponses] = useState<Record<string, AccessResponse>>({});
  const [currentNeedIndex, setCurrentNeedIndex] = useState(0);

  const toggleNeed = (needId: string) => {
    setSelectedNeeds(prev =>
      prev.includes(needId)
        ? prev.filter(id => id !== needId)
        : [...prev, needId]
    );
  };

  const handleAccessResponse = (response: AccessResponse) => {
    const currentNeed = selectedNeeds[currentNeedIndex];
    setAccessResponses(prev => ({
      ...prev,
      [currentNeed]: response,
    }));

    // Move to next need or complete
    if (currentNeedIndex < selectedNeeds.length - 1) {
      setCurrentNeedIndex(prev => prev + 1);
    } else {
      // Save responses (localStorage for now)
      const surveyResponse = {
        date: new Date().toISOString(),
        selectedNeeds,
        accessResponses,
      };
      const existingResponses = JSON.parse(localStorage.getItem("careNavigationResponses") || "[]");
      localStorage.setItem("careNavigationResponses", JSON.stringify([...existingResponses, surveyResponse]));
      
      setStep("complete");
    }
  };

  const currentNeed = selectedNeeds[currentNeedIndex];
  const currentNeedLabel = careNeeds.find(n => n.id === currentNeed)?.label;

  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] relative overflow-hidden transition-colors duration-500">
      {/* Warm ambient light */}
      <div className="fixed inset-0 opacity-40 dark:opacity-30 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[140px]"></div>
        <div className="absolute bottom-1/4 left-1/4 w-[400px] h-[400px] rounded-full bg-[#b899d4] blur-[120px]"></div>
      </div>

      <div className="relative p-6 pb-24 max-w-2xl mx-auto">
        {/* Back Navigation */}
        {step !== "complete" && (
          <Link to="/" className="inline-flex items-center gap-2 mb-8 text-[#75657d] dark:text-[#cbbec9] hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors duration-300">
            <ChevronLeft className="w-4 h-4 stroke-[1.5]" />
            <span className="text-sm font-light tracking-wide">Home</span>
          </Link>
        )}

        {/* Intro Step */}
        {step === "intro" && (
          <div className="animate-in fade-in duration-500">
            <div className="mb-8 mt-4">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#2a2435] dark:to-[#3a3043] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-4 shadow-sm">
                <Sparkles className="w-3.5 h-3.5 text-[#d4a574]" />
                <span className="text-[#75657d] dark:text-[#cbbec9] text-xs tracking-[0.03em] font-light">Care check-in</span>
              </div>
              <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-3 tracking-[-0.01em]">How can we support you?</h1>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-[15px] font-light leading-relaxed">
                Your responses help us understand what's working and where you might need more support. This takes about 2 minutes.
              </p>
            </div>

            <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-8 mb-6 shadow-[0_16px_48px_rgba(102,51,153,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-[16px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)]">
                  <Heart className="w-5 h-5 text-[#d4a574] stroke-[1.5]" />
                </div>
                <div className="flex-1">
                  <h3 className="text-[#663399] dark:text-[#cbbec9] text-sm font-[450] mb-2 tracking-[-0.005em]">Your privacy matters</h3>
                  <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">
                    Your answers are confidential and help improve care for everyone. You can skip any question.
                  </p>
                </div>
              </div>
            </div>

            <button
              onClick={() => setStep("needs")}
              className="w-full py-4 px-6 rounded-[18px] bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] dark:from-[#3a3043] dark:via-[#4a3e5d] dark:to-[#5a4971] text-[#f5f0f7] text-[15px] font-[450] shadow-[0_12px_40px_rgba(102,51,153,0.25),_inset_0_1px_0_rgba(255,255,255,0.1)] hover:shadow-[0_16px_56px_rgba(102,51,153,0.3)] hover:translate-y-[-2px] transition-all duration-300 tracking-[-0.005em]"
            >
              Start check-in
            </button>
          </div>
        )}

        {/* Needs Selection Step */}
        {step === "needs" && (
          <div className="animate-in fade-in duration-500">
            <div className="mb-8 mt-4">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-4 shadow-sm">
                <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574]"></div>
                <span className="text-[#75657d] dark:text-[#cbbec9] text-xs tracking-[0.03em] font-light">Step 1 of 2</span>
              </div>
              <h2 className="text-[28px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-3 tracking-[-0.01em]">In the past few weeks, did you need help with:</h2>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">Select all that apply</p>
            </div>

            <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-8 mb-6 shadow-[0_16px_48px_rgba(102,51,153,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
              <div className="space-y-3">
                {careNeeds.map((need) => {
                  const isSelected = selectedNeeds.includes(need.id);
                  return (
                    <button
                      key={need.id}
                      onClick={() => toggleNeed(need.id)}
                      className={`w-full flex items-center gap-4 p-4 rounded-[16px] transition-all duration-300 ${
                        isSelected
                          ? "bg-gradient-to-br from-[#663399] to-[#7744aa] dark:from-[#3a3043] dark:to-[#4a3e5d] shadow-[0_8px_24px_rgba(102,51,153,0.2)]"
                          : "bg-[#faf8f4] dark:bg-[#1a1520] hover:bg-[#f5f0f7] dark:hover:bg-[#2a2435] shadow-[0_4px_16px_rgba(102,51,153,0.08)]"
                      }`}
                    >
                      <div className={`w-5 h-5 rounded-full flex items-center justify-center transition-all duration-300 ${
                        isSelected
                          ? "bg-[#d4a574]"
                          : "border-2 border-[#cbbec9] dark:border-[#75657d]"
                      }`}>
                        {isSelected && <Check className="w-4 h-4 text-white stroke-[2.5]" />}
                      </div>
                      <span className={`text-[15px] font-light tracking-[-0.005em] text-left transition-colors duration-300 ${
                        isSelected
                          ? "text-[#f5f0f7]"
                          : "text-[#2d2235] dark:text-[#f5f0f7]"
                      }`}>
                        {need.label}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setStep("intro")}
                className="flex-1 py-4 px-6 rounded-[18px] bg-white dark:bg-[#2a2435] text-[#75657d] dark:text-[#cbbec9] text-[15px] font-light shadow-[0_8px_32px_rgba(102,51,153,0.1)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 hover:shadow-[0_12px_48px_rgba(102,51,153,0.14)] hover:translate-y-[-2px] transition-all duration-300"
              >
                Back
              </button>
              <button
                onClick={() => {
                  if (selectedNeeds.length === 0) {
                    setStep("complete");
                  } else {
                    setStep("access");
                  }
                }}
                className="flex-1 py-4 px-6 rounded-[18px] bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] dark:from-[#3a3043] dark:via-[#4a3e5d] dark:to-[#5a4971] text-[#f5f0f7] text-[15px] font-[450] shadow-[0_12px_40px_rgba(102,51,153,0.25),_inset_0_1px_0_rgba(255,255,255,0.1)] hover:shadow-[0_16px_56px_rgba(102,51,153,0.3)] hover:translate-y-[-2px] transition-all duration-300 flex items-center justify-center gap-2"
              >
                {selectedNeeds.length === 0 ? "Skip to finish" : "Continue"}
                <ChevronRight className="w-4 h-4 stroke-[2]" />
              </button>
            </div>
          </div>
        )}

        {/* Access Response Step */}
        {step === "access" && (
          <div className="animate-in fade-in duration-500">
            <div className="mb-8 mt-4">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-4 shadow-sm">
                <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574]"></div>
                <span className="text-[#75657d] dark:text-[#cbbec9] text-xs tracking-[0.03em] font-light">
                  Question {currentNeedIndex + 1} of {selectedNeeds.length}
                </span>
              </div>
              <h2 className="text-[24px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-3 tracking-[-0.01em]">
                {currentNeedLabel}
              </h2>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">Did you get what you needed?</p>
            </div>

            {/* Progress bar */}
            <div className="mb-6">
              <div className="h-1.5 bg-[#e8e0f0] dark:bg-[#3a3043] rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-[#663399] to-[#d4a574] rounded-full transition-all duration-500"
                  style={{ width: `${((currentNeedIndex + 1) / selectedNeeds.length) * 100}%` }}
                ></div>
              </div>
            </div>

            <div className="space-y-3 mb-6">
              {accessOptions.map((option) => (
                <button
                  key={option.value}
                  onClick={() => handleAccessResponse(option.value as AccessResponse)}
                  className="w-full p-5 rounded-[18px] bg-white dark:bg-[#2a2435] shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_32px_rgba(0,0,0,0.3)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 hover:shadow-[0_12px_48px_rgba(102,51,153,0.16)] hover:translate-y-[-2px] transition-all duration-300 text-left group"
                >
                  <span className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-light tracking-[-0.005em] group-hover:text-[#663399] dark:group-hover:text-[#d4a574] transition-colors">
                    {option.label}
                  </span>
                </button>
              ))}
            </div>

            <button
              onClick={() => {
                if (currentNeedIndex > 0) {
                  setCurrentNeedIndex(prev => prev - 1);
                } else {
                  setStep("needs");
                }
              }}
              className="w-full py-3 px-6 rounded-[18px] bg-white dark:bg-[#2a2435] text-[#75657d] dark:text-[#cbbec9] text-sm font-light shadow-[0_8px_32px_rgba(102,51,153,0.1)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 hover:shadow-[0_12px_48px_rgba(102,51,153,0.14)] transition-all duration-300"
            >
              Back
            </button>
          </div>
        )}

        {/* Complete Step */}
        {step === "complete" && (
          <div className="animate-in fade-in duration-500">
            <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
              <div className="w-20 h-20 rounded-full bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center mb-6 shadow-[0_12px_40px_rgba(102,51,153,0.15)]">
                <Heart className="w-10 h-10 text-[#d4a574] stroke-[1.5]" />
              </div>
              
              <h2 className="text-[28px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-3 tracking-[-0.01em]">
                Thank you for sharing
              </h2>
              
              <p className="text-[#75657d] dark:text-[#cbbec9] text-[15px] font-light leading-relaxed mb-8 max-w-md">
                Your responses help us understand how to better support you and others in your community.
              </p>

              <div className="relative bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] dark:from-[#2a2435] dark:via-[#3a3149] dark:to-[#4a3e5d] rounded-[20px] p-6 mb-8 max-w-md shadow-[0_16px_48px_rgba(102,51,153,0.2)]">
                <div className="absolute inset-0 opacity-20">
                  <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-[#d4a574] blur-[60px]"></div>
                </div>
                <p className="relative text-[#f5f0f7] text-sm font-light leading-relaxed">
                  If you need immediate help accessing any of these services, our care team is here for you. You can reach out anytime.
                </p>
              </div>

              <Link
                to="/"
                className="inline-flex items-center justify-center gap-2 py-4 px-8 rounded-[18px] bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] dark:from-[#3a3043] dark:via-[#4a3e5d] dark:to-[#5a4971] text-[#f5f0f7] text-[15px] font-[450] shadow-[0_12px_40px_rgba(102,51,153,0.25),_inset_0_1px_0_rgba(255,255,255,0.1)] hover:shadow-[0_16px_56px_rgba(102,51,153,0.3)] hover:translate-y-[-2px] transition-all duration-300"
              >
                Back to home
              </Link>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
