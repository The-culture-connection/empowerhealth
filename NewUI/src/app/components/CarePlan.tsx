import { ChevronLeft, Heart, Calendar, Pill, Activity, BookOpen } from "lucide-react";
import { Link } from "react-router";

export function CarePlan() {
  const careSections = [
    {
      icon: Calendar,
      title: "Upcoming appointments",
      color: "from-[#e8e0d8] to-[#ded6ce]",
      darkColor: "dark:from-[#4a403c] dark:to-[#564a50]",
      items: [
        { label: "Prenatal visit", detail: "March 23 • 10:00 AM", status: "scheduled" },
        { label: "Glucose screening", detail: "March 23 • During visit", status: "pending" },
      ],
    },
    {
      icon: Pill,
      title: "Medications & supplements",
      color: "from-[#dce8e4] to-[#d0dfd9]",
      darkColor: "dark:from-[#3a4240] dark:to-[#465250]",
      items: [
        { label: "Prenatal vitamin with iron", detail: "Once daily • Morning", status: "active" },
        { label: "Vitamin D", detail: "Once daily • With food", status: "active" },
      ],
    },
    {
      icon: Activity,
      title: "Movement & rest",
      color: "from-[#f0e8e0] to-[#ebe0d6]",
      darkColor: "dark:from-[#4a403c] dark:to-[#564a50]",
      items: [
        { label: "Gentle walking", detail: "20-30 minutes most days", status: "recommended" },
        { label: "Prenatal yoga", detail: "Twice weekly", status: "recommended" },
      ],
    },
    {
      icon: BookOpen,
      title: "Learning modules",
      color: "from-[#e8e0d8] to-[#ded6ce]",
      darkColor: "dark:from-[#4a403c] dark:to-[#564a50]",
      items: [
        { label: "Second trimester guide", detail: "60% complete", status: "progress" },
        { label: "Preparing for labor", detail: "Not started", status: "upcoming" },
      ],
    },
  ];

  return (
    <div className="min-h-screen bg-[#f5f0eb] dark:bg-[#2a2228] relative overflow-hidden transition-colors duration-500">
      {/* Warm ambient light */}
      <div className="fixed inset-0 opacity-40 dark:opacity-30 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[140px]"></div>
        <div className="absolute bottom-1/4 left-1/4 w-[400px] h-[400px] rounded-full bg-[#c9b6a8] blur-[120px]"></div>
      </div>

      <div className="relative p-6 pb-24 max-w-2xl mx-auto">
        {/* Back Navigation */}
        <Link to="/" className="inline-flex items-center gap-2 mb-8 text-[#7d7370] dark:text-[#c9b6a8] hover:text-[#5a4552] dark:hover:text-[#d4a574] transition-colors duration-300">
          <ChevronLeft className="w-4 h-4 stroke-[1.5]" />
          <span className="text-sm font-light tracking-wide">Home</span>
        </Link>

        {/* Header */}
        <div className="mb-8">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[#faf7f3] dark:bg-[#3a3036] border border-[#e8e0d8]/40 dark:border-[#4a403c]/40 mb-4 shadow-sm">
            <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574]"></div>
            <span className="text-[#7d7370] dark:text-[#c9b6a8] text-xs tracking-[0.03em] font-light">Personalized for you</span>
          </div>
          <h1 className="text-[32px] text-[#3d3230] dark:text-[#f5f0eb] font-[450] leading-[1.3] mb-2 tracking-[-0.01em]">Your care plan</h1>
          <p className="text-[#7d7370] dark:text-[#c9b6a8] text-sm font-light">Week 24 • Second trimester</p>
        </div>

        {/* Overview Card - Like a plush cushion */}
        <div className="relative bg-gradient-to-br from-[#5a4552] via-[#6a5461] to-[#7a6471] dark:from-[#3a3036] dark:via-[#4a3c42] dark:to-[#5a4852] rounded-[24px] p-8 mb-8 shadow-[0_20px_60px_rgba(61,50,48,0.25),_inset_0_1px_0_rgba(255,255,255,0.1)] dark:shadow-[0_24px_72px_rgba(0,0,0,0.5)] overflow-hidden transition-all duration-500">
          {/* Soft inner glow */}
          <div className="absolute inset-0 opacity-20">
            <div className="absolute top-0 right-0 w-48 h-48 rounded-full bg-[#d4a574] blur-[80px]"></div>
          </div>

          <div className="relative">
            <div className="flex items-start gap-4 mb-6">
              <div className="w-12 h-12 rounded-[16px] bg-white/10 backdrop-blur-sm flex items-center justify-center border border-white/20">
                <Heart className="w-6 h-6 text-[#f5f0eb] stroke-[1.5]" />
              </div>
              <div className="flex-1">
                <h2 className="text-[#f5f0eb] dark:text-[#faf7f3] text-[20px] font-[450] mb-2 tracking-[-0.01em]">You're progressing beautifully</h2>
                <p className="text-[#e8ddd5] dark:text-[#ded6ce] text-sm font-light leading-relaxed">
                  Everything is on track. Here's your personalized path forward.
                </p>
              </div>
            </div>

            {/* Quick stats */}
            <div className="grid grid-cols-3 gap-4">
              <div className="bg-white/5 backdrop-blur-sm rounded-[16px] p-4 border border-white/10">
                <p className="text-[#e8ddd5] text-xs mb-1 font-light tracking-wide">Next visit</p>
                <p className="text-[#f5f0eb] text-sm font-[450]">4 weeks</p>
              </div>
              <div className="bg-white/5 backdrop-blur-sm rounded-[16px] p-4 border border-white/10">
                <p className="text-[#e8ddd5] text-xs mb-1 font-light tracking-wide">Active tasks</p>
                <p className="text-[#f5f0eb] text-sm font-[450]">3 items</p>
              </div>
              <div className="bg-white/5 backdrop-blur-sm rounded-[16px] p-4 border border-white/10">
                <p className="text-[#e8ddd5] text-xs mb-1 font-light tracking-wide">Learning</p>
                <p className="text-[#f5f0eb] text-sm font-[450]">60% done</p>
              </div>
            </div>
          </div>
        </div>

        {/* Care Sections - Layered like folded fabric */}
        <div className="space-y-6">
          {careSections.map((section, index) => {
            const Icon = section.icon;
            
            return (
              <div
                key={index}
                className="relative bg-[#faf7f3] dark:bg-[#3a3036] rounded-[24px] p-7 shadow-[0_16px_48px_rgba(61,50,48,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0d8]/40 dark:border-[#4a403c]/40 transition-all duration-500 hover:shadow-[0_20px_64px_rgba(61,50,48,0.18)] dark:hover:shadow-[0_20px_72px_rgba(0,0,0,0.5)] hover:translate-y-[-2px]"
              >
                {/* Section Header */}
                <div className="flex items-center gap-3 mb-6">
                  <div className={`w-12 h-12 rounded-[16px] bg-gradient-to-br ${section.color} ${section.darkColor} flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300`}>
                    <Icon className="w-5 h-5 text-[#5a4552] dark:text-[#b8a3ad] stroke-[1.5]" />
                  </div>
                  <h3 className="text-[#3d3230] dark:text-[#f5f0eb] text-[17px] font-[450] tracking-[-0.005em] transition-colors duration-300">{section.title}</h3>
                </div>

                {/* Items - Nested like stacked papers */}
                <div className="space-y-3 pl-15">
                  {section.items.map((item, itemIndex) => (
                    <div
                      key={itemIndex}
                      className="relative bg-[#f5f0eb] dark:bg-[#2a2228] rounded-[16px] p-4 shadow-[0_4px_16px_rgba(61,50,48,0.08)] dark:shadow-[0_4px_16px_rgba(0,0,0,0.3)] border border-[#e8e0d8]/40 dark:border-[#4a403c]/40 transition-all duration-300 hover:shadow-[0_8px_24px_rgba(61,50,48,0.12)] dark:hover:shadow-[0_8px_24px_rgba(0,0,0,0.4)] hover:translate-x-1"
                    >
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex-1">
                          <p className="text-[#3d3230] dark:text-[#f5f0eb] text-sm font-[450] mb-1 tracking-[-0.005em] transition-colors duration-300">
                            {item.label}
                          </p>
                          <p className="text-[#7d7370] dark:text-[#c9b6a8] text-xs font-light transition-colors duration-300">
                            {item.detail}
                          </p>
                        </div>
                        
                        {/* Status indicator */}
                        <div className={`px-3 py-1.5 rounded-full text-xs font-light tracking-wide ${
                          item.status === "scheduled" || item.status === "active"
                            ? "bg-[#d4a574]/10 text-[#b8926f] dark:text-[#d4a574]"
                            : item.status === "progress"
                            ? "bg-[#5a4552]/10 text-[#5a4552] dark:text-[#b8a3ad]"
                            : "bg-[#e8e0d8] dark:bg-[#4a403c] text-[#7d7370] dark:text-[#c9b6a8]"
                        }`}>
                          {item.status === "scheduled" && "Scheduled"}
                          {item.status === "active" && "Active"}
                          {item.status === "pending" && "Pending"}
                          {item.status === "recommended" && "Suggested"}
                          {item.status === "progress" && "In progress"}
                          {item.status === "upcoming" && "Upcoming"}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            );
          })}
        </div>

        {/* Support Note */}
        <div className="mt-8 text-center">
          <p className="text-[#a89b95] dark:text-[#a89b95] text-xs font-light leading-relaxed">
            Your plan adjusts with you. Questions? Reach out to your care team anytime.
          </p>
        </div>
      </div>
    </div>
  );
}
