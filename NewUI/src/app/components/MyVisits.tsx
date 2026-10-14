import { ChevronLeft, FileText, ChevronRight, Plus, Heart, Calendar, MessageSquare } from "lucide-react";
import { Link } from "react-router";

export function MyVisits() {
  const visits = [
    {
      id: "1",
      date: "Mar 31, 2026",
      readingLevel: "6th grade",
      preview: "The baby requires continued surveillance due to the high-risk ...",
      hasQuestions: true,
      link: "/my-visits/1",
    },
    {
      id: "2",
      date: "Mar 16, 2026",
      readingLevel: "6th grade",
      preview: "The baby's heartbeat and movements are healthy.",
      hasQuestions: false,
      link: "/my-visits/2",
    },
    {
      id: "feb-23",
      date: "Feb 23, 2026",
      readingLevel: "6th grade",
      preview: "Everything looks healthy and on track. Baby is growing well and movement patterns are normal.",
      hasQuestions: false,
      link: "/after-visit",
    },
    {
      id: "3",
      date: "Feb 10, 2026",
      readingLevel: "6th grade",
      preview: "QuestionsToAsk: What are the potential risks of high blood pres...",
      hasQuestions: true,
      link: "/my-visits/3",
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
            <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-2 tracking-[-0.01em] transition-colors duration-300">My Visits</h1>
            <p className="text-[#75657d] dark:text-[#cbbec9] text-[15px] font-light leading-relaxed transition-colors duration-300">
              Summaries in plain language — newest first
            </p>
          </div>
          <Link to="/my-visits/upload">
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
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-2 tracking-[-0.005em] transition-colors duration-300">You deserve to feel heard at every visit</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
                These summaries help you understand what was discussed. They're written in simple language and organized to support you, not replace medical advice.
              </p>
            </div>
          </div>
        </div>

        {/* Upcoming Visit Card */}
        <section className="mb-6">
          <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-4 font-medium transition-colors duration-300">Upcoming</h2>

          <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_12px_48px_rgba(102,51,153,0.14)] dark:hover:shadow-[0_12px_56px_rgba(0,0,0,0.5)] hover:translate-y-[-2px]">
            <div className="flex items-start gap-4 mb-4">
              <div className="w-12 h-12 rounded-[16px] bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
                <Calendar className="w-5 h-5 text-[#663399] dark:text-[#9d7ab8] stroke-[1.5]" />
              </div>
              <div className="flex-1">
                <h4 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-1 tracking-[-0.005em] transition-colors duration-300">Tomorrow • 2:00 PM</h4>
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light mb-3 transition-colors duration-300">Dr. Maria Johnson</p>
              </div>
            </div>

            {/* Questions to Ask Section */}
            <div className="pt-4 border-t border-[#e8e0f0] dark:border-[#3a3043]">
              <div className="flex items-center gap-2 mb-3">
                <MessageSquare className="w-4 h-4 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
                <h5 className="text-[#663399] dark:text-[#cbbec9] text-xs font-medium tracking-wide uppercase">Questions to ask</h5>
              </div>
              <ul className="space-y-2">
                <li className="flex items-start gap-3">
                  <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                  <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">What are my options for pain management?</p>
                </li>
                <li className="flex items-start gap-3">
                  <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                  <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">Should I be concerned about swelling?</p>
                </li>
              </ul>
            </div>
          </div>
        </section>

        {/* Past Visits */}
        <section>
          <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-4 font-medium transition-colors duration-300">Past visits</h2>

          <div className="space-y-3">
            {visits.map((visit) => (
              <Link key={visit.id} to={visit.link}>
                <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_12px_48px_rgba(102,51,153,0.14)] dark:hover:shadow-[0_12px_56px_rgba(0,0,0,0.5)] hover:translate-y-[-2px] cursor-pointer">
                  <div className="flex items-start gap-4">
                    <div className="w-11 h-11 rounded-[16px] bg-gradient-to-br from-[#b899d4] to-[#9d7ab8] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
                      <FileText className="w-5 h-5 text-white dark:text-[#cbbec9] stroke-[1.5]" />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-1 tracking-[-0.005em] transition-colors duration-300">{visit.date}</h4>
                      <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs mb-3 font-light transition-colors duration-300">
                        Visit summary • {visit.readingLevel}
                      </p>
                      <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
                        {visit.preview}
                      </p>
                    </div>
                    <ChevronRight className="w-5 h-5 text-[#cbbec9] dark:text-[#75657d] stroke-[1.5] flex-shrink-0" />
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </section>

        {/* Past Visit Notes Card */}
        <div className="mt-6 relative bg-gradient-to-br from-[#faf7f3] via-[#f5f0eb] to-[#f0ead8] dark:from-[#2d2438] dark:via-[#2a2435] dark:to-[#2f2638] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1)] dark:shadow-[0_8px_32px_rgba(0,0,0,0.3)] border border-[#e8dfc8]/40 dark:border-[#3a3043]/40 transition-all duration-300">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-[14px] bg-[#faf8f4]/60 dark:bg-[#3d3547]/60 backdrop-blur-sm flex items-center justify-center shadow-sm transition-all duration-300">
              <FileText className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
            </div>
            <div className="flex-1">
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-1 tracking-[-0.005em] transition-colors duration-300">Notes from past visits</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-xs font-light leading-relaxed transition-colors duration-300">
                Your visit history helps you track your journey and prepare for future appointments.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
