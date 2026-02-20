import { ArrowLeft, Award } from "lucide-react";
import { Link } from "react-router";
import { useState } from "react";

export function NewPost() {
  const [category, setCategory] = useState("Questions");
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [isAnonymous, setIsAnonymous] = useState(false);

  const categories = [
    "Questions",
    "Birth Stories",
    "Support",
    "Resources",
    "Advice Needed",
    "Celebration"
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] pb-24">
      {/* Header */}
      <div className="bg-white border-b border-gray-100 px-5 py-4 sticky top-0 z-10">
        <div className="flex items-center justify-between">
          <Link to="/community" className="flex items-center gap-2 text-gray-600 hover:text-[#663399] transition-colors">
            <ArrowLeft className="w-5 h-5" />
            <span className="text-sm">Cancel</span>
          </Link>
          <button 
            disabled={!title.trim() || !content.trim()}
            className="py-2 px-6 rounded-2xl bg-[#663399] text-white text-sm hover:bg-[#552288] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Post
          </button>
        </div>
      </div>

      <div className="max-w-2xl mx-auto p-5">
        {/* Welcome Message */}
        <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] rounded-3xl p-6 text-white shadow-md mb-6">
          <h1 className="text-xl mb-2">Share Your Story</h1>
          <p className="text-white/90 text-sm">
            Your voice matters. Share your experiences, ask questions, or offer support to other mothers. This is a safe, judgment-free space.
          </p>
        </div>

        {/* Post Form */}
        <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 mb-4">
          {/* Category Selection */}
          <div className="mb-6">
            <label className="block text-sm font-medium mb-3">Category</label>
            <div className="flex flex-wrap gap-2">
              {categories.map((cat) => (
                <button
                  key={cat}
                  onClick={() => setCategory(cat)}
                  className={`px-4 py-2 rounded-2xl text-sm transition-colors ${
                    category === cat
                      ? "bg-[#663399] text-white"
                      : "bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30"
                  }`}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>

          {/* Title Input */}
          <div className="mb-6">
            <label className="block text-sm font-medium mb-2">Title</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Give your post a clear, descriptive title..."
              className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors"
            />
            <p className="text-xs text-gray-500 mt-2">
              Example: "First time feeling movement - is this normal?"
            </p>
          </div>

          {/* Content Textarea */}
          <div className="mb-6">
            <label className="block text-sm font-medium mb-2">Your Story</label>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={12}
              placeholder="Share your thoughts, experiences, questions, or advice. Be as detailed as you'd like - your story could help another mother..."
              className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors resize-none"
            ></textarea>
            <p className="text-xs text-gray-500 mt-2">
              Take your time. There's no rush - share what feels comfortable.
            </p>
          </div>

          {/* Anonymous Toggle */}
          <div className="mb-6 p-4 bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl border border-blue-100">
            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={isAnonymous}
                onChange={(e) => setIsAnonymous(e.target.checked)}
                className="mt-1 w-5 h-5 rounded border-gray-300 text-[#663399] focus:ring-[#663399]/20"
              />
              <div>
                <span className="block text-sm font-medium mb-1">Post anonymously</span>
                <span className="text-xs text-gray-600">
                  Your post will be shared without showing your name or profile. You'll still be able to see and manage your own posts.
                </span>
              </div>
            </label>
          </div>
        </div>

        {/* Community Guidelines Reminder */}
        <div className="bg-gradient-to-br from-[#fef3f3] to-[#fff0f8] rounded-3xl p-5 shadow-sm border border-pink-100">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-2xl bg-rose-100 flex items-center justify-center flex-shrink-0">
              <Award className="w-5 h-5 text-rose-600" />
            </div>
            <div>
              <h3 className="mb-2">Community Guidelines</h3>
              <ul className="text-sm text-gray-600 space-y-1.5">
                <li>• Be kind, respectful, and supportive</li>
                <li>• Avoid medical advice - share experiences only</li>
                <li>• Respect privacy - don't share others' personal information</li>
                <li>• Report harmful or inappropriate content</li>
              </ul>
              <p className="text-xs text-gray-500 mt-3">
                All posts are moderated to ensure a safe, supportive environment for everyone.
              </p>
            </div>
          </div>
        </div>

        {/* Support Note */}
        <div className="mt-6 text-center">
          <p className="text-sm text-gray-500">
            Need immediate support? Call the National Maternal Mental Health Hotline
          </p>
          <a href="tel:1-833-943-5746" className="text-[#663399] font-medium text-sm">
            1-833-9-HELP4MOMS
          </a>
        </div>
      </div>
    </div>
  );
}
