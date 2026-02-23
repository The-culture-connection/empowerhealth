import { Link } from "react-router";
import { Search, Calendar, Heart, BookOpen, FileText, Pen, ChevronRight, Sparkles } from "lucide-react";

export function Home() {
  return (
    <div className="min-h-screen bg-[#faf8f4] relative overflow-hidden">
      {/* Subtle warm texture overlay */}
      <div 
        className="absolute inset-0 opacity-[0.02] pointer-events-none"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23663399' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`
        }}
      />

      <div className="relative p-6 pb-24">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3">
              <div className="w-14 h-14 rounded-full bg-gradient-to-br from-[#8b7aa8] to-[#d4a574] flex items-center justify-center text-white text-lg shadow-[0_6px_20px_rgba(102,51,153,0.25)]">
                S
              </div>
              <div>
                <p className="text-[#9d8fb5] text-sm font-light">Good morning,</p>
                <h1 className="text-xl text-[#2d2733] font-normal">Sarah</h1>
              </div>
            </div>
          </div>

          {/* Search Bar */}
          <Link to="/providers">
            <div className="relative cursor-pointer group">
              <Search className="absolute left-5 top-1/2 transform -translate-y-1/2 text-[#9d8fb5] w-5 h-5 transition-colors group-hover:text-[#663399] stroke-[1.5]" />
              <input
                type="text"
                placeholder="Find trusted providers near you"
                className="w-full pl-14 pr-5 py-4 rounded-[28px] bg-white border border-[#e8dfe8] focus:outline-none focus:ring-2 focus:ring-[#8b7aa8]/30 cursor-pointer text-[#2d2733] placeholder:text-[#b5a8c2] transition-all shadow-[0_4px_20px_rgba(102,51,153,0.08)] hover:shadow-[0_8px_32px_rgba(102,51,153,0.12)] hover:border-[#d4c5e0] font-light"
                readOnly
              />
            </div>
          </Link>
        </div>

        {/* Pregnancy Journey */}
        <section className="mb-8">
          <h2 className="mb-4 text-[#4a3f52] font-normal text-base tracking-wide">Your pregnancy journey</h2>
          <div className="bg-gradient-to-br from-[#ebe4f3] via-[#e6d8ed] to-[#ead9e0] rounded-[32px] p-7 shadow-[0_8px_32px_rgba(102,51,153,0.12)] relative overflow-hidden border border-[#e0d3e8]/50">
            {/* Subtle background glow */}
            <div className="absolute inset-0 opacity-30">
              <div className="absolute top-0 right-0 w-40 h-40 rounded-full bg-[#d4c5e0] blur-3xl"></div>
              <div className="absolute bottom-0 left-0 w-48 h-48 rounded-full bg-[#e6d5b8] blur-3xl"></div>
            </div>
            
            <div className="relative">
              <div className="flex justify-between items-start mb-6">
                <div>
                  <p className="text-[#7d6d85] text-sm mb-2 font-light">Week 24 of 40</p>
                  <h3 className="text-2xl mb-2 text-[#2d2733] font-normal">You're in your second trimester</h3>
                  <p className="text-[#d4a574] text-sm font-medium">You're doing beautifully</p>
                </div>
                <div className="w-16 h-16 rounded-full bg-white/60 backdrop-blur-sm flex items-center justify-center shadow-[0_4px_16px_rgba(102,51,153,0.15)]">
                  <span className="text-2xl">🤰</span>
                </div>
              </div>
              
              {/* Progress bar with gradient */}
              <div className="w-full h-1.5 bg-white/50 rounded-full overflow-hidden backdrop-blur-sm">
                <div className="h-full bg-gradient-to-r from-[#8b7aa8] to-[#d4a574] rounded-full transition-all duration-1000 shadow-[0_2px_8px_rgba(139,122,168,0.4)]" style={{ width: "60%" }}></div>
              </div>
            </div>
          </div>
        </section>

        {/* Support for Today */}
        <section className="mb-8">
          <h2 className="mb-4 text-[#4a3f52] font-normal text-base tracking-wide">Support for today</h2>
          
          {/* Appointment */}
          <div className="bg-white rounded-[32px] p-6 mb-4 shadow-[0_6px_24px_rgba(102,51,153,0.1)] border border-[#e8dfe8] hover:shadow-[0_10px_40px_rgba(102,51,153,0.14)] hover:border-[#d4c5e0] transition-all">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 rounded-[20px] bg-gradient-to-br from-[#e8e0f0] to-[#ede7f3] flex items-center justify-center flex-shrink-0 shadow-sm">
                <Calendar className="w-5 h-5 text-[#8b7aa8] stroke-[1.5]" />
              </div>
              <div className="flex-1">
                <h3 className="mb-1 text-[#2d2733] font-normal">Prenatal appointment</h3>
                <p className="text-sm text-[#6b5c75] mb-2 font-light">Tomorrow at 2:00 PM</p>
                <p className="text-sm text-[#9d8fb5] font-light">Dr. Johnson • Valley Health Center</p>
              </div>
              <ChevronRight className="w-5 h-5 text-[#b5a8c2] stroke-[1.5]" />
            </div>
          </div>

          {/* Emotional Check-in */}
          <div className="bg-gradient-to-br from-[#fdfbfc] via-white to-[#fef9f5] rounded-[32px] p-6 shadow-[0_6px_24px_rgba(102,51,153,0.1)] border border-[#f0e8f3] hover:shadow-[0_10px_40px_rgba(212,165,116,0.14)] hover:border-[#e6d5b8] transition-all">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 rounded-[20px] bg-gradient-to-br from-[#f8edf3] to-[#f9f2e8] flex items-center justify-center flex-shrink-0 shadow-sm">
                <Heart className="w-5 h-5 text-[#c9a9c0] stroke-[1.5]" />
              </div>
              <div className="flex-1">
                <h3 className="mb-1 text-[#2d2733] font-normal">Take a moment for yourself</h3>
                <p className="text-sm text-[#6b5c75] font-light leading-relaxed">
                  How are you feeling today? Your emotional wellbeing matters.
                </p>
              </div>
              <ChevronRight className="w-5 h-5 text-[#d4a574] stroke-[1.5]" />
            </div>
          </div>
        </section>

        {/* Quick Actions */}
        <section>
          <h2 className="mb-4 text-[#4a3f52] font-normal text-base tracking-wide">Your care tools</h2>
          <div className="grid grid-cols-2 gap-4">
            <Link to="/learning">
              <div className="bg-white rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] border border-[#e8dfe8] hover:shadow-[0_8px_32px_rgba(102,51,153,0.12)] hover:border-[#d4c5e0] transition-all">
                <div className="w-11 h-11 rounded-[18px] bg-gradient-to-br from-[#e8e0f0] to-[#ede7f3] flex items-center justify-center mb-3 shadow-sm">
                  <BookOpen className="w-5 h-5 text-[#8b7aa8] stroke-[1.5]" />
                </div>
                <h3 className="mb-1 text-[#2d2733] font-normal text-sm">Learning</h3>
                <p className="text-xs text-[#9d8fb5] font-light">Week by week guides</p>
              </div>
            </Link>

            <Link to="/journal">
              <div className="bg-white rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] border border-[#e8dfe8] hover:shadow-[0_8px_32px_rgba(212,165,116,0.12)] hover:border-[#e6d5b8] transition-all">
                <div className="w-11 h-11 rounded-[18px] bg-gradient-to-br from-[#f9f2e8] to-[#fef9f5] flex items-center justify-center mb-3 shadow-sm">
                  <Pen className="w-5 h-5 text-[#d4a574] stroke-[1.5]" />
                </div>
                <h3 className="mb-1 text-[#2d2733] font-normal text-sm">Journal</h3>
                <p className="text-xs text-[#9d8fb5] font-light">Your private space</p>
              </div>
            </Link>

            <Link to="/birth-plan">
              <div className="bg-white rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] border border-[#e8dfe8] hover:shadow-[0_8px_32px_rgba(102,51,153,0.12)] hover:border-[#d4c5e0] transition-all">
                <div className="w-11 h-11 rounded-[18px] bg-gradient-to-br from-[#e8e0f0] to-[#ede7f3] flex items-center justify-center mb-3 shadow-sm">
                  <FileText className="w-5 h-5 text-[#8b7aa8] stroke-[1.5]" />
                </div>
                <h3 className="mb-1 text-[#2d2733] font-normal text-sm">Birth plan</h3>
                <p className="text-xs text-[#9d8fb5] font-light">Your preferences</p>
              </div>
            </Link>

            <Link to="/community">
              <div className="bg-gradient-to-br from-white via-[#fdfbfc] to-[#fef9f5] rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] border border-[#f0e8f3] hover:shadow-[0_8px_32px_rgba(201,169,192,0.12)] hover:border-[#e8d9e0] transition-all">
                <div className="w-11 h-11 rounded-[18px] bg-gradient-to-br from-[#f8edf3] to-[#f9f2e8] flex items-center justify-center mb-3 shadow-sm">
                  <Sparkles className="w-5 h-5 text-[#c9a9c0] stroke-[1.5]" />
                </div>
                <h3 className="mb-1 text-[#2d2733] font-normal text-sm">Community</h3>
                <p className="text-xs text-[#9d8fb5] font-light">Connect & share</p>
              </div>
            </Link>
          </div>
        </section>
      </div>
    </div>
  );
}
