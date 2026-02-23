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
        <h1 className="text-2xl mb-2 text-[#4a3f52] font-normal">Community</h1>
        <p className="text-[#8b7a95] font-light">Connect with others on the same journey</p>
      </div>

      {/* Safety Note */}
      <div className="bg-gradient-to-br from-[#ebe4f3] via-[#e0d5eb] to-[#e8dfe8] rounded-[32px] p-6 shadow-[0_4px_24px_rgba(0,0,0,0.06)] mb-8 relative overflow-hidden">
        {/* Subtle background pattern */}
        <div className="absolute inset-0 opacity-5">
          <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-white blur-3xl"></div>
          <div className="absolute bottom-0 left-0 w-40 h-40 rounded-full bg-[#d4c5e0] blur-3xl"></div>
        </div>
        
        <div className="relative flex items-start gap-3">
          <div className="w-11 h-11 rounded-[20px] bg-white/40 backdrop-blur-sm flex items-center justify-center flex-shrink-0 shadow-sm">
            <Heart className="w-5 h-5 text-[#6b5c75] stroke-[1.5]" />
          </div>
          <div>
            <h2 className="text-lg mb-2 text-[#4a3f52] font-normal">A safe space</h2>
            <p className="text-[#6b5c75] text-sm font-light leading-relaxed">
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
              className={`px-5 py-2.5 rounded-[20px] whitespace-nowrap transition-all font-light shadow-[0_2px_12px_rgba(0,0,0,0.03)] ${
                category === "All"
                  ? "bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] text-white"
                  : "bg-white/80 backdrop-blur-sm text-[#6b5c75] border border-[#e8e0f0]/50 hover:border-[#d4c5e0]/50"
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
          <h2 className="text-[#6b5c75] font-normal text-base tracking-wide">Recent discussions</h2>
          <Link to="/community/new" className="text-sm text-[#a89cb5] font-light hover:text-[#8b7a95] transition-colors">New post</Link>
        </div>
        <div className="space-y-3">
          {discussions.map((discussion, index) => (
            <Link
              key={index}
              to={`/community/${discussion.id}`}
              className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50 hover:shadow-[0_4px_24px_rgba(0,0,0,0.06)] transition-all cursor-pointer block"
            >
              <div className="flex items-start gap-4">
                <div className="w-11 h-11 rounded-full bg-gradient-to-br from-[#d4c5e0] to-[#e0d5eb] flex items-center justify-center flex-shrink-0 text-white text-sm shadow-sm">
                  {discussion.author.charAt(0)}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-xs px-3 py-1.5 rounded-[14px] bg-[#ede7f3]/60 text-[#8b7a95] font-light">
                      {discussion.category}
                    </span>
                    {discussion.hasBlackMamaTag && (
                      <span className="text-xs px-3 py-1.5 rounded-[14px] bg-[#f0e0e8]/80 text-[#c9a9c0] flex items-center gap-1.5 font-light">
                        <Award className="w-3 h-3 stroke-[1.5]" />
                        Mama Approved™
                      </span>
                    )}
                  </div>
                  <h3 className="text-sm mb-2 text-[#4a3f52] font-normal">{discussion.title}</h3>
                  <div className="flex items-center gap-3 text-xs text-[#a89cb5] font-light">
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
          <h2 className="text-[#6b5c75] font-normal text-base tracking-wide">Trusted providers</h2>
          <button className="text-sm text-[#a89cb5] font-light hover:text-[#8b7a95] transition-colors">See all</button>
        </div>
        <div className="space-y-3">
          {providers.map((provider, index) => (
            <div
              key={index}
              className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50 hover:shadow-[0_4px_24px_rgba(0,0,0,0.06)] transition-all cursor-pointer"
            >
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-[20px] bg-gradient-to-br from-[#d4c5e0] to-[#e0d5eb] flex items-center justify-center flex-shrink-0 text-white shadow-sm">
                  {provider.name.charAt(0)}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="text-sm text-[#4a3f52] font-normal">{provider.name}</h3>
                    {provider.hasBlackMamaTag && (
                      <span className="text-xs px-2 py-1 rounded-[12px] bg-[#f0e0e8]/80 text-[#c9a9c0] flex items-center gap-1">
                        <Award className="w-3 h-3 stroke-[1.5]" />
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-[#8b7a95] mb-2 font-light">{provider.title}</p>
                  <div className="flex items-center gap-2 text-xs text-[#a89cb5] mb-2 font-light">
                    <MapPin className="w-3.5 h-3.5 stroke-[1.5]" />
                    <span>{provider.location}</span>
                  </div>
                  <div className="flex items-center gap-2 mb-3">
                    <div className="flex items-center gap-1">
                      <span className="text-[#c9b087]">★</span>
                      <span className="text-sm text-[#6b5c75] font-light">{provider.rating}</span>
                      <span className="text-xs text-[#a89cb5] font-light">({provider.reviews} reviews)</span>
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {provider.specialties.map((specialty, i) => (
                      <span
                        key={i}
                        className="text-xs px-3 py-1.5 rounded-[14px] bg-[#e8e0f0]/60 text-[#8b7a95] font-light"
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
      <div className="mb-6 bg-gradient-to-br from-[#f0ead8] to-[#f5f0e8] rounded-[28px] p-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#e8dfc8]/50">
        <div className="flex items-start gap-3">
          <div className="w-11 h-11 rounded-[20px] bg-white/60 backdrop-blur-sm flex items-center justify-center flex-shrink-0 shadow-sm">
            <Sparkles className="w-5 h-5 text-[#c9b087] stroke-[1.5]" />
          </div>
          <div className="flex-1">
            <h3 className="mb-2 text-[#4a3f52] font-normal">Share your experience</h3>
            <p className="text-sm text-[#6b5c75] mb-3 font-light leading-relaxed">
              Help others by sharing anonymous feedback about your providers and birth experience.
            </p>
            <button className="text-sm text-[#a89cb5] font-light hover:text-[#8b7a95] transition-colors">Submit feedback →</button>
          </div>
        </div>
      </div>
    </div>
  );
}
