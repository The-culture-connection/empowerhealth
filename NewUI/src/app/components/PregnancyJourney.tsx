import { ChevronLeft, Heart, User, Baby, Sparkles } from "lucide-react";
import { Link } from "react-router";

export function PregnancyJourney() {
  // Current week data (this would come from user profile)
  const currentWeek = 24;
  const currentTrimester = 2;
  const totalWeeks = 40;
  const progressPercent = (currentWeek / totalWeeks) * 100;

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

        {/* Header */}
        <div className="mb-8">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/60 dark:bg-[#2a2435] backdrop-blur-sm border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-4 shadow-sm">
            <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574]"></div>
            <span className="text-[#75657d] dark:text-[#cbbec9] text-xs tracking-[0.03em] font-light">Week {currentWeek}</span>
          </div>
          <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-3 tracking-[-0.01em]">Second trimester</h1>
          <p className="text-[#75657d] dark:text-[#cbbec9] text-[15px] font-light leading-relaxed">
            You're doing beautifully. This is a time of steady growth and settling in.
          </p>
        </div>

        {/* Progress Card */}
        <div className="relative bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] dark:from-[#2a2435] dark:via-[#3a3149] dark:to-[#4a3e5d] rounded-[24px] p-8 shadow-[0_20px_60px_rgba(102,51,153,0.25),_inset_0_1px_0_rgba(255,255,255,0.1)] overflow-hidden mb-6 transition-all duration-500">
          {/* Soft inner glow */}
          <div className="absolute inset-0 opacity-20">
            <div className="absolute top-0 left-1/3 w-64 h-64 rounded-full bg-[#d4a574] blur-[80px]"></div>
          </div>

          <div className="relative">
            {/* Progress bar */}
            <div className="mb-4">
              <div className="h-[3px] bg-white/20 rounded-full overflow-hidden backdrop-blur-sm">
                <div
                  className="h-full bg-gradient-to-r from-[#d4a574] via-[#e0b589] to-[#edc799] rounded-full shadow-[0_0_12px_rgba(212,165,116,0.5)] transition-all duration-1000"
                  style={{ width: `${progressPercent}%` }}
                ></div>
              </div>
              <p className="text-[#e8dff0] text-xs mt-3 font-light tracking-wide">{currentWeek} of {totalWeeks} weeks</p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="bg-white/10 backdrop-blur-sm rounded-[18px] p-4 border border-white/20">
                <p className="text-[#e8dff0] text-xs mb-1 font-light">Current trimester</p>
                <p className="text-[#f5f0f7] text-lg font-[450]">Second</p>
              </div>
              <div className="bg-white/10 backdrop-blur-sm rounded-[18px] p-4 border border-white/20">
                <p className="text-[#e8dff0] text-xs mb-1 font-light">Weeks remaining</p>
                <p className="text-[#f5f0f7] text-lg font-[450]">{totalWeeks - currentWeek} weeks</p>
              </div>
            </div>
          </div>
        </div>

        {/* Your Body Changes */}
        <section className="mb-6">
          <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-8 shadow-[0_16px_48px_rgba(102,51,153,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
            <div className="flex items-start gap-3 mb-6">
              <div className="w-14 h-14 rounded-[18px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_10px_rgba(0,0,0,0.08)] transition-all duration-300">
                <User className="w-6 h-6 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
              </div>
              <div>
                <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-2 font-medium">Your Body</h2>
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-[17px] font-[450] mb-1">Changes this week</p>
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-2">What you might be feeling:</h3>
                <ul className="space-y-3">
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                    <div>
                      <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">
                        <span className="font-[450]">Your belly is growing.</span> You might notice your baby bump is more visible now, and you may feel your baby moving more regularly.
                      </p>
                    </div>
                  </li>
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                    <div>
                      <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">
                        <span className="font-[450]">You might have more energy.</span> Many people feel better in the second trimester compared to the first.
                      </p>
                    </div>
                  </li>
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                    <div>
                      <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">
                        <span className="font-[450]">Back or hip discomfort is common.</span> Your body is adjusting to carrying extra weight.
                      </p>
                    </div>
                  </li>
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574] mt-2 flex-shrink-0"></div>
                    <div>
                      <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">
                        <span className="font-[450]">Your skin might feel different.</span> Some people notice stretch marks, dry skin, or changes in skin tone.
                      </p>
                    </div>
                  </li>
                </ul>
              </div>

              <div className="h-px bg-[#e8e0f0] dark:bg-[#3a3043]"></div>

              <div>
                <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-2">What can help:</h3>
                <ul className="space-y-2.5">
                  <li className="flex items-start gap-3">
                    <Heart className="w-4 h-4 text-[#8b7aa8] dark:text-[#b89fb5] flex-shrink-0 mt-0.5 stroke-[1.5]" />
                    <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">Rest when you can and ask for help when you need it</p>
                  </li>
                  <li className="flex items-start gap-3">
                    <Heart className="w-4 h-4 text-[#8b7aa8] dark:text-[#b89fb5] flex-shrink-0 mt-0.5 stroke-[1.5]" />
                    <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">Gentle stretches or prenatal yoga can ease back discomfort</p>
                  </li>
                  <li className="flex items-start gap-3">
                    <Heart className="w-4 h-4 text-[#8b7aa8] dark:text-[#b89fb5] flex-shrink-0 mt-0.5 stroke-[1.5]" />
                    <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">Stay hydrated and moisturize your skin</p>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* Baby's Growth */}
        <section className="mb-6">
          <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-8 shadow-[0_16px_48px_rgba(102,51,153,0.14),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_16px_56px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
            <div className="flex items-start gap-3 mb-6">
              <div className="w-14 h-14 rounded-[18px] bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_10px_rgba(0,0,0,0.08)] transition-all duration-300">
                <Baby className="w-6 h-6 text-[#663399] dark:text-[#9d7ab8] stroke-[1.5]" />
              </div>
              <div>
                <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-2 font-medium">Your Baby</h2>
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-[17px] font-[450] mb-1">Growth this week</p>
              </div>
            </div>

            <div className="space-y-4">
              <div className="bg-gradient-to-br from-[#f5eee0]/30 to-[#ebe0d6]/30 dark:from-[#3a3043]/30 dark:to-[#4a3e5d]/30 rounded-[18px] p-5 border border-[#e8e0f0]/50 dark:border-[#3a3043]/50">
                <div className="flex items-center gap-3 mb-3">
                  <Sparkles className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
                  <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">About the size of a cantaloupe</p>
                </div>
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">
                  Your baby is about 12 inches long and weighs around 1.3 pounds this week.
                </p>
              </div>

              <div>
                <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-3">What's developing:</h3>
                <ul className="space-y-3">
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#8b7aa8] mt-2 flex-shrink-0"></div>
                    <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">
                      <span className="font-[450]">Lungs are developing.</span> Your baby is practicing breathing movements with amniotic fluid.
                    </p>
                  </li>
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#8b7aa8] mt-2 flex-shrink-0"></div>
                    <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">
                      <span className="font-[450]">Hearing is improving.</span> Your baby can hear your voice and may respond to sounds.
                    </p>
                  </li>
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#8b7aa8] mt-2 flex-shrink-0"></div>
                    <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">
                      <span className="font-[450]">Taste buds are forming.</span> Your baby can taste what you eat through the amniotic fluid.
                    </p>
                  </li>
                  <li className="flex items-start gap-3">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#8b7aa8] mt-2 flex-shrink-0"></div>
                    <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">
                      <span className="font-[450]">Brain is growing rapidly.</span> Connections are forming that help with thinking and movement.
                    </p>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* Gentle Reminder */}
        <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[24px] p-6 shadow-[0_4px_20px_rgba(102,51,153,0.08)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
          <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed text-center">
            Every pregnancy is unique. If something doesn't feel right or you have concerns, it's always okay to reach out to your care team.
          </p>
        </div>
      </div>
    </div>
  );
}
