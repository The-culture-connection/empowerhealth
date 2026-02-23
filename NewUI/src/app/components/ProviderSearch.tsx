import { Search, MapPin, Star, Award, Filter, Shield, Heart, Phone, Clock, Quote, ThumbsUp, ChevronRight } from "lucide-react";
import { useState } from "react";
import { ProviderReviewBoundary } from "./PrivacyComponents";
import { Link } from "react-router";

export function ProviderSearch() {
  const [activeTab, setActiveTab] = useState<"all" | "obgyn" | "midwife" | "doula" | "mentalhealth">("all");

  const providers = [
    {
      id: "1",
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
    },
    {
      id: "2",
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
    },
    {
      id: "3",
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
    },
  ];

  const categories = [
    { id: "all", label: "All", count: 3 },
    { id: "obgyn", label: "OB-GYNs", count: 1 },
    { id: "midwife", label: "Midwives", count: 1 },
    { id: "doula", label: "Doulas", count: 1 },
  ];

  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] relative overflow-hidden transition-colors duration-500">
      {/* Warm ambient light */}
      <div className="fixed inset-0 opacity-40 dark:opacity-30 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[140px]"></div>
      </div>

      <div className="relative p-6 pb-24 max-w-2xl mx-auto">
        {/* Header */}
        <div className="mb-8 mt-4">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-4 shadow-sm">
            <div className="w-1.5 h-1.5 rounded-full bg-[#d4a574]"></div>
            <span className="text-[#75657d] dark:text-[#cbbec9] text-xs tracking-[0.03em] font-light">Ohio providers</span>
          </div>
          <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-2 tracking-[-0.01em]">Find your care team</h1>
          <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light">Trusted providers who listen and support you</p>
        </div>

        {/* Search Bar - Like a framed input */}
        <div className="mb-6">
          <div className="relative">
            <Search className="absolute left-5 top-1/2 transform -translate-y-1/2 text-[#cbbec9] dark:text-[#75657d] w-5 h-5 stroke-[1.5]" />
            <input
              type="text"
              placeholder="Search by name, location, or specialty..."
              className="w-full pl-14 pr-5 py-4 rounded-[20px] bg-white dark:bg-[#2a2435] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 focus:outline-none focus:ring-2 focus:ring-[#d4a574]/30 text-[#2d2235] dark:text-[#f5f0f7] placeholder:text-[#cbbec9] dark:placeholder:text-[#75657d] text-sm font-light shadow-[0_8px_32px_rgba(102,51,153,0.1)] dark:shadow-[0_8px_32px_rgba(0,0,0,0.3)] transition-all duration-300"
            />
          </div>
        </div>

        {/* Categories - Like fabric swatches */}
        <div className="mb-8">
          <div className="flex gap-2 overflow-x-auto pb-2">
            {categories.map((category) => (
              <button
                key={category.id}
                onClick={() => setActiveTab(category.id as any)}
                className={`px-5 py-2.5 rounded-[18px] whitespace-nowrap transition-all duration-300 font-light shadow-sm ${
                  activeTab === category.id
                    ? "bg-gradient-to-br from-[#663399] to-[#7744aa] dark:from-[#3a3043] dark:to-[#4a3e5d] text-[#f5f0f7] shadow-[0_8px_24px_rgba(102,51,153,0.2)]"
                    : "bg-white dark:bg-[#2a2435] text-[#75657d] dark:text-[#cbbec9] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 hover:border-[#d4a574]/30"
                }`}
              >
                <span className="text-sm tracking-[-0.005em]">{category.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Trust Indicator */}
        <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[20px] p-6 mb-8 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 overflow-hidden transition-all duration-500">
          {/* Subtle glow */}
          <div className="absolute inset-0 opacity-[0.03] pointer-events-none">
            <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-[#d4a574] blur-[60px]"></div>
          </div>
          
          <div className="relative flex items-start gap-3">
            <div className="w-10 h-10 rounded-[14px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_6px_rgba(0,0,0,0.06)]">
              <Award className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
            </div>
            <div>
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-1 tracking-[-0.005em]">Mama Approved™ providers</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-xs font-light leading-relaxed">
                Verified by community trust indicators and identity transparency
              </p>
            </div>
          </div>
        </div>

        {/* Provider Cards - Like upholstered panels */}
        <div className="space-y-4">
          {providers.map((provider) => (
            <Link key={provider.id} to={`/providers/${provider.id}`}>
              <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-6 shadow-[0_12px_40px_rgba(102,51,153,0.12),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_12px_48px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_16px_56px_rgba(102,51,153,0.16)] dark:hover:shadow-[0_16px_64px_rgba(0,0,0,0.5)] hover:translate-y-[-2px] cursor-pointer">
                {/* Header */}
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[17px] font-[450] tracking-[-0.005em]">{provider.name}</h3>
                      {provider.hasBlackMamaTag && (
                        <div className="px-2.5 py-1 rounded-full bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center gap-1.5 shadow-sm">
                          <Award className="w-3.5 h-3.5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
                        </div>
                      )}
                    </div>
                    <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light mb-1">{provider.specialty}</p>
                    <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light">{provider.practice}</p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#cbbec9] dark:text-[#75657d] stroke-[1.5] flex-shrink-0" />
                </div>

                {/* Rating & Location */}
                <div className="flex items-center gap-4 mb-4">
                  <div className="flex items-center gap-1.5">
                    <Star className="w-4 h-4 text-[#d4a574] fill-[#d4a574] stroke-[1.5]" />
                    <span className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450]">{provider.rating}</span>
                    <span className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light">({provider.reviews})</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <MapPin className="w-4 h-4 text-[#cbbec9] dark:text-[#75657d] stroke-[1.5]" />
                    <span className="text-[#75657d] dark:text-[#cbbec9] text-xs font-light">{provider.distance}</span>
                  </div>
                  {provider.acceptingNew && (
                    <div className="px-3 py-1 rounded-full bg-[#e8f5f0]/60 dark:bg-[#2a3f38] text-[#5a9d7d] dark:text-[#89c5a6] text-xs font-light">
                      Accepting new patients
                    </div>
                  )}
                </div>

                {/* Specialties - Like fabric tags */}
                <div className="flex flex-wrap gap-2">
                  {provider.specialties.slice(0, 3).map((specialty, index) => (
                    <span
                      key={index}
                      className="px-3 py-1.5 rounded-full bg-[#e8e0f0] dark:bg-[#3a3043] text-[#75657d] dark:text-[#cbbec9] text-xs font-light"
                    >
                      {specialty}
                    </span>
                  ))}
                </div>
              </div>
            </Link>
          ))}
        </div>

        {/* Trust Notice */}
        <ProviderReviewBoundary>
          <div className="mt-8 text-center">
            <p className="text-[#9b8ba5] dark:text-[#9b8ba5] text-xs font-light leading-relaxed">
              All providers shown maintain community trust indicators and transparency standards
            </p>
          </div>
        </ProviderReviewBoundary>
      </div>
    </div>
  );
}