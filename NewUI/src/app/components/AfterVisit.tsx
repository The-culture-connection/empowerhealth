import { Calendar, User, FileText, Heart, ChevronLeft } from "lucide-react";
import { Link } from "react-router";

export function AfterVisit() {
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

        {/* Document Header - Like a framed document */}
        <div className="mb-8">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-4 shadow-sm">
            <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574]"></div>
            <span className="text-[#75657d] dark:text-[#cbbec9] text-xs tracking-[0.03em] font-light">Visit summary</span>
          </div>
          <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-2 tracking-[-0.01em]">Your prenatal visit</h1>
          <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">February 23, 2026</p>
        </div>

        {/* Visit Details Card - Structured like a document on a table */}
        <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-8 mb-6 shadow-[0_16px_48px_rgba(102,51,153,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
          {/* Provider Info */}
          <div className="flex items-start gap-4 pb-6 mb-6 border-b border-[#e8e0f0] dark:border-[#3a3043]">
            <div className="w-14 h-14 rounded-[16px] bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)]">
              <User className="w-6 h-6 text-[#663399] dark:text-[#9d7ab8] stroke-[1.5]" />
            </div>
            <div>
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[17px] font-[450] mb-1 tracking-[-0.005em]">Dr. Maria Johnson</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light mb-0.5">Valley Health Center</p>
              <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light">Prenatal care visit</p>
            </div>
          </div>

          {/* Key Measurements */}
          <div className="space-y-5 mb-6">
            <div>
              <h4 className="text-[#663399] dark:text-[#cbbec9] text-[11px] uppercase tracking-[0.08em] mb-3 font-medium">Measurements</h4>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">Blood pressure</span>
                  <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">118/76</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">Weight</span>
                  <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">+2 lbs since last visit</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">Fundal height</span>
                  <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">24 cm</span>
                </div>
              </div>
            </div>

            <div className="h-px bg-[#e8e0f0] dark:bg-[#3a3043]"></div>

            {/* Baby's Heartbeat */}
            <div>
              <h4 className="text-[#663399] dark:text-[#cbbec9] text-[11px] uppercase tracking-[0.08em] mb-3 font-medium">Baby</h4>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_6px_rgba(0,0,0,0.06)]">
                  <Heart className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
                </div>
                <div>
                  <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light mb-0.5">Heartbeat</p>
                  <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">148 bpm • Strong and steady</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Notes Section - Like a written note */}
        <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-8 mb-6 shadow-[0_16px_48px_rgba(102,51,153,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
          <h3 className="text-[#663399] dark:text-[#cbbec9] text-[11px] uppercase tracking-[0.08em] mb-4 font-medium">What we discussed</h3>
          
          <div className="space-y-4">
            <p className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-light leading-relaxed">
              Everything looks healthy and on track. Baby is growing well and movement patterns are normal.
            </p>
            
            <div className="pt-4 border-t border-[#e8e0f0] dark:border-[#3a3043]">
              <h4 className="text-[#663399] dark:text-[#cbbec9] text-xs mb-3 font-medium tracking-wide">For next time</h4>
              <ul className="space-y-2.5">
                <li className="flex items-start gap-3">
                  <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                  <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">Continue prenatal vitamins with iron</p>
                </li>
                <li className="flex items-start gap-3">
                  <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                  <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">Schedule glucose screening for next visit</p>
                </li>
                <li className="flex items-start gap-3">
                  <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                  <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">Call if any concerns arise before next appointment</p>
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* Next Appointment */}
        <div className="relative bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] dark:from-[#2a2435] dark:via-[#3a3149] dark:to-[#4a3e5d] rounded-[20px] p-6 shadow-[0_16px_48px_rgba(102,51,153,0.2),_inset_0_1px_0_rgba(255,255,255,0.1)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.5)] overflow-hidden transition-all duration-500">
          <div className="absolute inset-0 opacity-20">
            <div className="absolute bottom-0 right-0 w-40 h-40 rounded-full bg-[#d4a574] blur-[80px]"></div>
          </div>
          
          <div className="relative flex items-center gap-4">
            <div className="w-12 h-12 rounded-[16px] bg-white/10 backdrop-blur-sm flex items-center justify-center border border-white/20">
              <Calendar className="w-5 h-5 text-[#f5f0f7] stroke-[1.5]" />
            </div>
            <div className="flex-1">
              <p className="text-[#e8dff0] text-xs mb-1 font-light tracking-wide">Next visit</p>
              <p className="text-[#f5f0f7] text-[15px] font-[450]">March 23, 2026 • 10:00 AM</p>
            </div>
            <ChevronLeft className="w-5 h-5 text-[#e8dff0] stroke-[1.5] rotate-180" />
          </div>
        </div>

        {/* Quiet reassurance */}
        <div className="mt-8 text-center">
          <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light leading-relaxed">
            Questions about this visit? Call your care team anytime.
          </p>
        </div>
      </div>
    </div>
  );
}
