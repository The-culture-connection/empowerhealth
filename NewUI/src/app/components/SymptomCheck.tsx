import { ChevronLeft, Circle, CheckCircle2 } from "lucide-react";
import { Link } from "react-router";
import { useState } from "react";

export function SymptomCheck() {
  const [selectedSymptoms, setSelectedSymptoms] = useState<string[]>([]);

  const symptoms = [
    { id: "nausea", label: "Nausea or vomiting" },
    { id: "headache", label: "Headache" },
    { id: "backache", label: "Back pain" },
    { id: "fatigue", label: "Feeling tired" },
    { id: "swelling", label: "Swelling in hands or feet" },
    { id: "heartburn", label: "Heartburn" },
    { id: "cramping", label: "Cramping" },
    { id: "bleeding", label: "Any bleeding" },
    { id: "dizziness", label: "Dizziness" },
    { id: "none", label: "None today" },
  ];

  const toggleSymptom = (id: string) => {
    if (id === "none") {
      setSelectedSymptoms(["none"]);
    } else {
      setSelectedSymptoms((prev) => {
        const filtered = prev.filter((s) => s !== "none");
        if (filtered.includes(id)) {
          return filtered.filter((s) => s !== id);
        } else {
          return [...filtered, id];
        }
      });
    }
  };

  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] relative overflow-hidden transition-colors duration-500">
      {/* Warm ambient light */}
      <div className="fixed inset-0 opacity-40 dark:opacity-30 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[140px]"></div>
      </div>

      <div className="relative p-6 pb-24 max-w-2xl mx-auto">
        {/* Back Navigation */}
        <Link to="/" className="inline-flex items-center gap-2 mb-8 text-[#75657d] dark:text-[#cbbec9] hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors duration-300">
          <ChevronLeft className="w-4 h-4 stroke-[1.5]" />
          <span className="text-sm font-light tracking-wide">Home</span>
        </Link>

        {/* Header - Journal style */}
        <div className="mb-8">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-4 shadow-sm">
            <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574]"></div>
            <span className="text-[#75657d] dark:text-[#cbbec9] text-xs tracking-[0.03em] font-light">Daily check-in</span>
          </div>
          <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-2 tracking-[-0.01em]">How are you feeling?</h1>
          <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">This helps us understand what you're experiencing.</p>
        </div>

        {/* Symptom Checklist - Like a journal page */}
        <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-8 mb-6 shadow-[0_16px_48px_rgba(102,51,153,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
          {/* Subtle page-like lines */}
          <div className="absolute left-8 top-0 bottom-0 w-px bg-[#e8e0f0] dark:bg-[#3a3043] opacity-30"></div>
          
          <div className="relative">
            <h3 className="text-[#663399] dark:text-[#cbbec9] text-[11px] uppercase tracking-[0.08em] mb-6 font-medium">Select any that apply</h3>
            
            <div className="space-y-3">
              {symptoms.map((symptom) => {
                const isSelected = selectedSymptoms.includes(symptom.id);
                const isNone = symptom.id === "none";
                
                return (
                  <button
                    key={symptom.id}
                    onClick={() => toggleSymptom(symptom.id)}
                    className={`w-full flex items-center gap-4 p-4 rounded-[16px] transition-all duration-300 ${
                      isSelected
                        ? "bg-gradient-to-br from-[#663399] to-[#7744aa] dark:from-[#3a3043] dark:to-[#4a3e5d] shadow-[0_8px_24px_rgba(102,51,153,0.2)]"
                        : "bg-[#faf8f4] dark:bg-[#1a1520] hover:bg-[#f5f0f7] dark:hover:bg-[#2a2435] shadow-[0_4px_16px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_16px_rgba(0,0,0,0.3)]"
                    } ${isNone ? "border border-[#e8e0f0] dark:border-[#3a3043]" : ""}`}
                  >
                    <div className={`w-5 h-5 rounded-full flex items-center justify-center transition-all duration-300 ${
                      isSelected
                        ? "bg-[#d4a574]"
                        : "border-2 border-[#cbbec9] dark:border-[#75657d]"
                    }`}>
                      {isSelected && <CheckCircle2 className="w-5 h-5 text-white stroke-[2.5]" />}
                    </div>
                    <span className={`text-[15px] font-light tracking-[-0.005em] transition-colors duration-300 ${
                      isSelected
                        ? "text-[#f5f0f7]"
                        : "text-[#2d2235] dark:text-[#f5f0f7]"
                    }`}>
                      {symptom.label}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        {/* Additional Notes - Optional writing space */}
        <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-8 mb-6 shadow-[0_16px_48px_rgba(102,51,153,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
          <h3 className="text-[#663399] dark:text-[#cbbec9] text-[11px] uppercase tracking-[0.08em] mb-4 font-medium">Anything else?</h3>
          <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light mb-4 leading-relaxed">
            Share any details that feel important. This is optional.
          </p>
          
          <textarea
            rows={4}
            placeholder="How you're feeling, questions, or concerns..."
            className="w-full px-5 py-4 rounded-[18px] bg-[#faf8f4] dark:bg-[#1a1520] border border-[#e8e0f0]/60 dark:border-[#3a3043] focus:outline-none focus:ring-2 focus:ring-[#d4a574]/30 resize-none text-[#2d2235] dark:text-[#f5f0f7] placeholder:text-[#cbbec9] dark:placeholder:text-[#75657d] text-[15px] font-light leading-relaxed shadow-[inset_0_2px_8px_rgba(0,0,0,0.04)] transition-all duration-300"
          ></textarea>
        </div>

        {/* Action Buttons - Layered like fabric */}
        <div className="space-y-3">
          <button className="w-full py-4 px-6 rounded-[18px] bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] dark:from-[#3a3043] dark:via-[#4a3e5d] dark:to-[#5a4971] text-[#f5f0f7] text-[15px] font-[450] shadow-[0_12px_40px_rgba(102,51,153,0.25),_inset_0_1px_0_rgba(255,255,255,0.1)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] hover:shadow-[0_16px_56px_rgba(102,51,153,0.3)] hover:translate-y-[-2px] transition-all duration-300 tracking-[-0.005em]">
            Save check-in
          </button>
          
          <button className="w-full py-4 px-6 rounded-[18px] bg-white dark:bg-[#2a2435] text-[#75657d] dark:text-[#cbbec9] text-[15px] font-light shadow-[0_8px_32px_rgba(102,51,153,0.1)] dark:shadow-[0_8px_32px_rgba(0,0,0,0.3)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 hover:shadow-[0_12px_48px_rgba(102,51,153,0.14)] hover:translate-y-[-2px] transition-all duration-300 tracking-[-0.005em]">
            Skip for today
          </button>
        </div>

        {/* Reassurance */}
        <div className="mt-8 text-center">
          <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light leading-relaxed">
            Your responses are private and help your care team support you better.
          </p>
        </div>
      </div>
    </div>
  );
}