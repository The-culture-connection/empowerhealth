import { MessageCircle, Heart, Users, MapPin, Award, ThumbsUp, MessageSquare, Sparkles } from "lucide-react";
import { Link } from "react-router";

export function Community() {
  const discussions = [
    {
      id: 1,
      title: "First time feeling movement - is this normal?",
      author: "Maya K.",
      replies: 12,
      category: "Questions",
      time: "2 hours ago",
      hasBlackMamaTag: false,
    },
    {
      id: 2,
      title: "My unmedicated birth story - you CAN do this!",
      author: "Jennifer R.",
      replies: 45,
      category: "Birth Stories",
      time: "5 hours ago",
      hasBlackMamaTag: true,
    },
    {
      id: 3,
      title: "Anxiety about upcoming glucose test",
      author: "Sarah M.",
      replies: 8,
      category: "Support",
      time: "1 day ago",
      hasBlackMamaTag: false,
    },
    {
      id: 4,
      title: "Finding a doula who looks like me",
      author: "Amara T.",
      replies: 23,
      category: "Resources",
      time: "1 day ago",
      hasBlackMamaTag: true,
    },
  ];

  const providers = [
    {
      name: "Destiny Williams",
      title: "Birth Doula",
      location: "Oakland, CA",
      rating: 4.9,
      reviews: 127,
      specialties: ["VBAC support", "Cultural sensitivity"],
      hasBlackMamaTag: true,
    },
    {
      name: "Oakland Birth Center",
      title: "Midwifery Care",
      location: "Oakland, CA",
      rating: 4.8,
      reviews: 89,
      specialties: ["Water birth", "Home birth"],
      hasBlackMamaTag: true,
    },
    {
      name: "Dr. Lisa Chen",
      title: "Maternal Mental Health",
      location: "Berkeley, CA",
      rating: 5.0,
      reviews: 64,
      specialties: ["Postpartum support", "Anxiety"],
      hasBlackMamaTag: false,
    },
  ];

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl mb-2 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Community</h1>
        <p className="text-[#6b5c75] dark:text-[#c9bfd4] font-light transition-colors">Connect with others on the same journey</p>
      </div>

      {/* Safety Note */}
      <div className="bg-gradient-to-br from-[#ebe4f3] via-[#e0d5eb] to-[#e8dfe8] dark:from-[#2d2438] dark:via-[#352d40] dark:to-[#3a2f3d] rounded-[32px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.12)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] mb-8 relative overflow-hidden border border-[#e0d3e8]/50 dark:border-[#4a4057]/30 transition-all duration-300">
        {/* Subtle background pattern */}
        <div className="absolute inset-0 opacity-30 dark:opacity-20 transition-opacity duration-300">
          <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-[#d4c5e0] dark:bg-[#663399] blur-3xl"></div>
          <div className="absolute bottom-0 left-0 w-40 h-40 rounded-full bg-[#e6d5b8] dark:bg-[#d4a574] blur-3xl"></div>
        </div>
        
        <div className="relative flex items-start gap-3">
          <div className="w-11 h-11 rounded-[20px] bg-white/40 dark:bg-[#3d3547]/60 backdrop-blur-sm flex items-center justify-center flex-shrink-0 shadow-sm transition-all duration-300">
            <Heart className="w-5 h-5 text-[#6b5c75] dark:text-[#b89fb5] stroke-[1.5] transition-colors" />
          </div>
          <div>
            <h2 className="text-lg mb-2 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">A safe space</h2>
            <p className="text-[#6b5c75] dark:text-[#c9bfd4] text-sm font-light leading-relaxed transition-colors">
              Share your experiences, ask questions, and support others. All discussions are moderated to keep this space respectful and supportive.
            </p>
          </div>
        </div>
      </div>

      {/* Categories */}
      <section className="mb-6">
        <div className="flex gap-2 overflow-x-auto pb-2">
          {["All", "Questions", "Birth Stories", "Support", "Resources"].map((category) => (
            <button
              key={category}
              className={`px-5 py-2.5 rounded-[20px] whitespace-nowrap transition-all duration-300 font-light shadow-[0_2px_12px_rgba(102,51,153,0.06)] dark:shadow-[0_2px_12px_rgba(0,0,0,0.2)] ${
                category === "All"
                  ? "bg-gradient-to-br from-[#8b7aa8] to-[#b89fb5] dark:from-[#9d8fb5] dark:to-[#d4a574] text-white"
                  : "bg-white/80 dark:bg-[#2a2435] backdrop-blur-sm text-[#6b5c75] dark:text-[#c9bfd4] border border-[#e8e0f0]/50 dark:border-[#3d3547] hover:border-[#d4c5e0]/50 dark:hover:border-[#4a4057]"
              }`}
            >
              {category}
            </button>
          ))}
        </div>
      </section>

      {/* Discussions */}
      <section className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-[#4a3f52] dark:text-[#c9bfd4] font-normal text-base tracking-wide transition-colors">Recent discussions</h2>
          <Link to="/community/new" className="text-sm text-[#9d8fb5] dark:text-[#9d8fb5] font-light hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors">New post</Link>
        </div>
        <div className="space-y-3">
          {discussions.map((discussion, index) => (
            <Link
              key={index}
              to={`/community/${discussion.id}`}
              className="bg-white/60 dark:bg-[#2a2435] backdrop-blur-sm rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#ede7f3]/50 dark:border-[#3d3547] hover:shadow-[0_8px_32px_rgba(102,51,153,0.12)] dark:hover:shadow-[0_8px_32px_rgba(157,143,181,0.15)] hover:border-[#d4c5e0] dark:hover:border-[#4a4057] transition-all duration-300 cursor-pointer block"
            >
              <div className="flex items-start gap-4">
                <div className="w-11 h-11 rounded-full bg-gradient-to-br from-[#8b7aa8] to-[#b89fb5] dark:from-[#9d8fb5] dark:to-[#d4a574] flex items-center justify-center flex-shrink-0 text-white text-sm shadow-sm transition-all duration-300">
                  {discussion.author.charAt(0)}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-xs px-3 py-1.5 rounded-[14px] bg-[#ede7f3]/60 dark:bg-[#3d3547] text-[#8b7a95] dark:text-[#b89fb5] font-light transition-all duration-300">
                      {discussion.category}
                    </span>
                    {discussion.hasBlackMamaTag && (
                      <span className="text-xs px-3 py-1.5 rounded-[14px] bg-[#f0e0e8]/80 dark:bg-[#3d3040] text-[#c9a9c0] dark:text-[#d4a574] flex items-center gap-1.5 font-light transition-all duration-300">
                        <Award className="w-3 h-3 stroke-[1.5]" />
                        Mama Approved™
                      </span>
                    )}
                  </div>
                  <h3 className="text-sm mb-2 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">{discussion.title}</h3>
                  <div className="flex items-center gap-3 text-xs text-[#9d8fb5] dark:text-[#9d8fb5] font-light transition-colors">
                    <span>{discussion.author}</span>
                    <span>•</span>
                    <span className="flex items-center gap-1">
                      <MessageSquare className="w-3.5 h-3.5 stroke-[1.5]" />
                      {discussion.replies} replies
                    </span>
                    <span>•</span>
                    <span>{discussion.time}</span>
                  </div>
                </div>
              </div>
            </Link>
          ))}
        </div>
      </section>

      {/* Provider Directory */}
      <section className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-[#4a3f52] dark:text-[#c9bfd4] font-normal text-base tracking-wide transition-colors">Trusted providers</h2>
          <button className="text-sm text-[#9d8fb5] dark:text-[#9d8fb5] font-light hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors">See all</button>
        </div>
        <div className="space-y-3">
          {providers.map((provider, index) => (
            <div
              key={index}
              className="bg-white/60 dark:bg-[#2a2435] backdrop-blur-sm rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#ede7f3]/50 dark:border-[#3d3547] hover:shadow-[0_8px_32px_rgba(102,51,153,0.12)] dark:hover:shadow-[0_8px_32px_rgba(157,143,181,0.15)] hover:border-[#d4c5e0] dark:hover:border-[#4a4057] transition-all duration-300 cursor-pointer"
            >
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-[20px] bg-gradient-to-br from-[#8b7aa8] to-[#b89fb5] dark:from-[#9d8fb5] dark:to-[#d4a574] flex items-center justify-center flex-shrink-0 text-white shadow-sm transition-all duration-300">
                  {provider.name.charAt(0)}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="text-sm text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">{provider.name}</h3>
                    {provider.hasBlackMamaTag && (
                      <span className="text-xs px-2 py-1 rounded-[12px] bg-[#f0e0e8]/80 dark:bg-[#3d3040] text-[#c9a9c0] dark:text-[#d4a574] flex items-center gap-1 transition-all duration-300">
                        <Award className="w-3 h-3 stroke-[1.5]" />
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-[#6b5c75] dark:text-[#b89fb5] mb-2 font-light transition-colors">{provider.title}</p>
                  <div className="flex items-center gap-2 text-xs text-[#9d8fb5] dark:text-[#9d8fb5] mb-2 font-light transition-colors">
                    <MapPin className="w-3.5 h-3.5 stroke-[1.5]" />
                    <span>{provider.location}</span>
                  </div>
                  <div className="flex items-center gap-2 mb-3">
                    <div className="flex items-center gap-1">
                      <span className="text-[#d4a574] dark:text-[#e0b589] transition-colors">★</span>
                      <span className="text-sm text-[#6b5c75] dark:text-[#c9bfd4] font-light transition-colors">{provider.rating}</span>
                      <span className="text-xs text-[#9d8fb5] dark:text-[#9d8fb5] font-light transition-colors">({provider.reviews} reviews)</span>
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {provider.specialties.map((specialty, i) => (
                      <span
                        key={i}
                        className="text-xs px-3 py-1.5 rounded-[14px] bg-[#e8e0f0]/60 dark:bg-[#3d3547] text-[#8b7a95] dark:text-[#b89fb5] font-light transition-all duration-300"
                      >
                        {specialty}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Anonymous Feedback */}
      <div className="mb-6 bg-gradient-to-br from-[#f9f2e8] to-[#fef9f5] dark:from-[#3d3540] dark:to-[#453d48] rounded-[28px] p-6 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#e8dfc8]/50 dark:border-[#3d3547] transition-all duration-300">
        <div className="flex items-start gap-3">
          <div className="w-11 h-11 rounded-[20px] bg-white/60 dark:bg-[#4a4057]/60 backdrop-blur-sm flex items-center justify-center flex-shrink-0 shadow-sm transition-all duration-300">
            <Sparkles className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5] transition-colors" />
          </div>
          <div className="flex-1">
            <h3 className="mb-2 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Share your experience</h3>
            <p className="text-sm text-[#6b5c75] dark:text-[#c9bfd4] mb-3 font-light leading-relaxed transition-colors">
              Help others by sharing anonymous feedback about your providers and birth experience.
            </p>
            <button className="text-sm text-[#9d8fb5] dark:text-[#9d8fb5] font-light hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors">Submit feedback →</button>
          </div>
        </div>
      </div>
    </div>
  );
}
