import { MessageCircle, Heart, Users, MapPin, Award, ThumbsUp, MessageSquare } from "lucide-react";
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
    <div className="p-5">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl mb-2">Community</h1>
        <p className="text-gray-600">Connect with others on the same journey</p>
      </div>

      {/* Safety Note */}
      <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] rounded-3xl p-5 text-white shadow-md mb-6">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-2xl bg-white/20 flex items-center justify-center flex-shrink-0">
            <Heart className="w-5 h-5 text-white" />
          </div>
          <div>
            <h2 className="text-lg mb-1">A Safe Space</h2>
            <p className="text-white/90 text-sm">
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
              className={`px-4 py-2 rounded-2xl whitespace-nowrap transition-colors ${
                category === "All"
                  ? "bg-[#663399] text-white"
                  : "bg-white text-gray-700 border border-gray-200 hover:border-[#663399]/30"
              }`}
            >
              {category}
            </button>
          ))}
        </div>
      </section>

      {/* Discussions */}
      <section className="mb-8">
        <div className="flex items-center justify-between mb-3">
          <h2>Recent Discussions</h2>
          <Link to="/community/new" className="text-sm text-[#663399]">New post</Link>
        </div>
        <div className="space-y-3">
          {discussions.map((discussion, index) => (
            <Link
              key={index}
              to={`/community/${discussion.id}`}
              className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors cursor-pointer block"
            >
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#663399] to-[#cbbec9] flex items-center justify-center flex-shrink-0 text-white text-sm">
                  {discussion.author.charAt(0)}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-xs px-2 py-1 rounded-lg bg-gray-100 text-gray-600">
                      {discussion.category}
                    </span>
                    {discussion.hasBlackMamaTag && (
                      <span className="text-xs px-2 py-1 rounded-lg bg-rose-100 text-rose-700 flex items-center gap-1">
                        <Award className="w-3 h-3" />
                        Black Mama Approved
                      </span>
                    )}
                  </div>
                  <h3 className="text-sm mb-1">{discussion.title}</h3>
                  <div className="flex items-center gap-3 text-xs text-gray-500">
                    <span>{discussion.author}</span>
                    <span>•</span>
                    <span className="flex items-center gap-1">
                      <MessageSquare className="w-3.5 h-3.5" />
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
      <section>
        <div className="flex items-center justify-between mb-3">
          <h2>Trusted Providers</h2>
          <button className="text-sm text-[#663399]">See all</button>
        </div>
        <div className="space-y-3">
          {providers.map((provider, index) => (
            <div
              key={index}
              className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors cursor-pointer"
            >
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#663399] to-[#cbbec9] flex items-center justify-center flex-shrink-0 text-white">
                  {provider.name.charAt(0)}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="text-sm">{provider.name}</h3>
                    {provider.hasBlackMamaTag && (
                      <span className="text-xs px-2 py-1 rounded-lg bg-rose-100 text-rose-700 flex items-center gap-1">
                        <Award className="w-3 h-3" />
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-gray-600 mb-2">{provider.title}</p>
                  <div className="flex items-center gap-2 text-xs text-gray-500 mb-2">
                    <MapPin className="w-3.5 h-3.5" />
                    <span>{provider.location}</span>
                  </div>
                  <div className="flex items-center gap-2 mb-2">
                    <div className="flex items-center gap-1">
                      <span className="text-amber-500">★</span>
                      <span className="text-sm">{provider.rating}</span>
                      <span className="text-xs text-gray-500">({provider.reviews} reviews)</span>
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {provider.specialties.map((specialty, i) => (
                      <span
                        key={i}
                        className="text-xs px-2 py-1 rounded-lg bg-purple-50 text-[#663399]"
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
      <div className="mt-6 bg-gradient-to-br from-blue-50 to-purple-50 rounded-3xl p-5 shadow-sm border border-blue-100">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-2xl bg-blue-100 flex items-center justify-center flex-shrink-0">
            <ThumbsUp className="w-5 h-5 text-blue-600" />
          </div>
          <div className="flex-1">
            <h3 className="mb-1">Share Your Experience</h3>
            <p className="text-sm text-gray-600 mb-3">
              Help others by sharing anonymous feedback about your providers and birth experience.
            </p>
            <button className="text-sm text-[#663399]">Submit feedback →</button>
          </div>
        </div>
      </div>
    </div>
  );
}