import { ChevronLeft, Star, MapPin, Phone, Clock, Award, Heart, ThumbsUp, Quote, Shield } from "lucide-react";
import { Link } from "react-router";
import { ProviderReviewBoundary } from "./PrivacyComponents";

export function ProviderDetailProfile() {
  const provider = {
    name: "Dr. Aisha Williams",
    credentials: "MD, FACOG",
    specialty: "OB-GYN",
    practice: "Equity Maternal Health",
    location: "Columbus, OH",
    address: "1234 Healthcare Drive, Columbus, OH 43215",
    distance: "4.1 miles",
    rating: 4.9,
    reviews: 189,
    acceptingNew: true,
    languages: ["English"],
    specialties: ["Cultural sensitivity", "Birth trauma", "VBAC support", "High-risk pregnancy"],
    hasBlackMamaTag: true,
    phone: "(614) 555-0142",
    hours: "Mon-Fri 8am-6pm",
    insurance: ["Medicaid", "Medicare", "Blue Cross", "Aetna", "United Healthcare"],
    bio: "Dr. Williams is committed to providing culturally sensitive, trauma-informed care. She believes every person deserves to be heard, respected, and supported throughout their pregnancy journey.",
  };

  const reviews = [
    {
      author: "Jasmine M.",
      rating: 5,
      date: "2 weeks ago",
      text: "Dr. Williams took the time to listen to all my concerns and made me feel truly heard. She respected my birth plan and was so supportive throughout my pregnancy.",
      helpful: 45,
    },
    {
      author: "Maria S.",
      rating: 5,
      date: "1 month ago",
      text: "I felt safe and cared for at every appointment. Dr. Williams explains everything clearly and never rushes you.",
      helpful: 38,
    },
    {
      author: "Amara T.",
      rating: 5,
      date: "2 months ago",
      text: "Finding Dr. Williams changed my entire pregnancy experience. She's knowledgeable, compassionate, and truly advocates for her patients.",
      helpful: 52,
    },
  ];

  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] relative overflow-hidden transition-colors duration-500">
      {/* Warm ambient light */}
      <div className="fixed inset-0 opacity-40 dark:opacity-30 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[140px]"></div>
      </div>

      <div className="relative p-6 pb-24 max-w-2xl mx-auto">
        {/* Back Navigation */}
        <Link to="/providers" className="inline-flex items-center gap-2 mb-8 text-[#75657d] dark:text-[#cbbec9] hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors duration-300">
          <ChevronLeft className="w-4 h-4 stroke-[1.5]" />
          <span className="text-sm font-light tracking-wide">All providers</span>
        </Link>

        {/* Provider Header Card */}
        <div className="relative bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] dark:from-[#2a2435] dark:via-[#3a3149] dark:to-[#4a3e5d] rounded-[24px] p-8 mb-6 shadow-[0_20px_60px_rgba(102,51,153,0.25),_inset_0_1px_0_rgba(255,255,255,0.1)] dark:shadow-[0_24px_72px_rgba(0,0,0,0.5)] overflow-hidden transition-all duration-500">
          {/* Soft inner glow */}
          <div className="absolute inset-0 opacity-20">
            <div className="absolute top-0 right-0 w-48 h-48 rounded-full bg-[#d4a574] blur-[80px]"></div>
          </div>

          <div className="relative">
            <div className="flex items-start justify-between mb-6">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-3">
                  <h1 className="text-[#f5f0f7] dark:text-[#ffffff] text-[24px] font-[450] tracking-[-0.01em]">{provider.name}</h1>
                  {provider.hasBlackMamaTag && (
                    <div className="px-3 py-1.5 rounded-full bg-white/10 backdrop-blur-sm border border-white/20 flex items-center gap-1.5">
                      <Award className="w-4 h-4 text-[#d4a574] stroke-[1.5]" />
                      <span className="text-[#f5f0f7] text-xs font-light tracking-wide">Mama Approved™</span>
                    </div>
                  )}
                </div>
                <p className="text-[#e8dff0] dark:text-[#e8e0f0] text-sm font-light mb-1">{provider.credentials}</p>
                <p className="text-[#e8dff0] dark:text-[#e8e0f0] text-sm font-light mb-1">{provider.specialty} • {provider.practice}</p>
                <div className="flex items-center gap-2 mt-3">
                  <div className="flex items-center gap-1.5">
                    <Star className="w-4 h-4 text-[#d4a574] fill-[#d4a574] stroke-[1.5]" />
                    <span className="text-[#f5f0f7] text-sm font-[450]">{provider.rating}</span>
                    <span className="text-[#e8dff0] text-xs font-light">({provider.reviews} reviews)</span>
                  </div>
                </div>
              </div>
            </div>

            {provider.acceptingNew && (
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[#e8f5f0]/20 backdrop-blur-sm border border-[#89c5a6]/30">
                <div className="w-1.5 h-1.5 rounded-full bg-[#89c5a6]"></div>
                <span className="text-[#f5f0f7] text-xs tracking-wide font-light">Accepting new patients</span>
              </div>
            )}
          </div>
        </div>

        {/* Contact Information */}
        <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-7 mb-6 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
          <h2 className="text-[#663399] dark:text-[#cbbec9] text-[11px] uppercase tracking-[0.08em] mb-5 font-medium">Contact</h2>
          
          <div className="space-y-4">
            <div className="flex items-start gap-3">
              <MapPin className="w-5 h-5 text-[#cbbec9] dark:text-[#75657d] stroke-[1.5] flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">{provider.address}</p>
                <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light mt-1">{provider.distance} away</p>
              </div>
            </div>
            
            <div className="h-px bg-[#e8e0f0] dark:bg-[#3a3043]"></div>
            
            <div className="flex items-center gap-3">
              <Phone className="w-5 h-5 text-[#cbbec9] dark:text-[#75657d] stroke-[1.5]" />
              <a href={`tel:${provider.phone}`} className="text-[#663399] dark:text-[#d4a574] text-sm font-[450] hover:underline">{provider.phone}</a>
            </div>
            
            <div className="h-px bg-[#e8e0f0] dark:bg-[#3a3043]"></div>
            
            <div className="flex items-center gap-3">
              <Clock className="w-5 h-5 text-[#cbbec9] dark:text-[#75657d] stroke-[1.5]" />
              <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light">{provider.hours}</p>
            </div>
          </div>

          <button className="w-full mt-6 py-3.5 px-6 rounded-[18px] bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] dark:from-[#3a3043] dark:via-[#4a3e5d] dark:to-[#5a4971] text-[#f5f0f7] text-sm font-[450] shadow-[0_8px_24px_rgba(102,51,153,0.2),_inset_0_1px_0_rgba(255,255,255,0.1)] hover:shadow-[0_12px_32px_rgba(102,51,153,0.25)] hover:translate-y-[-1px] transition-all duration-300 tracking-[-0.005em]">
            Schedule appointment
          </button>
        </div>

        {/* About */}
        <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-7 mb-6 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
          <h2 className="text-[#663399] dark:text-[#cbbec9] text-[11px] uppercase tracking-[0.08em] mb-4 font-medium">About</h2>
          <p className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-light leading-relaxed">{provider.bio}</p>
        </div>

        {/* Specialties */}
        <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-7 mb-6 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
          <h2 className="text-[#663399] dark:text-[#cbbec9] text-[11px] uppercase tracking-[0.08em] mb-4 font-medium">Specialties</h2>
          <div className="flex flex-wrap gap-2">
            {provider.specialties.map((specialty, index) => (
              <span
                key={index}
                className="px-4 py-2 rounded-full bg-[#e8e0f0] dark:bg-[#3a3043] text-[#75657d] dark:text-[#cbbec9] text-sm font-light"
              >
                {specialty}
              </span>
            ))}
          </div>
        </div>

        {/* Insurance */}
        <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-7 mb-6 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
          <h2 className="text-[#663399] dark:text-[#cbbec9] text-[11px] uppercase tracking-[0.08em] mb-4 font-medium">Insurance accepted</h2>
          <div className="flex flex-wrap gap-2">
            {provider.insurance.map((ins, index) => (
              <span
                key={index}
                className="px-4 py-2 rounded-full bg-[#e8f5f0] dark:bg-[#2a3f38] text-[#5a9d7d] dark:text-[#89c5a6] text-sm font-light"
              >
                {ins}
              </span>
            ))}
          </div>
        </div>

        {/* Reviews */}
        <ProviderReviewBoundary>
          <div className="mb-6">
            <h2 className="text-[#663399] dark:text-[#cbbec9] text-[11px] uppercase tracking-[0.08em] mb-4 font-medium">Community reviews</h2>
            <div className="space-y-4">
              {reviews.map((review, index) => (
                <div
                  key={index}
                  className="relative bg-white dark:bg-[#2a2435] rounded-[20px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_32px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500"
                >
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-sm">
                        <span className="text-[#663399] dark:text-[#9d7ab8] text-xs font-[450]">{review.author.charAt(0)}</span>
                      </div>
                      <div>
                        <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">{review.author}</p>
                        <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light">{review.date}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-1">
                      {[...Array(review.rating)].map((_, i) => (
                        <Star key={i} className="w-3.5 h-3.5 text-[#d4a574] fill-[#d4a574] stroke-[1.5]" />
                      ))}
                    </div>
                  </div>
                  
                  <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed mb-3">{review.text}</p>
                  
                  <div className="flex items-center gap-2 text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light">
                    <ThumbsUp className="w-3.5 h-3.5 stroke-[1.5]" />
                    <span>{review.helpful} found this helpful</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </ProviderReviewBoundary>
      </div>
    </div>
  );
}