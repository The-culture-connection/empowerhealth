import { ArrowLeft, Heart, MessageCircle, Share2, Flag, ThumbsUp, Award, MoreVertical } from "lucide-react";
import { Link } from "react-router";
import { useState } from "react";

export function PostDetail() {
  const [liked, setLiked] = useState(false);
  const [comment, setComment] = useState("");
  
  const post = {
    id: 1,
    title: "My unmedicated birth story - you CAN do this!",
    author: "Jennifer R.",
    authorInitial: "J",
    category: "Birth Stories",
    time: "5 hours ago",
    hasBlackMamaTag: true,
    content: `I wanted to share my birth story because I know how much reading other women's experiences helped me prepare for mine.

At 39 weeks, I went into labor naturally around 2am. I had been practicing breathing techniques and visualization for months, and I'm so glad I did. 

The early labor at home was actually peaceful. I lit candles, played my favorite music, and my partner helped me through contractions with massage. We stayed home until contractions were 5 minutes apart.

When we got to the birth center, I was already 6cm dilated! The midwives were amazing - they let me labor in the tub, move around freely, and never once pressured me about pain management.

The hardest part was transition (aren't they all?), but having my doula there reminding me that I was made for this kept me going. I pushed for about 45 minutes and our beautiful baby girl arrived at 2:47pm.

The feeling of empowerment was incredible. My body knew exactly what to do. If you're considering unmedicated birth, I want you to know - you are strong enough. Trust yourself.

Happy to answer any questions! 💜`,
    likes: 142,
    comments: 45,
    helpful: 98,
  };

  const replies = [
    {
      author: "Maya K.",
      authorInitial: "M",
      time: "4 hours ago",
      content: "This is so inspiring! I'm 32 weeks and planning an unmedicated birth too. Did you take any specific classes to prepare?",
      likes: 12,
      hasBlackMamaTag: false,
    },
    {
      author: "Jennifer R.",
      authorInitial: "J",
      time: "3 hours ago",
      content: "Yes! I took a HypnoBirthing class and also worked with my doula starting at 28 weeks. The breathing techniques were game-changers for me.",
      likes: 8,
      isOP: true,
      hasBlackMamaTag: true,
    },
    {
      author: "Destiny L.",
      authorInitial: "D",
      time: "3 hours ago",
      content: "Beautiful story, mama! Your strength is inspiring. I had a similar experience at a birth center and it was the most empowering day of my life. 🙏🏾",
      likes: 15,
      hasBlackMamaTag: true,
    },
    {
      author: "Sarah M.",
      authorInitial: "S",
      time: "2 hours ago",
      content: "Thank you for sharing this. I've been feeling nervous about my upcoming birth, but reading your story gives me confidence.",
      likes: 7,
      hasBlackMamaTag: false,
    },
    {
      author: "Keisha R.",
      authorInitial: "K",
      time: "1 hour ago",
      content: "Love this! I'm a doula and I always tell my clients - your body is DESIGNED for this. Trust the process. Congratulations on your beautiful birth! 💜",
      likes: 23,
      hasBlackMamaTag: true,
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] pb-24">
      {/* Header */}
      <div className="bg-white border-b border-gray-100 px-5 py-4 sticky top-0 z-10">
        <div className="flex items-center justify-between">
          <Link to="/community" className="flex items-center gap-2 text-gray-600 hover:text-[#663399] transition-colors">
            <ArrowLeft className="w-5 h-5" />
            <span className="text-sm">Back to Community</span>
          </Link>
          <button className="p-2 hover:bg-gray-50 rounded-full transition-colors">
            <MoreVertical className="w-5 h-5 text-gray-400" />
          </button>
        </div>
      </div>

      <div className="max-w-2xl mx-auto p-5">
        {/* Post Header */}
        <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 mb-4">
          {/* Category Badge */}
          <div className="flex items-center gap-2 mb-4">
            <span className="text-xs px-3 py-1.5 rounded-full bg-purple-50 text-[#663399] border border-purple-100">
              {post.category}
            </span>
            {post.hasBlackMamaTag && (
              <span className="text-xs px-3 py-1.5 rounded-full bg-gradient-to-r from-rose-50 to-pink-50 border border-rose-200 flex items-center gap-1">
                <Award className="w-3.5 h-3.5 text-rose-600" />
                <span className="text-rose-700 font-medium">Black Mama Approved</span>
              </span>
            )}
          </div>

          {/* Author Info */}
          <div className="flex items-start gap-3 mb-4">
            <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#663399] to-[#cbbec9] flex items-center justify-center text-white flex-shrink-0">
              {post.authorInitial}
            </div>
            <div className="flex-1">
              <h3 className="text-sm font-medium mb-0.5">{post.author}</h3>
              <p className="text-xs text-gray-500">{post.time}</p>
            </div>
          </div>

          {/* Post Title */}
          <h1 className="text-xl mb-4">{post.title}</h1>

          {/* Post Content */}
          <div className="prose prose-sm max-w-none mb-6">
            {post.content.split('\n\n').map((paragraph, index) => (
              <p key={index} className="text-gray-700 mb-3 last:mb-0">
                {paragraph}
              </p>
            ))}
          </div>

          {/* Engagement Stats */}
          <div className="flex items-center gap-4 py-4 border-t border-gray-100">
            <div className="flex items-center gap-1.5 text-sm text-gray-600">
              <Heart className={`w-4 h-4 ${liked ? 'fill-rose-500 text-rose-500' : ''}`} />
              <span>{post.likes + (liked ? 1 : 0)}</span>
            </div>
            <div className="flex items-center gap-1.5 text-sm text-gray-600">
              <MessageCircle className="w-4 h-4" />
              <span>{post.comments}</span>
            </div>
            <div className="flex items-center gap-1.5 text-sm text-gray-600">
              <ThumbsUp className="w-4 h-4" />
              <span>{post.helpful} found helpful</span>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="grid grid-cols-3 gap-2">
            <button
              onClick={() => setLiked(!liked)}
              className={`py-2.5 px-4 rounded-2xl transition-colors flex items-center justify-center gap-2 text-sm ${
                liked
                  ? 'bg-rose-50 text-rose-600 border border-rose-200'
                  : 'bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30'
              }`}
            >
              <Heart className={`w-4 h-4 ${liked ? 'fill-rose-500' : ''}`} />
              <span>{liked ? 'Liked' : 'Like'}</span>
            </button>
            <button className="py-2.5 px-4 rounded-2xl bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30 transition-colors flex items-center justify-center gap-2 text-sm">
              <Share2 className="w-4 h-4" />
              <span>Share</span>
            </button>
            <button className="py-2.5 px-4 rounded-2xl bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30 transition-colors flex items-center justify-center gap-2 text-sm">
              <Flag className="w-4 h-4" />
              <span>Report</span>
            </button>
          </div>
        </div>

        {/* Replies Section */}
        <div className="mb-6">
          <h2 className="mb-4">{replies.length} Replies</h2>
          
          <div className="space-y-3">
            {replies.map((reply, index) => (
              <div key={index} className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-start gap-3 mb-3">
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#663399] to-[#cbbec9] flex items-center justify-center text-white text-sm flex-shrink-0">
                    {reply.authorInitial}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="text-sm font-medium">{reply.author}</h3>
                      {reply.isOP && (
                        <span className="text-xs px-2 py-0.5 rounded-full bg-[#663399]/10 text-[#663399] border border-[#663399]/20">
                          Original Poster
                        </span>
                      )}
                      {reply.hasBlackMamaTag && (
                        <Award className="w-3.5 h-3.5 text-rose-600" />
                      )}
                    </div>
                    <p className="text-xs text-gray-500">{reply.time}</p>
                  </div>
                </div>
                
                <p className="text-sm text-gray-700 mb-3">{reply.content}</p>
                
                <div className="flex items-center gap-3">
                  <button className="flex items-center gap-1.5 text-xs text-gray-600 hover:text-[#663399] transition-colors">
                    <Heart className="w-3.5 h-3.5" />
                    <span>{reply.likes}</span>
                  </button>
                  <button className="text-xs text-gray-600 hover:text-[#663399] transition-colors">
                    Reply
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Add Comment */}
        <div className="bg-gradient-to-br from-[#fef3f3] to-[#fff0f8] rounded-3xl p-5 shadow-sm border border-pink-100">
          <h3 className="mb-3">Add Your Reply</h3>
          <textarea
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            rows={4}
            placeholder="Share your thoughts, experiences, or encouragement..."
            className="w-full px-4 py-3 rounded-2xl bg-white border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 resize-none text-sm mb-3"
          ></textarea>
          <div className="flex items-center justify-between">
            <p className="text-xs text-gray-500">Be kind and supportive 💜</p>
            <button 
              disabled={!comment.trim()}
              className="py-2.5 px-6 rounded-2xl bg-[#663399] text-white text-sm hover:bg-[#552288] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Post Reply
            </button>
          </div>
        </div>

        {/* Community Guidelines */}
        <div className="mt-6 bg-gradient-to-br from-blue-50 to-purple-50 rounded-3xl p-5 shadow-sm border border-blue-100">
          <h3 className="mb-2">Community Guidelines</h3>
          <p className="text-sm text-gray-600">
            This is a safe space for sharing experiences and supporting each other. All posts are moderated to ensure respect and kindness. Harmful or disrespectful content will be removed.
          </p>
        </div>
      </div>
    </div>
  );
}
