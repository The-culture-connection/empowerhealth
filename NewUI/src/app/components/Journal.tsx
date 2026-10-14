import { Heart, Cloud, Sparkles, Calendar, Pen, Smile, Edit3 } from "lucide-react";
import { useState } from "react";
import { SecureIndicator, EmergencyFooter } from "./PrivacyComponents";

export function Journal() {
  const [entryMethod, setEntryMethod] = useState<"quick" | "write" | null>(null);
  const [entry, setEntry] = useState("");
  const [selectedMood, setSelectedMood] = useState<string | null>(null);
  const [quickNote, setQuickNote] = useState("");

  const prompts = [
    "How are you feeling today?",
    "What brought you peace this week?",
    "What concerns are on your mind?",
    "What are you grateful for right now?",
    "What do you want to remember about this moment?",
  ];

  const formatDate = (date: Date) => {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const month = months[date.getMonth()];
    const day = date.getDate();
    const year = date.getFullYear();

    let hours = date.getHours();
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    hours = hours ? hours : 12; // the hour '0' should be '12'

    return `${month} ${day}, ${year} at ${hours}:${minutes} ${ampm}`;
  };

  const recentEntries = [
    {
      date: formatDate(new Date(2026, 1, 14, 14, 30)),
      preview: "Today I felt the baby kick for the first time during the ultrasound...",
      mood: "joyful",
    },
    {
      date: formatDate(new Date(2026, 1, 10, 9, 15)),
      preview: "Feeling a bit anxious about the glucose test coming up...",
      mood: "thoughtful",
    },
    {
      date: formatDate(new Date(2026, 1, 7, 19, 45)),
      preview: "Had a beautiful conversation with my partner about names...",
      mood: "peaceful",
    },
  ];

  return (
    <div className="p-6 pb-24">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl mb-2 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Your journal</h1>
        <p className="text-[#6b5c75] dark:text-[#c9bfd4] font-light transition-colors">A safe space for your thoughts and feelings</p>
      </div>

      {/* Privacy Notice */}
      <div className="bg-gradient-to-br from-[#ebe4f3] to-[#f5f0f8] dark:from-[#2d2438] dark:to-[#2f2638] rounded-[28px] p-5 border border-[#e8e0f0]/50 dark:border-[#3d3547] mb-8 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] transition-all duration-300">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-[18px] bg-white/60 dark:bg-[#3d3547]/60 backdrop-blur-sm flex items-center justify-center flex-shrink-0 shadow-sm transition-all duration-300">
            <Heart className="w-5 h-5 text-[#a89cb5] dark:text-[#b89fb5] stroke-[1.5] transition-colors" />
          </div>
          <div>
            <p className="text-sm text-[#6b5c75] dark:text-[#c9bfd4] mb-2 font-light leading-relaxed transition-colors">
              Your journal is private. Only you can see what you write here.
            </p>
            <SecureIndicator />
          </div>
        </div>
      </div>

      {/* Welcoming Intro */}
      <section className="mb-6">
        <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[24px] p-6 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
          {/* Warm gold glow */}
          <div className="absolute inset-0 opacity-[0.05] pointer-events-none rounded-[24px] overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-[#d4a574] blur-[60px]"></div>
          </div>

          <div className="relative">
            <h2 className="text-[#2d2235] dark:text-[#f5f0f7] text-[19px] font-[450] mb-2 tracking-[-0.005em] transition-colors duration-300">How are you feeling today?</h2>
            <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
              Take a moment to check in with yourself — whether it's a quick note about your mood or a longer reflection.
            </p>
          </div>
        </div>
      </section>

      {/* Entry Method Selection */}
      {!entryMethod && (
        <section className="mb-8">
          <h3 className="text-[#4a3f52] dark:text-[#c9bfd4] text-sm mb-3 font-light tracking-wide transition-colors">Choose how you'd like to journal:</h3>
          <div className="grid grid-cols-2 gap-3">
            <button
              onClick={() => setEntryMethod("quick")}
              className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[24px] p-5 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-300 hover:shadow-[0_12px_40px_rgba(102,51,153,0.15)] hover:scale-[1.02] active:scale-[0.98]"
            >
              <div className="flex flex-col items-center gap-3 text-center">
                <div className="w-12 h-12 rounded-[16px] bg-gradient-to-br from-[#d4a574] to-[#e0b589] flex items-center justify-center shadow-[0_4px_16px_rgba(212,165,116,0.25)]">
                  <Smile className="w-6 h-6 text-white stroke-[1.5]" />
                </div>
                <div>
                  <h4 className="text-[#2d2235] dark:text-[#f5f0f7] font-[450] mb-1 text-[15px]">Quick Check-in</h4>
                  <p className="text-[#75657d] dark:text-[#cbbec9] text-xs font-light leading-relaxed">Track your mood with an optional note</p>
                </div>
              </div>
            </button>

            <button
              onClick={() => setEntryMethod("write")}
              className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[24px] p-5 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-300 hover:shadow-[0_12px_40px_rgba(102,51,153,0.15)] hover:scale-[1.02] active:scale-[0.98]"
            >
              <div className="flex flex-col items-center gap-3 text-center">
                <div className="w-12 h-12 rounded-[16px] bg-gradient-to-br from-[#663399] to-[#8855bb] flex items-center justify-center shadow-[0_4px_16px_rgba(102,51,153,0.25)]">
                  <Edit3 className="w-6 h-6 text-white stroke-[1.5]" />
                </div>
                <div>
                  <h4 className="text-[#2d2235] dark:text-[#f5f0f7] font-[450] mb-1 text-[15px]">Write</h4>
                  <p className="text-[#75657d] dark:text-[#cbbec9] text-xs font-light leading-relaxed">Express your thoughts and feelings</p>
                </div>
              </div>
            </button>
          </div>
        </section>
      )}

      {/* Quick Check-in Method */}
      {entryMethod === "quick" && (
        <section className="mb-8">
          <div className="bg-gradient-to-br from-[#faf7fb] to-[#f9f5fb] dark:from-[#2a2435] dark:to-[#2d2438] rounded-[32px] p-6 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#f0e8f3]/50 dark:border-[#3d3547] transition-all duration-300">
            <div className="flex items-center gap-2 mb-5">
              <Smile className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5] transition-colors" />
              <h2 className="text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Quick Check-in</h2>
            </div>

            <p className="text-sm text-[#75657d] dark:text-[#cbbec9] mb-4 font-light leading-relaxed">How are you feeling right now?</p>

            <div className="grid grid-cols-5 gap-2 mb-5">
              {[
                { emoji: "😊", label: "Joyful" },
                { emoji: "😌", label: "Calm" },
                { emoji: "😐", label: "Okay" },
                { emoji: "😟", label: "Worried" },
                { emoji: "😢", label: "Tearful" },
              ].map((mood) => (
                <button
                  key={mood.label}
                  onClick={() => setSelectedMood(mood.label)}
                  className={`flex flex-col items-center gap-2 p-3 rounded-[20px] transition-all duration-300 ${
                    selectedMood === mood.label
                      ? "bg-gradient-to-br from-[#d4a574] to-[#e0b589] shadow-[0_4px_16px_rgba(212,165,116,0.3)]"
                      : "bg-white/60 dark:bg-[#1a1520] hover:bg-[#f7f5f9] dark:hover:bg-[#2d2438]"
                  }`}
                >
                  <span className="text-3xl">{mood.emoji}</span>
                  <span className={`text-xs font-light transition-colors ${
                    selectedMood === mood.label
                      ? "text-white"
                      : "text-[#9d8fb5] dark:text-[#9d8fb5]"
                  }`}>{mood.label}</span>
                </button>
              ))}
            </div>

            <div className="mb-4">
              <label className="text-sm text-[#75657d] dark:text-[#cbbec9] mb-2 block font-light">Add a note (optional)</label>
              <textarea
                value={quickNote}
                onChange={(e) => setQuickNote(e.target.value)}
                rows={3}
                placeholder="Anything you'd like to remember about this moment..."
                className="w-full px-5 py-4 rounded-[20px] bg-white/80 dark:bg-[#1a1520] backdrop-blur-sm border border-[#e8e0f0]/50 dark:border-[#3d3547] focus:outline-none focus:ring-2 focus:ring-[#d4a574]/30 resize-none text-[#2d2733] dark:text-[#f5f0f7] placeholder:text-[#b5a8c2] dark:placeholder:text-[#9d8fb5] font-light shadow-[0_2px_12px_rgba(102,51,153,0.06)] dark:shadow-[0_2px_12px_rgba(0,0,0,0.2)] transition-all duration-300"
              ></textarea>
            </div>

            <div className="flex items-center gap-3">
              <button className="flex-1 py-3.5 px-4 rounded-[24px] bg-gradient-to-br from-[#d4a574] to-[#e0b589] text-white hover:shadow-[0_6px_24px_rgba(212,165,116,0.4)] transition-all font-light shadow-[0_2px_12px_rgba(212,165,116,0.2)]">
                Save check-in
              </button>
              <button
                onClick={() => {
                  setEntryMethod(null);
                  setSelectedMood(null);
                  setQuickNote("");
                }}
                className="px-5 py-3.5 rounded-[24px] border border-[#e8e0f0]/50 dark:border-[#3d3547] text-[#6b5c75] dark:text-[#b89fb5] hover:bg-[#f7f5f9] dark:hover:bg-[#2a2435] transition-all duration-300 font-light"
              >
                Cancel
              </button>
            </div>
          </div>
        </section>
      )}

      {/* Write Method */}
      {entryMethod === "write" && (
        <section className="mb-8">
          <div className="bg-gradient-to-br from-[#faf7fb] to-[#f9f5fb] dark:from-[#2a2435] dark:to-[#2d2438] rounded-[32px] p-6 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#f0e8f3]/50 dark:border-[#3d3547] transition-all duration-300">
            <div className="flex items-center gap-2 mb-5">
              <Pen className="w-5 h-5 text-[#663399] dark:text-[#9d8fb5] stroke-[1.5] transition-colors" />
              <h2 className="text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Write</h2>
            </div>

            {/* Writing Prompts */}
            <div className="mb-4">
              <p className="text-sm text-[#75657d] dark:text-[#cbbec9] mb-3 font-light">Not sure where to start? Try a prompt:</p>
              <div className="flex flex-wrap gap-2">
                {prompts.slice(0, 3).map((prompt, index) => (
                  <button
                    key={index}
                    onClick={() => setEntry(prompt + "\n\n")}
                    className="text-xs px-4 py-2.5 rounded-[18px] bg-white/80 dark:bg-[#3d3547] backdrop-blur-sm text-[#6b5c75] dark:text-[#c9bfd4] hover:bg-[#f0e8f3]/60 dark:hover:bg-[#4a4057] transition-all border border-[#e8e0f0]/50 dark:border-[#4a4057] shadow-[0_2px_12px_rgba(102,51,153,0.06)] dark:shadow-[0_2px_12px_rgba(0,0,0,0.2)] font-light"
                  >
                    {prompt}
                  </button>
                ))}
              </div>
            </div>

            <textarea
              value={entry}
              onChange={(e) => setEntry(e.target.value)}
              rows={8}
              placeholder="What's on your mind today?"
              className="w-full px-5 py-4 rounded-[24px] bg-white/80 dark:bg-[#1a1520] backdrop-blur-sm border border-[#e8e0f0]/50 dark:border-[#3d3547] focus:outline-none focus:ring-2 focus:ring-[#663399]/30 dark:focus:ring-[#9d8fb5]/30 resize-none text-[#2d2733] dark:text-[#f5f0f7] placeholder:text-[#b5a8c2] dark:placeholder:text-[#9d8fb5] font-light shadow-[0_2px_12px_rgba(102,51,153,0.06)] dark:shadow-[0_2px_12px_rgba(0,0,0,0.2)] transition-all duration-300 leading-relaxed"
            ></textarea>

            <div className="flex items-center gap-3 mt-4">
              <button className="flex-1 py-3.5 px-4 rounded-[24px] bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] text-white hover:shadow-[0_6px_24px_rgba(102,51,153,0.3)] transition-all font-light shadow-[0_2px_12px_rgba(102,51,153,0.2)]">
                Save entry
              </button>
              <button
                onClick={() => {
                  setEntryMethod(null);
                  setEntry("");
                }}
                className="px-5 py-3.5 rounded-[24px] border border-[#e8e0f0]/50 dark:border-[#3d3547] text-[#6b5c75] dark:text-[#b89fb5] hover:bg-[#f7f5f9] dark:hover:bg-[#2a2435] transition-all duration-300 font-light"
              >
                Cancel
              </button>
            </div>
          </div>
        </section>
      )}

      {/* Past Entries */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#4a3f52] dark:text-[#c9bfd4] font-normal text-base tracking-wide transition-colors">Recent reflections</h2>
        <div className="space-y-3">
          {recentEntries.map((entry, index) => (
            <div
              key={index}
              className="bg-white/60 dark:bg-[#2a2435] backdrop-blur-sm rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#ede7f3]/50 dark:border-[#3d3547] hover:shadow-[0_8px_32px_rgba(102,51,153,0.12)] dark:hover:shadow-[0_8px_32px_rgba(157,143,181,0.15)] hover:border-[#d4c5e0] dark:hover:border-[#4a4057] transition-all duration-300 cursor-pointer"
            >
              <div className="flex items-start gap-4">
                <div className="w-11 h-11 rounded-[20px] bg-gradient-to-br from-[#8b7aa8] to-[#b89fb5] dark:from-[#9d8fb5] dark:to-[#d4a574] flex items-center justify-center flex-shrink-0 shadow-sm transition-all duration-300">
                  <Heart className="w-5 h-5 text-white stroke-[1.5]" />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1.5">
                    <Calendar className="w-3.5 h-3.5 text-[#b5a8c2] dark:text-[#9d8fb5] stroke-[1.5] transition-colors" />
                    <p className="text-xs text-[#9d8fb5] dark:text-[#9d8fb5] font-light transition-colors">{entry.date}</p>
                  </div>
                  <p className="text-sm text-[#6b5c75] dark:text-[#c9bfd4] line-clamp-2 font-light leading-relaxed transition-colors">{entry.preview}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Emergency Footer */}
      <EmergencyFooter />
    </div>
  );
}
