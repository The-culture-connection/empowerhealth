import { BookOpen, Heart, Shield, Pill, Brain, Scale, ChevronRight, Sparkles } from "lucide-react";
import { Link } from "react-router";

export function Learning() {
  const modules = [
    {
      icon: BookOpen,
      title: "Trimester learning",
      description: "Week-by-week guidance for your journey",
      lightColor: "from-[#e8e0f0] to-[#ede7f3]",
      darkColor: "dark:from-[#3d3547] dark:to-[#4a4057]",
      iconColor: "text-[#8b7aa8] dark:text-[#b89fb5]",
      progress: 60,
    },
    {
      icon: Pill,
      title: "Understanding medications",
      description: "What you're taking and why it helps",
      lightColor: "from-[#dce8e4] to-[#e8f0ed]",
      darkColor: "dark:from-[#2d3836] dark:to-[#354340]",
      iconColor: "text-[#7d9d92] dark:text-[#89b5a6]",
      progress: 30,
    },
    {
      icon: Shield,
      title: "Prenatal health awareness",
      description: "Making informed decisions with confidence",
      lightColor: "from-[#f9f2e8] to-[#fef9f5]",
      darkColor: "dark:from-[#3d3540] dark:to-[#453d48]",
      iconColor: "text-[#d4a574] dark:text-[#e0b589]",
      progress: 45,
    },
    {
      icon: Brain,
      title: "Emotional wellbeing",
      description: "Supporting your mental health",
      lightColor: "from-[#f8edf3] to-[#fdf5f9]",
      darkColor: "dark:from-[#3d3040] dark:to-[#433845]",
      iconColor: "text-[#c9a9c0] dark:text-[#d4b5c9]",
      progress: 20,
    },
    {
      icon: Sparkles,
      title: "Know your rights",
      description: "Healthcare advocacy and informed consent",
      lightColor: "from-[#e8e0f0] to-[#f0e8f6]",
      darkColor: "dark:from-[#3d3547] dark:to-[#453d50]",
      iconColor: "text-[#9d8fb5] dark:text-[#b89fb5]",
      progress: 15,
    },
    {
      icon: Heart,
      title: "Birth preparation",
      description: "Getting ready for labor and delivery",
      lightColor: "from-[#f9f2e8] to-[#fef9f5]",
      darkColor: "dark:from-[#3d3540] dark:to-[#453d48]",
      iconColor: "text-[#d4a574] dark:text-[#e0b589]",
      progress: 0,
    },
  ];

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl mb-2 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Learning center</h1>
        <p className="text-[#6b5c75] dark:text-[#c9bfd4] font-light transition-colors">Knowledge that empowers your choices</p>
      </div>

      {/* Continue Learning */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#4a3f52] dark:text-[#c9bfd4] font-normal text-base tracking-wide transition-colors">Continue learning</h2>
        <Link to="/learning/week-24">
          <div className="bg-gradient-to-br from-[#ebe4f3] via-[#e6d8ed] to-[#ead9e0] dark:from-[#2d2438] dark:via-[#352d40] dark:to-[#3a2f3d] rounded-[32px] p-7 shadow-[0_8px_32px_rgba(102,51,153,0.12)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] relative overflow-hidden cursor-pointer hover:shadow-[0_12px_48px_rgba(102,51,153,0.16)] dark:hover:shadow-[0_12px_56px_rgba(157,143,181,0.2)] transition-all duration-300 border border-[#e0d3e8]/50 dark:border-[#4a4057]/30">
            {/* Subtle background glow */}
            <div className="absolute inset-0 opacity-30 dark:opacity-20 transition-opacity duration-300">
              <div className="absolute top-0 right-0 w-40 h-40 rounded-full bg-[#d4c5e0] dark:bg-[#663399] blur-3xl"></div>
              <div className="absolute bottom-0 left-0 w-48 h-48 rounded-full bg-[#e6d5b8] dark:bg-[#d4a574] blur-3xl"></div>
            </div>
            
            <div className="relative">
              <div className="flex items-start gap-4 mb-5">
                <div className="w-12 h-12 rounded-[20px] bg-white/60 dark:bg-[#3d3547]/60 backdrop-blur-sm flex items-center justify-center flex-shrink-0 shadow-[0_4px_16px_rgba(102,51,153,0.15)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] transition-all duration-300">
                  <BookOpen className="w-6 h-6 text-[#663399] dark:text-[#b89fb5] stroke-[1.5] transition-colors" />
                </div>
                <div className="flex-1">
                  <p className="text-[#7d6d85] dark:text-[#b89fb5] text-xs mb-2 font-medium tracking-wide uppercase transition-colors">In progress</p>
                  <h3 className="text-lg mb-1 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Second trimester guide</h3>
                  <p className="text-[#6b5c75] dark:text-[#c9bfd4] text-sm font-light transition-colors">Week 24: Your baby's development</p>
                </div>
              </div>
              <div className="w-full h-1.5 bg-white/50 dark:bg-[#1a1520]/50 rounded-full overflow-hidden mb-2 backdrop-blur-sm transition-colors duration-300">
                <div className="h-full bg-gradient-to-r from-[#8b7aa8] to-[#d4a574] rounded-full transition-all duration-1000 shadow-[0_2px_8px_rgba(139,122,168,0.4)] dark:shadow-[0_2px_12px_rgba(212,165,116,0.5)]" style={{ width: "60%" }}></div>
              </div>
              <p className="text-[#7d6d85] dark:text-[#9d8fb5] text-xs font-light transition-colors">60% complete • 5 min remaining</p>
            </div>
          </div>
        </Link>
      </section>

      {/* All Modules */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#4a3f52] dark:text-[#c9bfd4] font-normal text-base tracking-wide transition-colors">All topics</h2>
        <div className="space-y-3">
          {modules.map((module, index) => {
            const Icon = module.icon;
            return (
              <div
                key={index}
                className="bg-white dark:bg-[#2a2435] rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#e8dfe8] dark:border-[#3d3547] hover:shadow-[0_8px_32px_rgba(102,51,153,0.12)] dark:hover:shadow-[0_8px_32px_rgba(157,143,181,0.15)] hover:border-[#d4c5e0] dark:hover:border-[#4a4057] transition-all duration-300 cursor-pointer"
              >
                <div className="flex items-start gap-4">
                  <div className={`w-12 h-12 rounded-[20px] bg-gradient-to-br ${module.lightColor} ${module.darkColor} flex items-center justify-center flex-shrink-0 shadow-sm transition-all duration-300`}>
                    <Icon className={`w-6 h-6 ${module.iconColor} stroke-[1.5] transition-colors`} />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-sm mb-1 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">{module.title}</h3>
                    <p className="text-xs text-[#6b5c75] dark:text-[#b89fb5] mb-3 font-light transition-colors">{module.description}</p>
                    {module.progress > 0 && (
                      <>
                        <div className="w-full h-1 bg-[#f0e8f3] dark:bg-[#3d3547] rounded-full overflow-hidden mb-1.5 transition-colors duration-300">
                          <div
                            className="h-full bg-gradient-to-r from-[#8b7aa8] to-[#d4a574] rounded-full transition-all duration-500"
                            style={{ width: `${module.progress}%` }}
                          ></div>
                        </div>
                        <p className="text-xs text-[#9d8fb5] dark:text-[#9d8fb5] font-light transition-colors">{module.progress}% complete</p>
                      </>
                    )}
                    {module.progress === 0 && (
                      <button className="text-xs text-[#8b7aa8] dark:text-[#b89fb5] font-medium hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors">
                        Start learning →
                      </button>
                    )}
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#b5a8c2] dark:text-[#9d8fb5] stroke-[1.5] transition-colors" />
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* Resources */}
      <section className="mb-6">
        <h2 className="mb-4 text-[#4a3f52] dark:text-[#c9bfd4] font-normal text-base tracking-wide transition-colors">Our approach</h2>
        <div className="bg-gradient-to-br from-white via-[#fdfbfc] to-[#fef9f5] dark:from-[#2d2438] dark:via-[#2a2435] dark:to-[#2f2638] rounded-[28px] p-6 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#f0e8f3] dark:border-[#3d3547] transition-all duration-300">
          <h3 className="mb-2 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Plain language promise</h3>
          <p className="text-sm text-[#6b5c75] dark:text-[#c9bfd4] font-light leading-relaxed transition-colors">
            All our content is written at a 6th grade reading level. No confusing medical jargon—just clear, supportive guidance that helps you understand your care.
          </p>
        </div>
      </section>
    </div>
  );
}
