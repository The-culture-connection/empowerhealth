import { ArrowLeft, CheckCircle, Circle, Heart, Bookmark, Share2, ChevronRight, Sparkles, BookOpen, Volume2 } from "lucide-react";
import { Link } from "react-router";
import { useState } from "react";

export function LearningModuleDetail() {
  const [completedSections, setCompletedSections] = useState<number[]>([0, 1]);
  const [bookmarked, setBookmarked] = useState(false);
  const [currentSection, setCurrentSection] = useState(0);

  const sections = [
    {
      id: 0,
      title: "Your baby at 24 weeks",
      duration: "2 min read",
      content: "Your baby is about the size of an ear of corn this week—around 12 inches long and weighing about 1.3 pounds. Their tiny lungs are developing the branches that will help them breathe air after birth. Your baby can now hear sounds from outside the womb, including your voice, your heartbeat, and even music.",
    },
    {
      id: 1,
      title: "What you might be feeling",
      duration: "3 min read",
      content: "You might notice your baby moving more often now, especially when you're resting. Many people describe it as flutters or gentle kicks. You might also experience backaches, leg cramps, or swelling in your feet—all normal signs that your body is working hard to support your growing baby.",
    },
    {
      id: 2,
      title: "Important tests this week",
      duration: "4 min read",
      content: "Between weeks 24-28, your provider may recommend a glucose screening test to check for gestational diabetes. This is a routine test that helps make sure you and baby stay healthy. If the screening shows higher glucose levels, you'll do a follow-up test. Remember: having gestational diabetes doesn't mean you did anything wrong—it's about how your body processes sugar during pregnancy.",
    },
    {
      id: 3,
      title: "Taking care of yourself",
      duration: "2 min read",
      content: "Focus on eating balanced meals with plenty of protein, fruits, and vegetables. Drink lots of water throughout the day. If you're having trouble sleeping, try using extra pillows for support. Gentle exercise like walking or prenatal yoga can help with aches and improve your mood. And remember: it's okay to rest when you need to.",
    },
    {
      id: 4,
      title: "Questions to ask your provider",
      duration: "3 min read",
      content: "Use your next appointment to ask about anything on your mind. Some questions you might consider: What warning signs should I watch for? When should I start thinking about my birth plan? Are there any activities I should avoid? What's the best way to manage discomfort? Your provider is there to support you—no question is too small.",
    },
  ];

  const toggleSection = (id: number) => {
    if (completedSections.includes(id)) {
      setCompletedSections(completedSections.filter(s => s !== id));
    } else {
      setCompletedSections([...completedSections, id]);
    }
  };

  const progress = (completedSections.length / sections.length) * 100;
  const currentSectionData = sections[currentSection];

  return (
    <div className="min-h-screen bg-[#f7f5f9] pb-24">
      {/* Header */}
      <div className="bg-white/80 backdrop-blur-lg border-b border-[#e8e0f0]/50 sticky top-0 z-10">
        <div className="max-w-2xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between mb-4">
            <Link to="/learning" className="flex items-center gap-2 text-[#8b7a95] hover:text-[#6b5c75] transition-colors">
              <ArrowLeft className="w-5 h-5 stroke-[1.5]" />
              <span className="text-sm font-light">Back to learning</span>
            </Link>
            <div className="flex items-center gap-3">
              <button 
                onClick={() => setBookmarked(!bookmarked)}
                className="text-[#a89cb5] hover:text-[#8b7a95] transition-colors"
              >
                <Bookmark className={`w-5 h-5 stroke-[1.5] ${bookmarked ? 'fill-[#a89cb5]' : ''}`} />
              </button>
              <button className="text-[#a89cb5] hover:text-[#8b7a95] transition-colors">
                <Share2 className="w-5 h-5 stroke-[1.5]" />
              </button>
            </div>
          </div>

          {/* Progress */}
          <div className="mb-2">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs text-[#a89cb5] font-light">{completedSections.length} of {sections.length} sections complete</span>
              <span className="text-xs text-[#a89cb5] font-light">{Math.round(progress)}%</span>
            </div>
            <div className="h-1 bg-[#ede7f3]/60 rounded-full overflow-hidden">
              <div 
                className="h-full bg-gradient-to-r from-[#d4c5e0] to-[#a89cb5] rounded-full transition-all duration-500"
                style={{ width: `${progress}%` }}
              ></div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-2xl mx-auto px-6 py-8">
        {/* Module Header */}
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-3">
            <div className="w-10 h-10 rounded-[18px] bg-[#e8e0f0]/60 flex items-center justify-center">
              <BookOpen className="w-5 h-5 text-[#9d8fb5] stroke-[1.5]" />
            </div>
            <span className="text-xs text-[#a89cb5] font-light uppercase tracking-wide">Trimester Learning</span>
          </div>
          <h1 className="text-3xl mb-3 text-[#4a3f52] font-normal leading-tight">Week 24: Second trimester guide</h1>
          <p className="text-[#8b7a95] font-light leading-relaxed">
            You're in the middle of your second trimester—often called the "golden period" of pregnancy. Let's explore what's happening with you and your baby this week.
          </p>
        </div>

        {/* Featured Card with Audio */}
        <div className="bg-gradient-to-br from-[#ebe4f3] via-[#e0d5eb] to-[#e8dfe8] rounded-[32px] p-7 shadow-[0_4px_24px_rgba(0,0,0,0.06)] mb-8 relative overflow-hidden">
          <div className="absolute inset-0 opacity-5">
            <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-white blur-3xl"></div>
            <div className="absolute bottom-0 left-0 w-40 h-40 rounded-full bg-[#d4c5e0] blur-3xl"></div>
          </div>
          
          <div className="relative">
            <div className="flex items-start justify-between mb-4">
              <div>
                <p className="text-[#8b7a95] text-xs mb-2 font-light uppercase tracking-wide">Currently reading</p>
                <h2 className="text-xl mb-2 text-[#4a3f52] font-normal">{currentSectionData.title}</h2>
                <p className="text-sm text-[#8b7a95] font-light">{currentSectionData.duration}</p>
              </div>
              <div className="w-12 h-12 rounded-full bg-white/40 backdrop-blur-sm flex items-center justify-center shadow-sm">
                <span className="text-2xl">🤰</span>
              </div>
            </div>

            {/* Audio Player Option */}
            <button className="flex items-center gap-3 w-full bg-white/40 backdrop-blur-sm rounded-[20px] p-4 mb-4 hover:bg-white/60 transition-all">
              <div className="w-10 h-10 rounded-full bg-[#d4c5e0]/50 flex items-center justify-center">
                <Volume2 className="w-5 h-5 text-[#6b5c75] stroke-[1.5]" />
              </div>
              <div className="text-left flex-1">
                <p className="text-sm text-[#4a3f52] font-normal">Listen instead</p>
                <p className="text-xs text-[#8b7a95] font-light">Audio narration available</p>
              </div>
            </button>

            {/* Content */}
            <div className="bg-white/40 backdrop-blur-sm rounded-[24px] p-5">
              <p className="text-[#4a3f52] font-light leading-relaxed">
                {currentSectionData.content}
              </p>
            </div>

            {/* Navigation */}
            <div className="flex items-center justify-between mt-5">
              <button
                onClick={() => currentSection > 0 && setCurrentSection(currentSection - 1)}
                disabled={currentSection === 0}
                className={`px-5 py-2.5 rounded-[18px] text-sm font-light transition-all ${
                  currentSection === 0
                    ? 'text-[#b5a8c2] bg-[#f7f5f9] cursor-not-allowed'
                    : 'text-[#6b5c75] bg-white/60 hover:bg-white/80'
                }`}
              >
                ← Previous
              </button>
              <button
                onClick={() => {
                  if (!completedSections.includes(currentSection)) {
                    toggleSection(currentSection);
                  }
                  if (currentSection < sections.length - 1) {
                    setCurrentSection(currentSection + 1);
                  }
                }}
                className="px-5 py-2.5 rounded-[18px] bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] text-white text-sm font-light hover:shadow-[0_4px_20px_rgba(168,156,181,0.25)] transition-all"
              >
                {currentSection === sections.length - 1 ? 'Complete' : 'Next →'}
              </button>
            </div>
          </div>
        </div>

        {/* All Sections */}
        <section className="mb-8">
          <h2 className="mb-4 text-[#6b5c75] font-normal text-base tracking-wide">All sections</h2>
          <div className="space-y-3">
            {sections.map((section) => {
              const isCompleted = completedSections.includes(section.id);
              const isCurrent = currentSection === section.id;
              
              return (
                <button
                  key={section.id}
                  onClick={() => setCurrentSection(section.id)}
                  className={`w-full bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border transition-all text-left ${
                    isCurrent 
                      ? 'border-[#d4c5e0]/60 shadow-[0_4px_24px_rgba(168,156,181,0.15)]' 
                      : 'border-[#ede7f3]/50 hover:shadow-[0_4px_24px_rgba(0,0,0,0.06)]'
                  }`}
                >
                  <div className="flex items-start gap-4">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        toggleSection(section.id);
                      }}
                      className="flex-shrink-0 mt-0.5"
                    >
                      {isCompleted ? (
                        <CheckCircle className="w-6 h-6 text-[#8ba39c] fill-[#dce8e4] stroke-[1.5]" />
                      ) : (
                        <Circle className="w-6 h-6 text-[#b5a8c2] stroke-[1.5]" />
                      )}
                    </button>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="text-sm text-[#4a3f52] font-normal">{section.title}</h3>
                        {isCurrent && (
                          <span className="text-xs px-2 py-1 rounded-[10px] bg-[#e8e0f0]/60 text-[#8b7a95] font-light">
                            Reading
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-[#a89cb5] font-light">{section.duration}</p>
                    </div>
                    <ChevronRight className="w-5 h-5 text-[#b5a8c2] stroke-[1.5] flex-shrink-0" />
                  </div>
                </button>
              );
            })}
          </div>
        </section>

        {/* Related Resources */}
        <section className="mb-8">
          <h2 className="mb-4 text-[#6b5c75] font-normal text-base tracking-wide">You might also like</h2>
          <div className="space-y-3">
            <div className="bg-gradient-to-br from-[#faf7fb] to-[#f9f5fb] rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#f0e8f3]/50 hover:shadow-[0_4px_24px_rgba(0,0,0,0.06)] transition-all">
              <div className="flex items-start gap-4">
                <div className="w-11 h-11 rounded-[20px] bg-[#f0e0e8]/60 flex items-center justify-center flex-shrink-0">
                  <Heart className="w-5 h-5 text-[#c9a9c0] stroke-[1.5]" />
                </div>
                <div className="flex-1">
                  <h3 className="text-sm mb-1 text-[#4a3f52] font-normal">Emotional wellbeing</h3>
                  <p className="text-xs text-[#a89cb5] font-light">Supporting your mental health during pregnancy</p>
                </div>
                <ChevronRight className="w-5 h-5 text-[#b5a8c2] stroke-[1.5]" />
              </div>
            </div>

            <div className="bg-gradient-to-br from-[#f0ead8] to-[#f5f0e8] rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#e8dfc8]/50 hover:shadow-[0_4px_24px_rgba(0,0,0,0.06)] transition-all">
              <div className="flex items-start gap-4">
                <div className="w-11 h-11 rounded-[20px] bg-white/60 backdrop-blur-sm flex items-center justify-center flex-shrink-0 shadow-sm">
                  <Sparkles className="w-5 h-5 text-[#c9b087] stroke-[1.5]" />
                </div>
                <div className="flex-1">
                  <h3 className="text-sm mb-1 text-[#4a3f52] font-normal">Know your rights</h3>
                  <p className="text-xs text-[#a89cb5] font-light">Healthcare advocacy and informed consent</p>
                </div>
                <ChevronRight className="w-5 h-5 text-[#b5a8c2] stroke-[1.5]" />
              </div>
            </div>
          </div>
        </section>

        {/* Supportive Note */}
        <div className="bg-gradient-to-br from-[#ebe4f3] to-[#f5f0f8] rounded-[28px] p-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#e8e0f0]/50">
          <div className="flex items-start gap-3">
            <div className="w-11 h-11 rounded-[20px] bg-white/60 backdrop-blur-sm flex items-center justify-center flex-shrink-0 shadow-sm">
              <Heart className="w-5 h-5 text-[#a89cb5] stroke-[1.5]" />
            </div>
            <div>
              <h3 className="mb-2 text-[#4a3f52] font-normal">Remember</h3>
              <p className="text-sm text-[#6b5c75] font-light leading-relaxed">
                Every pregnancy is unique. What you're experiencing might be different from what's described here, and that's completely normal. Always reach out to your provider if you have questions or concerns—they're here to support you.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
