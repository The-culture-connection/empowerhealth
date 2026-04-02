import { ChevronLeft, Heart, ChevronRight, Plus, FileText } from "lucide-react";
import { Link } from "react-router";

export function BirthPlanBuilder() {
  const birthPlans = [
    {
      id: "1",
      title: "Birth Plan",
      date: "Jan 20, 2026",
      status: "incomplete",
      link: "/birth-plan/1",
    },
    {
      id: "2",
      title: "Birth Plan",
      date: "Dec 18, 2025",
      status: "complete",
      link: "/birth-plan",
    },
  ];

  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] relative overflow-hidden transition-colors duration-500">
      {/* Warm ambient light */}
      <div className="fixed inset-0 opacity-40 dark:opacity-30 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[140px]"></div>
        <div className="absolute bottom-1/4 left-1/4 w-[400px] h-[400px] rounded-full bg-[#b899d4] blur-[120px]"></div>
      </div>

      <div className="relative p-6 pb-24 max-w-2xl mx-auto">
        {/* Back Navigation */}
        <Link to="/" className="inline-flex items-center gap-2 mb-8 text-[#75657d] dark:text-[#cbbec9] hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors duration-300">
          <ChevronLeft className="w-4 h-4 stroke-[1.5]" />
          <span className="text-sm font-light tracking-wide">Home</span>
        </Link>

        {/* Header with Add Button */}
        <div className="mb-8 flex items-start justify-between">
          <div>
            <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-2 tracking-[-0.01em] transition-colors duration-300">Birth Plan Builder</h1>
            <p className="text-[#75657d] dark:text-[#cbbec9] text-[15px] font-light leading-relaxed transition-colors duration-300">
              Share your preferences with your care team
            </p>
          </div>
          <Link to="/birth-plan/new">
            <button className="w-12 h-12 rounded-full bg-gradient-to-br from-[#b899d4] to-[#9d7ab8] dark:from-[#4a3e5d] dark:to-[#5a4971] flex items-center justify-center shadow-[0_8px_24px_rgba(184,153,212,0.3)] dark:shadow-[0_8px_24px_rgba(0,0,0,0.4)] hover:shadow-[0_12px_32px_rgba(184,153,212,0.4)] hover:translate-y-[-2px] transition-all duration-300">
              <Plus className="w-5 h-5 text-white stroke-[2]" />
            </button>
          </Link>
        </div>

        {/* Reassurance Card */}
        <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[24px] p-6 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-8 transition-all duration-500">
          {/* Warm gold glow */}
          <div className="absolute inset-0 opacity-[0.05] pointer-events-none rounded-[24px] overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-[#d4a574] blur-[60px]"></div>
          </div>

          <div className="relative flex items-start gap-4">
            <div className="w-12 h-12 rounded-[16px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
              <Heart className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
            </div>
            <div className="flex-1">
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-2 tracking-[-0.005em] transition-colors duration-300">There is no one right way to give birth</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
                Only what's right for you. Your birth plan helps start conversations with your care team about your preferences and wishes.
              </p>
            </div>
          </div>
        </div>

        {/* Birth Plans List */}
        <section>
          <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-4 font-medium transition-colors duration-300">Your birth plans</h2>

          <div className="space-y-4">
            {birthPlans.map((plan) => (
              <Link key={plan.id} to={plan.link}>
                <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_12px_48px_rgba(102,51,153,0.14)] dark:hover:shadow-[0_12px_56px_rgba(0,0,0,0.5)] hover:translate-y-[-2px] cursor-pointer">
                  <div className="flex items-start gap-4">
                    <div className="w-11 h-11 rounded-[16px] bg-gradient-to-br from-[#b899d4] to-[#9d7ab8] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
                      <Heart className="w-5 h-5 text-white dark:text-[#cbbec9] stroke-[1.5]" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h4 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] tracking-[-0.005em] transition-colors duration-300">{plan.title}</h4>
                        {plan.status === "incomplete" && (
                          <span className="px-3 py-1 rounded-[14px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3d3540] dark:to-[#453d48] text-[#d4a574] dark:text-[#e0b589] text-xs font-light">
                            Incomplete
                          </span>
                        )}
                      </div>
                      <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light transition-colors duration-300 flex items-center gap-2">
                        <FileText className="w-3.5 h-3.5 stroke-[1.5]" />
                        {plan.date}
                      </p>
                    </div>
                    <ChevronRight className="w-5 h-5 text-[#cbbec9] dark:text-[#75657d] stroke-[1.5] flex-shrink-0" />
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </section>

        {/* Helpful Info Card */}
        <div className="mt-6 relative bg-gradient-to-br from-[#faf7f3] via-[#f5f0eb] to-[#f0ead8] dark:from-[#2d2438] dark:via-[#2a2435] dark:to-[#2f2638] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1)] dark:shadow-[0_8px_32px_rgba(0,0,0,0.3)] border border-[#e8dfc8]/40 dark:border-[#3a3043]/40 transition-all duration-300">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-[14px] bg-[#faf8f4]/60 dark:bg-[#3d3547]/60 backdrop-blur-sm flex items-center justify-center shadow-sm transition-all duration-300">
              <Heart className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
            </div>
            <div className="flex-1">
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-1 tracking-[-0.005em] transition-colors duration-300">Plans can change, and that's okay</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-xs font-light leading-relaxed transition-colors duration-300">
                This is about starting a conversation with your care team. You can update your preferences anytime.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
