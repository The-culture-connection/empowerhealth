import { ChevronLeft, Heart, FileText, X, AlertCircle, MessageSquare, CheckCircle } from "lucide-react";
import { Link, useParams } from "react-router";

export function VisitDetail() {
  const { visitId } = useParams();

  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] relative overflow-hidden transition-colors duration-500">
      {/* Warm ambient light */}
      <div className="fixed inset-0 opacity-40 dark:opacity-30 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[140px]"></div>
        <div className="absolute bottom-1/4 left-1/4 w-[400px] h-[400px] rounded-full bg-[#b899d4] blur-[120px]"></div>
      </div>

      <div className="relative p-6 pb-24 max-w-2xl mx-auto">
        {/* Back Navigation */}
        <Link to="/my-visits" className="inline-flex items-center gap-2 mb-8 text-[#75657d] dark:text-[#cbbec9] hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors duration-300">
          <ChevronLeft className="w-4 h-4 stroke-[1.5]" />
          <span className="text-sm font-light tracking-wide">My Visits</span>
        </Link>

        {/* Visit Header Card - Purple */}
        <div className="relative bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] dark:from-[#2a2435] dark:via-[#3a3149] dark:to-[#4a3e5d] rounded-[24px] p-7 shadow-[0_16px_48px_rgba(102,51,153,0.25),_inset_0_1px_0_rgba(255,255,255,0.1)] dark:shadow-[0_20px_60px_rgba(0,0,0,0.5)] overflow-hidden mb-6 transition-all duration-500">
          {/* Soft inner glow */}
          <div className="absolute inset-0 opacity-20">
            <div className="absolute top-0 right-0 w-48 h-48 rounded-full bg-[#d4a574] blur-[80px]"></div>
          </div>

          <div className="relative flex items-start gap-4">
            <div className="w-12 h-12 rounded-[16px] bg-white/10 backdrop-blur-sm flex items-center justify-center border border-white/20">
              <FileText className="w-5 h-5 text-[#f5f0f7] stroke-[1.5]" />
            </div>
            <div className="flex-1">
              <h1 className="text-[24px] text-[#f5f0f7] dark:text-[#ffffff] font-[450] leading-[1.3] mb-1 tracking-[-0.01em]">Mar 31, 2026</h1>
              <p className="text-[#e8dff0] text-sm font-light">Visit summary</p>
            </div>
          </div>
        </div>

        {/* About This Summary */}
        <section className="mb-6">
          <div className="flex items-center gap-2 mb-4">
            <h2 className="text-[#663399] dark:text-[#cbbec9] text-sm font-[450] tracking-[-0.005em] transition-colors duration-300">About this summary</h2>
          </div>

          <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
            <div className="flex items-start gap-4">
              <div className="w-11 h-11 rounded-[16px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
                <Heart className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
              </div>
              <div className="flex-1">
                <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-2 tracking-[-0.005em] transition-colors duration-300">This summary helps you understand your visit</h3>
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
                  It does not replace medical advice from your provider.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* What Was Discussed */}
        <section className="mb-6">
          <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-4 font-medium transition-colors duration-300">What was discussed</h2>

          <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
            <div className="space-y-4">
              <div>
                <h4 className="text-[#663399] dark:text-[#cbbec9] text-xs mb-2 font-medium tracking-wide">In simpler words</h4>
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-light leading-relaxed transition-colors duration-300">
                  The baby requires continued surveillance due to the high-risk nature of your pregnancy. Regular monitoring and follow-up appointments are important to ensure both you and baby stay healthy.
                </p>
              </div>

              <div className="h-px bg-[#e8e0f0] dark:bg-[#3a3043]"></div>

              <div>
                <h4 className="text-[#663399] dark:text-[#cbbec9] text-xs mb-3 font-medium tracking-wide">Key measurements</h4>
                <div className="space-y-2">
                  <div className="flex items-center justify-between py-2">
                    <span className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">Blood pressure</span>
                    <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">138/88</span>
                  </div>
                  <div className="flex items-center justify-between py-2">
                    <span className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">Baby's heartbeat</span>
                    <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">152 bpm</span>
                  </div>
                  <div className="flex items-center justify-between py-2">
                    <span className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">Fundal height</span>
                    <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">28 cm</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Actions to Take */}
        <section className="mb-6">
          <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-4 font-medium transition-colors duration-300">Actions to take</h2>

          <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
            <div className="space-y-4">
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5] flex-shrink-0 mt-0.5" />
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed transition-colors duration-300">
                  Continue regular monitoring and follow-up appointments
                </p>
              </div>
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5] flex-shrink-0 mt-0.5" />
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed transition-colors duration-300">
                  Contact provider if urgent symptoms occur and seek emergency care if severe symptoms develop
                </p>
              </div>
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5] flex-shrink-0 mt-0.5" />
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed transition-colors duration-300">
                  Attend the next scheduled appointment and contact the provider immediately if urgent symptoms occur
                </p>
              </div>
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5] flex-shrink-0 mt-0.5" />
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed transition-colors duration-300">
                  Keep a symptom diary to share with your provider during follow-ups
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Questions You May Want to Ask */}
        <section className="mb-6">
          <div className="flex items-center gap-2 mb-4">
            <MessageSquare className="w-4 h-4 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
            <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] font-medium transition-colors duration-300">Questions to ask next time</h2>
          </div>

          <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8dfc8]/40 dark:border-[#3a3043]/40 transition-all duration-500">
            <ul className="space-y-3">
              <li className="flex items-start gap-3">
                <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
                  What specific symptoms should I watch for?
                </p>
              </li>
              <li className="flex items-start gap-3">
                <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
                  How often will I need follow-up visits?
                </p>
              </li>
              <li className="flex items-start gap-3">
                <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
                  Are there lifestyle changes I should make?
                </p>
              </li>
            </ul>
          </div>
        </section>

        {/* Disclaimer */}
        <div className="relative bg-gradient-to-br from-[#faf7f3] via-[#f5f0eb] to-[#f0ead8] dark:from-[#2d2438] dark:via-[#2a2435] dark:to-[#2f2638] rounded-[24px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#e8dfc8]/50 dark:border-[#3d3547] transition-all duration-300">
          <div className="flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5] flex-shrink-0 mt-0.5" />
            <div>
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-1 tracking-[-0.005em] transition-colors duration-300">Reminder</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-xs font-light leading-relaxed transition-colors duration-300">
                This summary is meant to help you understand your document. It does not replace medical advice from your healthcare provider. Always contact your provider with questions or concerns.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
