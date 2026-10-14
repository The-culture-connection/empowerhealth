import { ChevronLeft, FileText, Heart, HelpCircle, AlertCircle, Download } from "lucide-react";
import { Link } from "react-router";

export function VisitSummarySimplified() {
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

        {/* Header */}
        <div className="mb-8">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[#faf8f4] dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-4 shadow-sm">
            <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574]"></div>
            <span className="text-[#75657d] dark:text-[#cbbec9] text-xs tracking-[0.03em] font-light">Simplified summary</span>
          </div>
          <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-2 tracking-[-0.01em]">Your prenatal visit</h1>
          <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">February 23, 2026</p>
        </div>

        {/* In Simpler Words */}
        <section className="mb-6">
          <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-8 shadow-[0_16px_48px_rgba(102,51,153,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
            <div className="flex items-start gap-3 mb-4">
              <div className="w-11 h-11 rounded-[16px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
                <Heart className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
              </div>
              <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] font-medium mt-3">In Simpler Words</h2>
            </div>

            <div className="space-y-4">
              <p className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-light leading-relaxed">
                Everything looks healthy with you and your baby. Your blood pressure is in a good range, and you've gained a healthy amount of weight since your last visit.
              </p>

              <p className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-light leading-relaxed">
                Your baby's heartbeat is strong and steady at 148 beats per minute. The baby is growing well - your belly measurement matches what we'd expect for how far along you are.
              </p>

              <p className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-light leading-relaxed">
                The baby is moving normally, which is a good sign that they're doing well.
              </p>
            </div>
          </div>
        </section>

        {/* Important Information */}
        <section className="mb-6">
          <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-8 shadow-[0_16px_48px_rgba(102,51,153,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
            <div className="flex items-start gap-3 mb-4">
              <div className="w-11 h-11 rounded-[16px] bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
                <FileText className="w-5 h-5 text-[#663399] dark:text-[#9d7ab8] stroke-[1.5]" />
              </div>
              <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] font-medium mt-3">Important Information</h2>
            </div>

            <div className="space-y-4">
              <div>
                <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-2">What to keep doing:</h3>
                <ul className="space-y-2.5">
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                    <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">Continue taking your prenatal vitamins with iron every day</p>
                  </li>
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                    <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">Keep eating healthy and staying active as you have been</p>
                  </li>
                </ul>
              </div>

              <div className="h-px bg-[#e8e0f0] dark:bg-[#3a3043]"></div>

              <div>
                <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-2">What comes next:</h3>
                <ul className="space-y-2.5">
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#8b7aa8] mt-2 flex-shrink-0"></div>
                    <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">You'll have a glucose screening test at your next appointment (this checks for gestational diabetes)</p>
                  </li>
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#8b7aa8] mt-2 flex-shrink-0"></div>
                    <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">Your next visit is scheduled for March 23, 2026 at 10:00 AM</p>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* Questions You May Want to Ask */}
        <section className="mb-6">
          <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-8 shadow-[0_16px_48px_rgba(102,51,153,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
            <div className="flex items-start gap-3 mb-4">
              <div className="w-11 h-11 rounded-[16px] bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
                <HelpCircle className="w-5 h-5 text-[#663399] dark:text-[#9d7ab8] stroke-[1.5]" />
              </div>
              <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] font-medium mt-3">Questions You May Want to Ask</h2>
            </div>

            <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed mb-4">
              These are questions you might want to bring up at your next visit:
            </p>

            <div className="space-y-3">
              <div className="flex items-start gap-3 p-4 rounded-[16px] bg-[#faf8f4] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50">
                <div className="w-1.5 h-1.5 rounded-full bg-[#8b7aa8] mt-2 flex-shrink-0"></div>
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">What should I expect during the glucose screening test?</p>
              </div>

              <div className="flex items-start gap-3 p-4 rounded-[16px] bg-[#faf8f4] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50">
                <div className="w-1.5 h-1.5 rounded-full bg-[#8b7aa8] mt-2 flex-shrink-0"></div>
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">Are there any warning signs I should watch for before my next appointment?</p>
              </div>

              <div className="flex items-start gap-3 p-4 rounded-[16px] bg-[#faf8f4] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50">
                <div className="w-1.5 h-1.5 rounded-full bg-[#8b7aa8] mt-2 flex-shrink-0"></div>
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">Is there anything I should be doing differently as I move into the third trimester?</p>
              </div>

              <div className="flex items-start gap-3 p-4 rounded-[16px] bg-[#faf8f4] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50">
                <div className="w-1.5 h-1.5 rounded-full bg-[#8b7aa8] mt-2 flex-shrink-0"></div>
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">What should I know about preparing for labor and delivery?</p>
              </div>
            </div>
          </div>
        </section>

        {/* Supportive Helper Text */}
        <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[24px] p-6 mb-6 shadow-[0_4px_20px_rgba(102,51,153,0.08)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
          <div className="flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5] flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">
                This summary is meant to help you understand your visit. It does not replace medical advice.
              </p>
            </div>
          </div>
        </div>

        {/* Download Option */}
        <button className="w-full py-3.5 px-6 rounded-[20px] bg-white dark:bg-[#2a2435] text-[#663399] dark:text-[#d4a574] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50 hover:shadow-[0_8px_24px_rgba(102,51,153,0.12)] transition-all duration-300 font-light flex items-center justify-center gap-2">
          <Download className="w-4 h-4 stroke-[2]" />
          Save as PDF
        </button>
      </div>
    </div>
  );
}
