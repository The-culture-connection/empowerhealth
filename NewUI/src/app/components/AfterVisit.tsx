import { FileText, Calendar, Pill, Activity, AlertCircle, CheckCircle, Flag, Share2, Sparkles } from "lucide-react";
import { useState } from "react";
import { PHIBoundaryNotice, SecureIndicator, EmergencyFooter } from "./PrivacyComponents";

export function AfterVisit() {
  const [flagged, setFlagged] = useState(false);

  return (
    <div className="p-6 pb-24">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl mb-2 text-[#4a3f52] font-normal">After visit summary</h1>
        <p className="text-[#8b7a95] font-light">Your visit explained in simple terms</p>
      </div>

      {/* PHI Boundary Notice */}
      <div className="mb-4">
        <PHIBoundaryNotice />
      </div>

      {/* Visit Info */}
      <div className="bg-white/60 backdrop-blur-sm rounded-[32px] p-6 mb-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
        <div className="flex items-start justify-between mb-5">
          <div>
            <p className="text-sm text-[#a89cb5] mb-1 font-light">February 14, 2026</p>
            <h2 className="text-lg mb-1 text-[#4a3f52] font-normal">24-week prenatal checkup</h2>
            <p className="text-sm text-[#8b7a95] font-light">Dr. Maria Johnson</p>
          </div>
          <button className="text-[#a89cb5] flex items-center gap-2 text-sm font-light hover:text-[#8b7a95] transition-colors">
            <Share2 className="w-4 h-4 stroke-[1.5]" />
            Share
          </button>
        </div>

        <div className="flex items-center gap-3 p-4 bg-gradient-to-br from-[#dce8e4] to-[#e8f0ed] rounded-[24px] mb-4 border border-[#c9e0d9]/30">
          <CheckCircle className="w-5 h-5 text-[#6b9688] flex-shrink-0 stroke-[1.5]" />
          <p className="text-sm text-[#4a5f56] font-light leading-relaxed">Everything looks great! You and baby are doing well.</p>
        </div>

        <SecureIndicator />
      </div>

      {/* What We Checked */}
      <section className="mb-6">
        <h2 className="mb-4 text-[#6b5c75] font-normal text-base tracking-wide">What we checked today</h2>
        <div className="space-y-3">
          <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
            <div className="flex items-start gap-3">
              <div className="w-11 h-11 rounded-[20px] bg-[#e8e0f0]/60 flex items-center justify-center flex-shrink-0">
                <Activity className="w-5 h-5 text-[#9d8fb5] stroke-[1.5]" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-1 text-[#4a3f52] font-normal">Baby's heartbeat</h3>
                <p className="text-sm text-[#6b5c75] mb-2 font-light">145 beats per minute</p>
                <p className="text-xs text-[#a89cb5] font-light leading-relaxed">
                  This is a healthy heart rate for your baby right now. A normal range is between 110-160 beats per minute.
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
            <div className="flex items-start gap-3">
              <div className="w-11 h-11 rounded-[20px] bg-[#f0e0e8]/60 flex items-center justify-center flex-shrink-0">
                <Activity className="w-5 h-5 text-[#c9a9c0] stroke-[1.5]" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-1 text-[#4a3f52] font-normal">Your blood pressure</h3>
                <p className="text-sm text-[#6b5c75] mb-2 font-light">118/76 mmHg</p>
                <p className="text-xs text-[#a89cb5] font-light leading-relaxed">
                  Your blood pressure is in the normal range. We'll keep monitoring it to make sure you stay healthy.
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
            <div className="flex items-start gap-3">
              <div className="w-11 h-11 rounded-[20px] bg-[#f0ead8]/60 flex items-center justify-center flex-shrink-0">
                <Activity className="w-5 h-5 text-[#c9b087] stroke-[1.5]" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-1 text-[#4a3f52] font-normal">Fundal height</h3>
                <p className="text-sm text-[#6b5c75] mb-2 font-light">24 centimeters</p>
                <p className="text-xs text-[#a89cb5] font-light leading-relaxed">
                  This measures how your baby is growing. At 24 weeks, a measurement around 24 cm means baby is right on track.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Medications */}
      <section className="mb-6">
        <h2 className="mb-4 text-[#6b5c75] font-normal text-base tracking-wide">Your medications</h2>
        <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
          <div className="flex items-start gap-3">
            <div className="w-11 h-11 rounded-[20px] bg-[#dce8e4]/60 flex items-center justify-center flex-shrink-0">
              <Pill className="w-5 h-5 text-[#8ba39c] stroke-[1.5]" />
            </div>
            <div className="flex-1">
              <h3 className="text-sm mb-1 text-[#4a3f52] font-normal">Prenatal vitamin</h3>
              <p className="text-sm text-[#6b5c75] mb-2 font-light">One tablet daily with food</p>
              <p className="text-xs text-[#a89cb5] font-light leading-relaxed">
                These vitamins help you and baby stay healthy. They include folic acid, iron, and other important nutrients. Take them with a meal to avoid nausea.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Next Steps */}
      <section className="mb-6">
        <h2 className="mb-4 text-[#6b5c75] font-normal text-base tracking-wide">What comes next</h2>
        <div className="space-y-3">
          <div className="bg-gradient-to-br from-[#faf7fb] to-[#f9f5fb] rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#f0e8f3]/50">
            <div className="flex items-start gap-3">
              <div className="w-11 h-11 rounded-[20px] bg-white/60 backdrop-blur-sm flex items-center justify-center flex-shrink-0 shadow-sm">
                <Calendar className="w-5 h-5 text-[#a89cb5] stroke-[1.5]" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-1 text-[#4a3f52] font-normal">Next appointment</h3>
                <p className="text-sm text-[#6b5c75] mb-2 font-light">March 14, 2026 at 2:00 PM</p>
                <p className="text-xs text-[#a89cb5] font-light leading-relaxed">
                  This will be your 28-week checkup. We'll do another ultrasound to check on baby's growth.
                </p>
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-[#f0ead8] to-[#f5f0e8] rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#e8dfc8]/50">
            <div className="flex items-start gap-3">
              <div className="w-11 h-11 rounded-[20px] bg-white/60 backdrop-blur-sm flex items-center justify-center flex-shrink-0 shadow-sm">
                <Sparkles className="w-5 h-5 text-[#c9b087] stroke-[1.5]" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-1 text-[#4a3f52] font-normal">Things to think about</h3>
                <p className="text-xs text-[#8b7a95] font-light leading-relaxed">
                  Start thinking about your birth plan and who you'd like with you during labor. We can talk about this at your next visit.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Flag Concerns */}
      <section className="mb-6">
        <div className="bg-gradient-to-br from-[#ebe4f3] to-[#f5f0f8] rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#e8e0f0]/50">
          <div className="flex items-start gap-3 mb-4">
            <Flag className="w-5 h-5 text-[#a89cb5] flex-shrink-0 stroke-[1.5]" />
            <div className="flex-1">
              <h3 className="text-sm mb-1 text-[#4a3f52] font-normal">Something not feel right?</h3>
              <p className="text-xs text-[#8b7a95] font-light leading-relaxed">
                If anything in this summary seems unclear or doesn't match what you discussed, let us know.
              </p>
            </div>
          </div>
          <button
            onClick={() => setFlagged(!flagged)}
            className={`w-full py-3.5 px-4 rounded-[20px] transition-all font-light shadow-[0_2px_12px_rgba(0,0,0,0.03)] ${
              flagged
                ? "bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] text-white"
                : "border border-[#e8e0f0]/50 text-[#8b7a95] hover:bg-[#f7f5f9]"
            }`}
          >
            {flagged ? "Concern flagged - we'll follow up" : "Flag a concern"}
          </button>
        </div>
      </section>

      {/* Emergency Footer */}
      <EmergencyFooter />
    </div>
  );
}
