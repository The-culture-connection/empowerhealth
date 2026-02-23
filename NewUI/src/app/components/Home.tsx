import { Link } from "react-router";
import { Calendar, BookOpen, FileText, Heart, ChevronRight, Sparkles } from "lucide-react";

export function Home() {
  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] relative overflow-hidden transition-colors duration-500">
      {/* Warm ambient light effect - like lamplight */}
      <div className="fixed inset-0 opacity-40 dark:opacity-30 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[140px]"></div>
        <div className="absolute bottom-1/4 left-1/4 w-[400px] h-[400px] rounded-full bg-[#b899d4] blur-[120px]"></div>
      </div>

      {/* Subtle texture overlay - like fabric weave */}
      <div 
        className="fixed inset-0 opacity-[0.015] pointer-events-none"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='%23663399' fill-opacity='1'%3E%3Ccircle cx='2' cy='2' r='1'/%3E%3Ccircle cx='50' cy='50' r='1'/%3E%3C/g%3E%3C/svg%3E")`
        }}
      />

      <div className="relative p-6 pb-24 max-w-2xl mx-auto">
        {/* Greeting - Editorial Style */}
        <div className="mb-10 mt-4">
          <p className="text-[#75657d] dark:text-[#cbbec9] text-sm mb-1.5 tracking-[0.02em] font-light transition-colors duration-300">Good afternoon</p>
          <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] tracking-[-0.01em] transition-colors duration-300">Sarah</h1>
        </div>

        {/* Main Journey Card - Like a plush sectional */}
        <section className="mb-10">
          <div className="relative bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] dark:from-[#2a2435] dark:via-[#3a3149] dark:to-[#4a3e5d] rounded-[24px] p-8 shadow-[0_20px_60px_rgba(102,51,153,0.25),_inset_0_1px_0_rgba(255,255,255,0.1)] dark:shadow-[0_24px_72px_rgba(0,0,0,0.5)] overflow-hidden transition-all duration-500">
            {/* Soft inner glow - like cushion depth */}
            <div className="absolute inset-0 opacity-20">
              <div className="absolute top-0 left-1/3 w-64 h-64 rounded-full bg-[#d4a574] blur-[80px]"></div>
              <div className="absolute bottom-0 right-1/4 w-80 h-80 rounded-full bg-[#b899d4] blur-[100px]"></div>
            </div>

            <div className="relative">
              {/* Week indicator - like embroidered detail */}
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/10 backdrop-blur-sm border border-white/20 mb-6">
                <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574]"></div>
                <span className="text-[#f5f0f7] text-xs tracking-[0.03em] font-light">Week 24</span>
              </div>

              <h2 className="text-[28px] text-[#f5f0f7] dark:text-[#ffffff] font-[450] leading-[1.35] mb-3 tracking-[-0.01em]">
                Second trimester
              </h2>
              <p className="text-[#e8dff0] dark:text-[#e8e0f0] text-[15px] font-light leading-relaxed mb-8 max-w-md">
                You're doing beautifully. This is a time of steady growth and settling in.
              </p>

              {/* Progress bar - like a decorative line */}
              <div className="relative">
                <div className="h-[3px] bg-white/20 rounded-full overflow-hidden backdrop-blur-sm">
                  <div 
                    className="h-full bg-gradient-to-r from-[#d4a574] via-[#e0b589] to-[#edc799] rounded-full shadow-[0_0_12px_rgba(212,165,116,0.5)] transition-all duration-1000"
                    style={{ width: "60%" }}
                  ></div>
                </div>
                <p className="text-[#e8dff0] text-xs mt-3 font-light tracking-wide">24 of 40 weeks</p>
              </div>
            </div>
          </div>
        </section>

        {/* Today's Care - Framed like art on a wall */}
        <section className="mb-10">
          <h3 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-4 font-medium transition-colors duration-300">Today</h3>
          
          <div className="space-y-4">
            {/* Care Check-in - Subtle, warm invitation */}
            <Link to="/care-check-in">
              <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[20px] p-6 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_16px_56px_rgba(212,165,116,0.18)] dark:hover:shadow-[0_16px_64px_rgba(0,0,0,0.5)] hover:translate-y-[-2px] cursor-pointer">
                {/* Warm gold glow */}
                <div className="absolute inset-0 opacity-[0.05] pointer-events-none rounded-[20px] overflow-hidden">
                  <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-[#d4a574] blur-[60px]"></div>
                </div>
                
                <div className="relative flex items-start gap-4">
                  <div className="w-12 h-12 rounded-[16px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
                    <Sparkles className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
                  </div>
                  <div className="flex-1">
                    <h4 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-1.5 tracking-[-0.005em] transition-colors duration-300">Care check-in</h4>
                    <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
                      Share what support you need • 2 minutes
                    </p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#cbbec9] dark:text-[#75657d] stroke-[1.5] mt-1" />
                </div>
              </div>
            </Link>

            {/* Appointment Card - Upholstered panel */}
            <div className="relative bg-white dark:bg-[#2a2435] rounded-[20px] p-6 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_16px_56px_rgba(102,51,153,0.16)] dark:hover:shadow-[0_16px_64px_rgba(0,0,0,0.5)] hover:translate-y-[-2px]">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-[16px] bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
                  <Calendar className="w-5 h-5 text-[#663399] dark:text-[#9d7ab8] stroke-[1.5]" />
                </div>
                <div className="flex-1">
                  <h4 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-1.5 tracking-[-0.005em] transition-colors duration-300">Prenatal visit</h4>
                  <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed mb-1 transition-colors duration-300">Tomorrow • 2:00 PM</p>
                  <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light transition-colors duration-300">Dr. Maria Johnson</p>
                </div>
                <ChevronRight className="w-5 h-5 text-[#cbbec9] dark:text-[#75657d] stroke-[1.5] mt-1" />
              </div>
            </div>

            {/* Emotional Check-in - Soft textile feel */}
            <Link to="/journal">
              <div className="relative bg-white dark:bg-[#2a2435] rounded-[20px] p-6 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_16px_56px_rgba(102,51,153,0.16)] dark:hover:shadow-[0_16px_64px_rgba(0,0,0,0.5)] hover:translate-y-[-2px] cursor-pointer">
                {/* Warm inner glow */}
                <div className="absolute inset-0 opacity-[0.03] pointer-events-none rounded-[20px] overflow-hidden">
                  <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-[#d4a574] blur-[60px]"></div>
                </div>
                
                <div className="relative flex items-start gap-4">
                  <div className="w-12 h-12 rounded-[16px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
                    <Heart className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
                  </div>
                  <div className="flex-1">
                    <h4 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-1.5 tracking-[-0.005em] transition-colors duration-300">A moment for yourself</h4>
                    <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
                      How are you feeling today?
                    </p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#cbbec9] dark:text-[#75657d] stroke-[1.5] mt-1" />
                </div>
              </div>
            </Link>
          </div>
        </section>

        {/* Your Space - Like sections in a room */}
        <section>
          <h3 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-4 font-medium transition-colors duration-300">Your space</h3>
          
          <div className="grid grid-cols-2 gap-4">
            <Link to="/learning">
              <div className="relative bg-white dark:bg-[#2a2435] rounded-[18px] p-5 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_12px_48px_rgba(102,51,153,0.14)] dark:hover:shadow-[0_12px_56px_rgba(0,0,0,0.5)] hover:translate-y-[-2px] cursor-pointer">
                <div className="w-11 h-11 rounded-[14px] bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center mb-4 shadow-[inset_0_2px_6px_rgba(0,0,0,0.06)] transition-all duration-300">
                  <BookOpen className="w-5 h-5 text-[#663399] dark:text-[#9d7ab8] stroke-[1.5]" />
                </div>
                <h4 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-1 tracking-[-0.005em] transition-colors duration-300">Learning</h4>
                <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light transition-colors duration-300">Guidance at your pace</p>
              </div>
            </Link>

            <Link to="/care-plan">
              <div className="relative bg-white dark:bg-[#2a2435] rounded-[18px] p-5 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_12px_48px_rgba(102,51,153,0.14)] dark:hover:shadow-[0_12px_56px_rgba(0,0,0,0.5)] hover:translate-y-[-2px] cursor-pointer">
                <div className="w-11 h-11 rounded-[14px] bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center mb-4 shadow-[inset_0_2px_6px_rgba(0,0,0,0.06)] transition-all duration-300">
                  <FileText className="w-5 h-5 text-[#663399] dark:text-[#9d7ab8] stroke-[1.5]" />
                </div>
                <h4 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-1 tracking-[-0.005em] transition-colors duration-300">Care plan</h4>
                <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light transition-colors duration-300">Your personalized path</p>
              </div>
            </Link>

            <Link to="/journal">
              <div className="relative bg-white dark:bg-[#2a2435] rounded-[18px] p-5 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_12px_48px_rgba(212,165,116,0.12)] dark:hover:shadow-[0_12px_56px_rgba(0,0,0,0.5)] hover:translate-y-[-2px] cursor-pointer">
                {/* Subtle gold warmth */}
                <div className="absolute inset-0 opacity-[0.02] pointer-events-none rounded-[18px] overflow-hidden">
                  <div className="absolute bottom-0 right-0 w-24 h-24 rounded-full bg-[#d4a574] blur-[50px]"></div>
                </div>
                
                <div className="relative">
                  <div className="w-11 h-11 rounded-[14px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center mb-4 shadow-[inset_0_2px_6px_rgba(0,0,0,0.06)] transition-all duration-300">
                    <Heart className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
                  </div>
                  <h4 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-1 tracking-[-0.005em] transition-colors duration-300">Journal</h4>
                  <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light transition-colors duration-300">Your private reflections</p>
                </div>
              </div>
            </Link>

            <Link to="/symptom-check">
              <div className="relative bg-white dark:bg-[#2a2435] rounded-[18px] p-5 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_12px_48px_rgba(102,51,153,0.14)] dark:hover:shadow-[0_12px_56px_rgba(0,0,0,0.5)] hover:translate-y-[-2px] cursor-pointer">
                <div className="w-11 h-11 rounded-[14px] bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center mb-4 shadow-[inset_0_2px_6px_rgba(0,0,0,0.06)] transition-all duration-300">
                  <div className="w-2 h-2 rounded-full bg-[#663399] dark:bg-[#9d7ab8]"></div>
                </div>
                <h4 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-1 tracking-[-0.005em] transition-colors duration-300">Check-in</h4>
                <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light transition-colors duration-300">How you're feeling</p>
              </div>
            </Link>
          </div>
        </section>
      </div>
    </div>
  );
}