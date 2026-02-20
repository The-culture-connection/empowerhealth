import { Heart, Cloud, Sparkles, Calendar } from "lucide-react";
import { useState } from "react";
import { SecureIndicator, EmergencyFooter } from "./PrivacyComponents";

export function Journal() {
  const [entry, setEntry] = useState("");

  const prompts = [
    "How are you feeling today?",
    "What brought you peace this week?",
    "What concerns are on your mind?",
    "What are you grateful for right now?",
    "What do you want to remember about this moment?",
  ];

  const recentEntries = [
    {
      date: "February 14, 2026",
      preview: "Today I felt the baby kick for the first time during the ultrasound...",
      mood: "joyful",
    },
    {
      date: "February 10, 2026",
      preview: "Feeling a bit anxious about the glucose test coming up...",
      mood: "thoughtful",
    },
    {
      date: "February 7, 2026",
      preview: "Had a beautiful conversation with my partner about names...",
      mood: "peaceful",
    },
  ];

  return (
    <div className="p-5 pb-24">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl mb-2">Your Journal</h1>
        <p className="text-gray-600">A safe space for your thoughts and feelings</p>
      </div>

      {/* Privacy Notice */}
      <div className="bg-gradient-to-br from-[#cbbec9]/20 to-[#cbbec9]/10 rounded-2xl p-4 border border-[#cbbec9]/30 mb-6">
        <div className="flex items-start gap-3">
          <div className="w-8 h-8 rounded-xl bg-white flex items-center justify-center flex-shrink-0">
            <Heart className="w-4 h-4 text-[#663399]" />
          </div>
          <div>
            <p className="text-sm text-gray-700 mb-2">
              Your journal is private. Only you can see what you write here.
            </p>
            <SecureIndicator />
          </div>
        </div>
      </div>

      {/* Current Entry */}
      <section className="mb-6">
        <div className="bg-gradient-to-br from-[#fef3f3] to-[#fff0f8] rounded-3xl p-6 shadow-sm border border-pink-100 mb-4">
          <div className="flex items-center gap-2 mb-4">
            <Sparkles className="w-5 h-5 text-rose-500" />
            <h2>Today's Entry</h2>
          </div>
          
          {/* Writing Prompts */}
          <div className="mb-4">
            <p className="text-sm text-gray-600 mb-2">Not sure where to start? Try a prompt:</p>
            <div className="flex flex-wrap gap-2">
              {prompts.slice(0, 3).map((prompt, index) => (
                <button
                  key={index}
                  onClick={() => setEntry(prompt + "\n\n")}
                  className="text-xs px-3 py-2 rounded-xl bg-white text-gray-700 hover:bg-rose-50 hover:text-rose-700 transition-colors border border-gray-200"
                >
                  {prompt}
                </button>
              ))}
            </div>
          </div>

          <textarea
            value={entry}
            onChange={(e) => setEntry(e.target.value)}
            rows={6}
            placeholder="What's on your mind today?"
            className="w-full px-4 py-4 rounded-2xl bg-white border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 resize-none text-gray-700 placeholder:text-gray-400"
          ></textarea>

          <div className="flex items-center gap-3 mt-4">
            <button className="flex-1 py-3 px-4 rounded-2xl bg-[#663399] text-white hover:bg-[#552288] transition-colors">
              Save Entry
            </button>
            <button className="px-4 py-3 rounded-2xl border border-gray-200 text-gray-600 hover:bg-gray-50 transition-colors">
              Cancel
            </button>
          </div>
        </div>
      </section>

      {/* Mood Check */}
      <section className="mb-6">
        <h2 className="mb-3">How are you feeling today?</h2>
        <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
          <div className="grid grid-cols-5 gap-3">
            {[
              { emoji: "😊", label: "Joyful" },
              { emoji: "😌", label: "Calm" },
              { emoji: "😐", label: "Okay" },
              { emoji: "😟", label: "Worried" },
              { emoji: "😢", label: "Tearful" },
            ].map((mood) => (
              <button
                key={mood.label}
                className="flex flex-col items-center gap-2 p-3 rounded-2xl hover:bg-gray-50 transition-colors"
              >
                <span className="text-3xl">{mood.emoji}</span>
                <span className="text-xs text-gray-600">{mood.label}</span>
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* Past Entries */}
      <section>
        <h2 className="mb-3">Recent Reflections</h2>
        <div className="space-y-3">
          {recentEntries.map((entry, index) => (
            <div
              key={index}
              className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors cursor-pointer"
            >
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-[#663399] to-[#cbbec9] flex items-center justify-center flex-shrink-0">
                  <Heart className="w-5 h-5 text-white" />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <Calendar className="w-3.5 h-3.5 text-gray-400" />
                    <p className="text-xs text-gray-500">{entry.date}</p>
                  </div>
                  <p className="text-sm text-gray-700 line-clamp-2">{entry.preview}</p>
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