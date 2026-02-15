import { BookOpen, Heart, Shield, Pill, Brain, Scale, ChevronRight } from "lucide-react";

export function Learning() {
  const modules = [
    {
      icon: BookOpen,
      title: "Trimester Learning",
      description: "Week-by-week guidance for your journey",
      color: "bg-blue-50",
      iconColor: "text-blue-500",
      progress: 60,
    },
    {
      icon: Pill,
      title: "Medication Explanations",
      description: "Understand what you're taking and why",
      color: "bg-green-50",
      iconColor: "text-green-600",
      progress: 30,
    },
    {
      icon: Shield,
      title: "Prenatal Risk Education",
      description: "Make informed decisions with confidence",
      color: "bg-amber-50",
      iconColor: "text-amber-600",
      progress: 45,
    },
    {
      icon: Brain,
      title: "Mental Health Awareness",
      description: "Supporting your emotional wellbeing",
      color: "bg-purple-50",
      iconColor: "text-[#663399]",
      progress: 20,
    },
    {
      icon: Scale,
      title: "Know Your Rights",
      description: "Healthcare advocacy and informed consent",
      color: "bg-rose-50",
      iconColor: "text-rose-600",
      progress: 15,
    },
    {
      icon: Heart,
      title: "Birth Preparation",
      description: "Getting ready for labor and delivery",
      color: "bg-pink-50",
      iconColor: "text-pink-600",
      progress: 0,
    },
  ];

  return (
    <div className="p-5">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl mb-2">Learning Center</h1>
        <p className="text-gray-600">Knowledge that empowers your choices</p>
      </div>

      {/* Continue Learning */}
      <section className="mb-6">
        <h2 className="mb-3">Continue Learning</h2>
        <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] rounded-3xl p-6 text-white shadow-md">
          <div className="flex items-start gap-4 mb-4">
            <div className="w-12 h-12 rounded-2xl bg-white/20 flex items-center justify-center flex-shrink-0">
              <BookOpen className="w-6 h-6 text-white" />
            </div>
            <div className="flex-1">
              <p className="text-white/80 text-xs mb-1">IN PROGRESS</p>
              <h3 className="text-lg mb-1">Second Trimester Guide</h3>
              <p className="text-white/90 text-sm">Week 24: Your baby's development</p>
            </div>
          </div>
          <div className="w-full h-2 bg-white/20 rounded-full overflow-hidden mb-2">
            <div className="h-full bg-white rounded-full" style={{ width: "60%" }}></div>
          </div>
          <p className="text-white/80 text-xs">60% complete • 5 min remaining</p>
        </div>
      </section>

      {/* All Modules */}
      <section>
        <h2 className="mb-3">All Topics</h2>
        <div className="space-y-3">
          {modules.map((module, index) => {
            const Icon = module.icon;
            return (
              <div
                key={index}
                className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors cursor-pointer"
              >
                <div className="flex items-start gap-4">
                  <div className={`w-12 h-12 rounded-2xl ${module.color} flex items-center justify-center flex-shrink-0`}>
                    <Icon className={`w-6 h-6 ${module.iconColor}`} />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-sm mb-1">{module.title}</h3>
                    <p className="text-xs text-gray-500 mb-3">{module.description}</p>
                    {module.progress > 0 && (
                      <>
                        <div className="w-full h-1.5 bg-gray-100 rounded-full overflow-hidden mb-1">
                          <div
                            className="h-full bg-[#663399] rounded-full"
                            style={{ width: `${module.progress}%` }}
                          ></div>
                        </div>
                        <p className="text-xs text-gray-500">{module.progress}% complete</p>
                      </>
                    )}
                    {module.progress === 0 && (
                      <button className="text-xs text-[#663399]">Start learning →</button>
                    )}
                  </div>
                  <ChevronRight className="w-5 h-5 text-gray-400" />
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* Resources */}
      <section className="mt-6">
        <h2 className="mb-3">Helpful Resources</h2>
        <div className="bg-gradient-to-br from-[#fef3f3] to-[#fff0f8] rounded-3xl p-5 shadow-sm border border-pink-100">
          <h3 className="mb-2">Plain Language Promise</h3>
          <p className="text-sm text-gray-600">
            All our content is written at a 6th grade reading level. No confusing medical jargon—just clear, supportive guidance that helps you understand your care.
          </p>
        </div>
      </section>
    </div>
  );
}
