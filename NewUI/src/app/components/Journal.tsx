import { Heart, Cloud, Sparkles, Calendar } from "lucide-react";
import { useState, useEffect } from "react";
import { authService } from "../../services/authService";
import { databaseService, JournalEntry } from "../../services/databaseService";
import { format } from "date-fns";

export function Journal() {
  const [entry, setEntry] = useState("");
  const [selectedMood, setSelectedMood] = useState<string>("");
  const [entries, setEntries] = useState<JournalEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const prompts = [
    "How are you feeling today?",
    "What brought you peace this week?",
    "What concerns are on your mind?",
    "What are you grateful for right now?",
    "What do you want to remember about this moment?",
  ];

  useEffect(() => {
    const user = authService.currentUser;
    if (!user) {
      setLoading(false);
      return;
    }

    const unsubscribe = databaseService.streamJournalEntries(user.uid, (journalEntries) => {
      setEntries(journalEntries);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleSave = async () => {
    const user = authService.currentUser;
    if (!user || !entry.trim()) return;

    setSaving(true);
    try {
      await databaseService.saveJournalEntry({
        userId: user.uid,
        content: entry,
        mood: selectedMood,
        createdAt: new Date(),
      });
      setEntry("");
      setSelectedMood("");
    } catch (error: any) {
      alert(`Error saving entry: ${error.message}`);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-5">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl mb-2">Your Journal</h1>
        <p className="text-gray-600">A safe space for your thoughts and feelings</p>
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
            <button
              onClick={handleSave}
              disabled={saving || !entry.trim()}
              className="flex-1 py-3 px-4 rounded-2xl bg-[#663399] text-white hover:bg-[#552288] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {saving ? "Saving..." : "Save Entry"}
            </button>
            <button
              onClick={() => {
                setEntry("");
                setSelectedMood("");
              }}
              className="px-4 py-3 rounded-2xl border border-gray-200 text-gray-600 hover:bg-gray-50 transition-colors"
            >
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
              { emoji: "😊", label: "Joyful", value: "joyful" },
              { emoji: "😌", label: "Calm", value: "calm" },
              { emoji: "😐", label: "Okay", value: "okay" },
              { emoji: "😟", label: "Worried", value: "worried" },
              { emoji: "😢", label: "Tearful", value: "tearful" },
            ].map((mood) => (
              <button
                key={mood.label}
                onClick={() => setSelectedMood(mood.value)}
                className={`flex flex-col items-center gap-2 p-3 rounded-2xl transition-colors ${
                  selectedMood === mood.value
                    ? "bg-[#663399]/10 border-2 border-[#663399]"
                    : "hover:bg-gray-50"
                }`}
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
        {loading ? (
          <div className="text-center py-8 text-gray-500">Loading entries...</div>
        ) : entries.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            <p>No entries yet. Start writing to see your reflections here.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {entries.slice(0, 10).map((entry) => (
              <div
                key={entry.id}
                className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors cursor-pointer"
              >
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-[#663399] to-[#cbbec9] flex items-center justify-center flex-shrink-0">
                    <Heart className="w-5 h-5 text-white" />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <Calendar className="w-3.5 h-3.5 text-gray-400" />
                      <p className="text-xs text-gray-500">
                        {format(entry.createdAt, "MMMM d, yyyy")}
                      </p>
                      {entry.mood && (
                        <span className="text-xs px-2 py-0.5 rounded-lg bg-purple-50 text-[#663399]">
                          {entry.mood}
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-gray-700 line-clamp-2">{entry.content}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Privacy Note */}
      <div className="mt-6 bg-gradient-to-br from-blue-50 to-purple-50 rounded-3xl p-5 shadow-sm border border-blue-100">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-2xl bg-blue-100 flex items-center justify-center flex-shrink-0">
            <Cloud className="w-5 h-5 text-blue-600" />
          </div>
          <div>
            <h3 className="mb-1">Your Private Space</h3>
            <p className="text-sm text-gray-600">
              Your journal entries are private and encrypted. They're for you, and you can choose if you want to share specific entries with your care team.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
