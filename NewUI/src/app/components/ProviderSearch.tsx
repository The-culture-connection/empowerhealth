import { Search, MapPin, Star, Award, Filter, Shield, Heart, Phone, Clock, Quote, ThumbsUp } from "lucide-react";
import { useState } from "react";
import { ProviderReviewBoundary } from "./PrivacyComponents";
import { Link } from "react-router";

export function ProviderSearch() {
  const [activeTab, setActiveTab] = useState<"all" | "obgyn" | "midwife" | "doula" | "mentalhealth">("all");
  const [filters, setFilters] = useState({
    location: "",
    insurance: "",
    raceConcordance: false,
  });

  const providers = [
    {
      name: "Dr. Aisha Williams",
      specialty: "OB-GYN",
      practice: "Equity Maternal Health",
      location: "Columbus, OH",
      distance: "4.1 miles",
      rating: 4.9,
      reviews: 189,
      acceptingNew: true,
      languages: ["English"],
      specialties: ["Cultural sensitivity", "Birth trauma", "VBAC support"],
      hasBlackMamaTag: true,
      raceMatch: true,
      phone: "(614) 555-0142",
      hours: "Mon-Fri 8am-6pm",
      priceRange: "$$",
      recentReviews: [
        {
          author: "Jasmine M.",
          rating: 5,
          date: "2 weeks ago",
          text: "Dr. Williams took the time to listen to all my concerns and made me feel truly heard. She respected my birth plan and was so supportive throughout my pregnancy.",
          helpful: 45,
        },
      ],
    },
    {
      name: "Ohio Midwifery Collective",
      specialty: "Certified Nurse Midwife",
      practice: "Columbus Birth Center",
      location: "Columbus, OH",
      distance: "2.8 miles",
      rating: 5.0,
      reviews: 156,
      acceptingNew: true,
      languages: ["English", "Spanish"],
      specialties: ["Home birth", "Water birth", "Gentle cesarean"],
      hasBlackMamaTag: true,
      raceMatch: false,
      phone: "(614) 555-0198",
      hours: "24/7 On-call",
      priceRange: "$$$",
      recentReviews: [
        {
          author: "Maria S.",
          rating: 5,
          date: "3 days ago",
          text: "The entire team made my home birth experience magical. They were calm, encouraging, and respected every one of my wishes.",
          helpful: 52,
        },
      ],
    },
    {
      name: "Destiny Williams, CD(DONA)",
      specialty: "Birth Doula",
      practice: "Sacred Journey Doula Services",
      location: "Columbus, OH",
      distance: "3.2 miles",
      rating: 5.0,
      reviews: 127,
      acceptingNew: true,
      languages: ["English"],
      specialties: ["VBAC support", "Cultural sensitivity", "Postpartum care"],
      hasBlackMamaTag: true,
      raceMatch: true,
      phone: "(614) 555-0203",
      hours: "By appointment",
      priceRange: "$$",
      recentReviews: [
        {
          author: "Amara T.",
          rating: 5,
          date: "5 days ago",
          text: "Destiny was my rock during labor. She knew exactly what I needed before I even asked. Her presence was calming and empowering.",
          helpful: 67,
        },
      ],
    },
  ];

  const categories = [
    { id: "all", label: "All providers", count: 3 },
    { id: "obgyn", label: "OB-GYNs", count: 1 },
    { id: "midwife", label: "Midwives", count: 1 },
    { id: "doula", label: "Doulas", count: 1 },
  ];

  return (
    <div className="pb-5">
      {/* Hero Header */}
      <div className="bg-gradient-to-br from-[#ebe4f3] via-[#e0d5eb] to-[#e8dfe8] px-6 pt-6 pb-8 mb-6 relative overflow-hidden">
        {/* Subtle background pattern */}
        <div className="absolute inset-0 opacity-5">
          <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-white blur-3xl"></div>
          <div className="absolute bottom-0 left-0 w-40 h-40 rounded-full bg-[#d4c5e0] blur-3xl"></div>
        </div>

        <div className="relative mb-6">
          <h1 className="text-2xl text-[#4a3f52] mb-2 font-normal">Find your care team</h1>
          <p className="text-[#6b5c75] text-sm font-light">Trusted providers reviewed by mothers like you</p>
        </div>

        {/* Search Bar */}
        <Link to="/providers/search" className="block relative">
          <div className="relative">
            <Search className="absolute left-5 top-1/2 transform -translate-y-1/2 text-[#a89cb5] w-5 h-5 pointer-events-none stroke-[1.5]" />
            <div className="w-full pl-14 pr-5 py-4 rounded-[24px] bg-white/80 backdrop-blur-sm border-0 shadow-[0_2px_16px_rgba(0,0,0,0.06)] text-[#a89cb5] font-light">
              Search providers, specialties, or location
            </div>
          </div>
        </Link>
      </div>

      <div className="px-6">
        {/* Category Pills */}
        <section className="mb-6">
          <div className="flex gap-2 overflow-x-auto pb-2 -mx-6 px-6">
            {categories.map((category) => (
              <button
                key={category.id}
                onClick={() => setActiveTab(category.id as any)}
                className={`px-5 py-2.5 rounded-[20px] whitespace-nowrap transition-all shadow-[0_2px_12px_rgba(0,0,0,0.03)] font-light ${
                  activeTab === category.id
                    ? "bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] text-white"
                    : "bg-white/80 backdrop-blur-sm text-[#6b5c75] border border-[#e8e0f0]/50 hover:border-[#d4c5e0]/50"
                }`}
              >
                {category.label} <span className="text-xs opacity-75">({category.count})</span>
              </button>
            ))}
          </div>
        </section>

        {/* Review Boundary Notice */}
        <ProviderReviewBoundary />

        {/* Quick Filters */}
        <section className="mb-6">
          <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
            <div className="flex items-center gap-2 mb-4">
              <Filter className="w-4 h-4 text-[#a89cb5] stroke-[1.5]" />
              <span className="text-sm text-[#6b5c75] font-normal">Filters</span>
            </div>
            <div className="flex flex-wrap gap-2">
              <button className="px-4 py-2 rounded-[16px] text-xs bg-[#e8e0f0]/60 text-[#8b7a95] border border-[#d4c5e0]/30 font-light">
                <MapPin className="w-3 h-3 inline mr-1.5 stroke-[1.5]" />
                Near me
              </button>
              <button className="px-4 py-2 rounded-[16px] text-xs bg-[#dce8e4]/60 text-[#6b9688] border border-[#c9e0d9]/30 font-light">
                ✓ Accepting patients
              </button>
              <button
                onClick={() => setFilters({ ...filters, raceConcordance: !filters.raceConcordance })}
                className={`px-4 py-2 rounded-[16px] text-xs border transition-colors font-light ${
                  filters.raceConcordance
                    ? "bg-[#e8e0f0]/80 text-[#8b7a95] border-[#d4c5e0]/50"
                    : "bg-[#f7f5f9] text-[#a89cb5] border-[#e8e0f0]/50"
                }`}
              >
                <Heart className="w-3 h-3 inline mr-1.5 stroke-[1.5]" />
                Background match
              </button>
              <button className="px-4 py-2 rounded-[16px] text-xs bg-[#f0e0e8]/60 text-[#c9a9c0] border border-[#e8d0e0]/30 font-light">
                <Award className="w-3 h-3 inline mr-1.5 stroke-[1.5]" />
                Mama Approved™
              </button>
            </div>
          </div>
        </section>

        {/* Provider Cards */}
        <section>
          <div className="flex items-center justify-between mb-5">
            <p className="text-sm text-[#8b7a95] font-light">{providers.length} providers near you</p>
            <select className="text-xs px-4 py-2 rounded-[16px] bg-white/80 backdrop-blur-sm border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#6b5c75] font-light">
              <option>Highest rated</option>
              <option>Most reviewed</option>
              <option>Nearest</option>
            </select>
          </div>

          <div className="space-y-5">
            {providers.map((provider, index) => (
              <div
                key={index}
                className="bg-white/60 backdrop-blur-sm rounded-[32px] shadow-[0_4px_24px_rgba(0,0,0,0.06)] border border-[#ede7f3]/50 overflow-hidden hover:shadow-[0_6px_32px_rgba(0,0,0,0.08)] transition-all"
              >
                {/* Provider Image/Header */}
                <div className="relative h-36 bg-gradient-to-br from-[#ebe4f3] to-[#e8dfe8] flex items-center justify-center">
                  <div className="w-20 h-20 rounded-full bg-gradient-to-br from-[#d4c5e0] to-[#e0d5eb] flex items-center justify-center text-white text-2xl shadow-[0_4px_16px_rgba(168,156,181,0.2)]">
                    {provider.name.charAt(0)}
                  </div>
                  {provider.raceMatch && filters.raceConcordance && (
                    <div className="absolute top-4 right-4 px-3 py-2 rounded-[16px] bg-[#e8e0f0]/90 backdrop-blur-sm text-[#6b5c75] text-xs font-light shadow-sm flex items-center gap-1.5">
                      <Heart className="w-3.5 h-3.5 fill-[#a89cb5] stroke-[1.5]" />
                      Match
                    </div>
                  )}
                </div>

                <div className="p-6">
                  {/* Name and Tags */}
                  <div className="mb-4">
                    <div className="flex items-start justify-between mb-2">
                      <div>
                        <h3 className="text-lg mb-1 text-[#4a3f52] font-normal">{provider.name}</h3>
                        <p className="text-sm text-[#8b7a95] font-light">{provider.specialty} • {provider.practice}</p>
                      </div>
                      {provider.acceptingNew && (
                        <span className="text-xs px-3 py-1.5 rounded-[14px] bg-[#dce8e4]/80 text-[#6b9688] border border-[#c9e0d9]/30 whitespace-nowrap font-light">
                          ✓ Accepting
                        </span>
                      )}
                    </div>

                    {provider.hasBlackMamaTag && (
                      <div className="inline-flex items-center gap-2 px-4 py-2 rounded-[16px] bg-gradient-to-r from-[#f0e0e8] to-[#f5e8f0] border border-[#e8d0e0]/50">
                        <Award className="w-4 h-4 text-[#c9a9c0] stroke-[1.5]" />
                        <span className="text-xs text-[#c9a9c0] font-light">Mama Approved™</span>
                      </div>
                    )}
                  </div>

                  {/* Rating */}
                  <div className="flex items-center gap-2 mb-5">
                    <div className="flex items-center gap-1.5">
                      <Star className="w-5 h-5 fill-[#c9b087] text-[#c9b087]" />
                      <span className="text-lg font-normal text-[#4a3f52]">{provider.rating}</span>
                    </div>
                    <span className="text-sm text-[#a89cb5] font-light">({provider.reviews} reviews)</span>
                    <span className="text-[#e8e0f0]">•</span>
                    <span className="text-sm text-[#a89cb5] font-light">{provider.priceRange}</span>
                  </div>

                  {/* Quick Info */}
                  <div className="grid grid-cols-2 gap-3 mb-5 p-4 bg-[#f7f5f9] rounded-[20px]">
                    <div className="flex items-center gap-2 text-xs text-[#8b7a95] font-light">
                      <MapPin className="w-4 h-4 text-[#a89cb5] stroke-[1.5]" />
                      <span>{provider.distance}</span>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-[#8b7a95] font-light">
                      <Phone className="w-4 h-4 text-[#a89cb5] stroke-[1.5]" />
                      <span>{provider.phone.slice(-8)}</span>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-[#8b7a95] col-span-2 font-light">
                      <Clock className="w-4 h-4 text-[#a89cb5] stroke-[1.5]" />
                      <span>{provider.hours}</span>
                    </div>
                  </div>

                  {/* Specialties */}
                  <div className="mb-5">
                    <div className="flex flex-wrap gap-2">
                      {provider.specialties.map((specialty, i) => (
                        <span key={i} className="text-xs px-3 py-1.5 rounded-[14px] bg-[#e8e0f0]/60 text-[#8b7a95] border border-[#d4c5e0]/20 font-light">
                          {specialty}
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* Featured Review */}
                  {provider.recentReviews && provider.recentReviews[0] && (
                    <div className="bg-gradient-to-br from-[#faf7fb] to-[#f9f5fb] rounded-[24px] p-5 mb-5 border border-[#f0e8f3]/50">
                      <div className="flex items-center gap-2 mb-3">
                        <Quote className="w-4 h-4 text-[#c9a9c0] stroke-[1.5]" />
                        <span className="text-xs text-[#a89cb5] font-light">Recent review</span>
                      </div>
                      <div className="flex gap-0.5 mb-3">
                        {[...Array(5)].map((_, i) => (
                          <Star
                            key={i}
                            className={`w-3.5 h-3.5 ${
                              i < provider.recentReviews[0].rating
                                ? "fill-[#c9b087] text-[#c9b087]"
                                : "text-[#e8e0f0]"
                            }`}
                          />
                        ))}
                      </div>
                      <p className="text-sm text-[#6b5c75] mb-3 line-clamp-3 font-light leading-relaxed">"{provider.recentReviews[0].text}"</p>
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-[#a89cb5] font-light">— {provider.recentReviews[0].author}</span>
                        <div className="flex items-center gap-1.5 text-[#a89cb5] font-light">
                          <ThumbsUp className="w-3 h-3 stroke-[1.5]" />
                          <span>{provider.recentReviews[0].helpful}</span>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Action Buttons */}
                  <div className="flex gap-3">
                    <button className="flex-1 py-3.5 px-4 rounded-[24px] bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] text-white text-sm hover:shadow-[0_4px_20px_rgba(168,156,181,0.25)] transition-all font-light shadow-[0_2px_12px_rgba(168,156,181,0.15)]">
                      View full profile
                    </button>
                    <button className="px-5 py-3.5 rounded-[24px] border border-[#e8e0f0]/50 text-[#8b7a95] text-sm hover:bg-[#f7f5f9] transition-colors font-light">
                      <Phone className="w-4 h-4 stroke-[1.5]" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Community Trust Badge */}
        <div className="mt-8 bg-gradient-to-br from-[#f0ead8] to-[#f5f0e8] rounded-[28px] p-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#e8dfc8]/50">
          <div className="flex items-start gap-3">
            <div className="w-11 h-11 rounded-[20px] bg-white/60 backdrop-blur-sm flex items-center justify-center flex-shrink-0 shadow-sm">
              <Shield className="w-5 h-5 text-[#c9b087] stroke-[1.5]" />
            </div>
            <div>
              <h3 className="mb-2 text-[#4a3f52] font-normal">Verified reviews</h3>
              <p className="text-sm text-[#6b5c75] mb-3 font-light leading-relaxed">
                All reviews come from verified patients. Share your experience anonymously to help other mothers make informed choices.
              </p>
              <button className="text-sm text-[#a89cb5] font-light hover:text-[#8b7a95] transition-colors">Write a review →</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
