import { Search, MapPin, Star, Award, Filter, Shield, Heart, Phone, Clock, DollarSign, ThumbsUp, Quote, ImageIcon } from "lucide-react";
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
      location: "Berkeley, CA",
      distance: "4.1 miles",
      rating: 4.9,
      reviews: 189,
      acceptingNew: true,
      languages: ["English"],
      specialties: ["Cultural sensitivity", "Birth trauma", "VBAC support"],
      hasBlackMamaTag: true,
      raceMatch: true,
      phone: "(510) 555-0142",
      hours: "Mon-Fri 8am-6pm",
      priceRange: "$$",
      image: "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400",
      recentReviews: [
        {
          author: "Jasmine M.",
          rating: 5,
          date: "2 weeks ago",
          text: "Dr. Williams took the time to listen to all my concerns and made me feel truly heard. She respected my birth plan and was so supportive throughout my pregnancy.",
          helpful: 45,
        },
        {
          author: "Keisha R.",
          rating: 5,
          date: "1 month ago",
          text: "Finally found a provider who understands the unique challenges Black mothers face. She's knowledgeable, compassionate, and advocates fiercely for her patients.",
          helpful: 38,
        },
      ],
    },
    {
      name: "Oakland Midwifery Collective",
      specialty: "Certified Nurse Midwife",
      practice: "Oakland Birth Center",
      location: "Oakland, CA",
      distance: "2.8 miles",
      rating: 5.0,
      reviews: 156,
      acceptingNew: true,
      languages: ["English", "Spanish", "Mandarin"],
      specialties: ["Home birth", "Water birth", "Gentle cesarean"],
      hasBlackMamaTag: true,
      raceMatch: false,
      phone: "(510) 555-0198",
      hours: "24/7 On-call",
      priceRange: "$$$",
      image: "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=400",
      recentReviews: [
        {
          author: "Maria S.",
          rating: 5,
          date: "3 days ago",
          text: "The entire team made my home birth experience magical. They were calm, encouraging, and respected every one of my wishes. I felt so empowered.",
          helpful: 52,
        },
        {
          author: "Destiny L.",
          rating: 5,
          date: "1 week ago",
          text: "These midwives are phenomenal. They treated me like family and gave me the most beautiful, peaceful birth experience I could have hoped for.",
          helpful: 41,
        },
      ],
    },
    {
      name: "Dr. Maria Johnson",
      specialty: "OB-GYN",
      practice: "Valley Health Center",
      location: "Oakland, CA",
      distance: "2.3 miles",
      rating: 4.8,
      reviews: 234,
      acceptingNew: true,
      languages: ["English", "Spanish"],
      specialties: ["High-risk pregnancy", "VBAC", "Diabetes management"],
      hasBlackMamaTag: false,
      raceMatch: false,
      phone: "(510) 555-0176",
      hours: "Mon-Fri 9am-5pm",
      priceRange: "$$",
      image: "https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=400",
      recentReviews: [
        {
          author: "Sarah P.",
          rating: 5,
          date: "4 days ago",
          text: "Dr. Johnson is incredibly thorough and patient. She explains everything in a way that's easy to understand and never makes you feel rushed.",
          helpful: 29,
        },
        {
          author: "Anonymous",
          rating: 4,
          date: "2 weeks ago",
          text: "Great doctor, very knowledgeable about high-risk pregnancies. The office staff could be more organized, but Dr. Johnson herself is wonderful.",
          helpful: 18,
        },
      ],
    },
    {
      name: "Destiny Williams, CD(DONA)",
      specialty: "Birth Doula",
      practice: "Sacred Journey Doula Services",
      location: "Oakland, CA",
      distance: "3.2 miles",
      rating: 5.0,
      reviews: 127,
      acceptingNew: true,
      languages: ["English"],
      specialties: ["VBAC support", "Cultural sensitivity", "Postpartum care"],
      hasBlackMamaTag: true,
      raceMatch: true,
      phone: "(510) 555-0203",
      hours: "By appointment",
      priceRange: "$$",
      image: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400",
      recentReviews: [
        {
          author: "Amara T.",
          rating: 5,
          date: "5 days ago",
          text: "Destiny was my rock during labor. She knew exactly what I needed before I even asked. Her presence was calming and empowering. Couldn't have done it without her!",
          helpful: 67,
        },
        {
          author: "Nicole B.",
          rating: 5,
          date: "3 weeks ago",
          text: "She advocates for you when you need it most. Destiny helped me have the birth I wanted and supported me postpartum too. Worth every penny!",
          helpful: 54,
        },
      ],
    },
  ];

  const categories = [
    { id: "all", label: "All Providers", count: 4 },
    { id: "obgyn", label: "OB-GYNs", count: 2 },
    { id: "midwife", label: "Midwives", count: 1 },
    { id: "doula", label: "Doulas", count: 1 },
  ];

  return (
    <div className="pb-5">
      {/* Hero Header */}
      <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] px-5 pt-5 pb-8 mb-4">
        <div className="mb-6">
          <h1 className="text-2xl text-white mb-2">Find Your Care Team</h1>
          <p className="text-white/90 text-sm">Trusted providers reviewed by mothers like you</p>
        </div>

        {/* Search Bar */}
        <Link to="/providers/search" className="block">
          <div className="relative">
            <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5 pointer-events-none" />
            <div className="w-full pl-12 pr-4 py-3.5 rounded-2xl bg-white border-0 shadow-lg text-gray-500">
              Search providers, specialties, or location
            </div>
          </div>
        </Link>
      </div>

      <div className="px-5">
        {/* Category Pills */}
        <section className="mb-5">
          <div className="flex gap-2 overflow-x-auto pb-2 -mx-5 px-5">
            {categories.map((category) => (
              <button
                key={category.id}
                onClick={() => setActiveTab(category.id as any)}
                className={`px-4 py-2 rounded-full whitespace-nowrap transition-all shadow-sm ${
                  activeTab === category.id
                    ? "bg-[#663399] text-white"
                    : "bg-white text-gray-700 border border-gray-200 hover:border-[#663399]/30"
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
        <section className="mb-5">
          <div className="bg-white rounded-3xl p-4 shadow-sm border border-gray-100">
            <div className="flex items-center gap-2 mb-3">
              <Filter className="w-4 h-4 text-[#663399]" />
              <span className="text-sm">Filters</span>
            </div>
            <div className="flex flex-wrap gap-2">
              <button className="px-3 py-1.5 rounded-full text-xs bg-purple-50 text-[#663399] border border-[#663399]/20">
                <MapPin className="w-3 h-3 inline mr-1" />
                Near me
              </button>
              <button className="px-3 py-1.5 rounded-full text-xs bg-green-50 text-green-700 border border-green-200">
                ✓ Accepting patients
              </button>
              <button
                onClick={() => setFilters({ ...filters, raceConcordance: !filters.raceConcordance })}
                className={`px-3 py-1.5 rounded-full text-xs border transition-colors ${
                  filters.raceConcordance
                    ? "bg-blue-50 text-blue-700 border-blue-200"
                    : "bg-gray-50 text-gray-600 border-gray-200"
                }`}
              >
                <Heart className="w-3 h-3 inline mr-1" />
                Background match
              </button>
              <button className="px-3 py-1.5 rounded-full text-xs bg-rose-50 text-rose-700 border border-rose-200">
                <Award className="w-3 h-3 inline mr-1" />
                Black Mama Approved
              </button>
            </div>
          </div>
        </section>

        {/* Provider Cards */}
        <section>
          <div className="flex items-center justify-between mb-4">
            <p className="text-sm text-gray-600">{providers.length} providers near you</p>
            <select className="text-xs px-3 py-1.5 rounded-xl bg-white border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20">
              <option>Highest rated</option>
              <option>Most reviewed</option>
              <option>Nearest</option>
            </select>
          </div>

          <div className="space-y-5">
            {providers.map((provider, index) => (
              <div
                key={index}
                className="bg-white rounded-3xl shadow-md border border-gray-100 overflow-hidden hover:shadow-lg transition-shadow"
              >
                {/* Provider Image/Header */}
                <div className="relative h-32 bg-gradient-to-br from-[#663399]/10 to-[#cbbec9]/10 flex items-center justify-center">
                  <div className="w-20 h-20 rounded-full bg-gradient-to-br from-[#663399] to-[#cbbec9] flex items-center justify-center text-white text-2xl shadow-lg">
                    {provider.name.charAt(0)}
                  </div>
                  {provider.raceMatch && filters.raceConcordance && (
                    <div className="absolute top-3 right-3 px-2.5 py-1.5 rounded-xl bg-blue-500 text-white text-xs font-medium shadow-lg flex items-center gap-1">
                      <Heart className="w-3.5 h-3.5" fill="white" />
                      Match
                    </div>
                  )}
                </div>

                <div className="p-5">
                  {/* Name and Tags */}
                  <div className="mb-3">
                    <div className="flex items-start justify-between mb-2">
                      <div>
                        <h3 className="text-lg mb-0.5">{provider.name}</h3>
                        <p className="text-sm text-gray-600">{provider.specialty} • {provider.practice}</p>
                      </div>
                      {provider.acceptingNew && (
                        <span className="text-xs px-2.5 py-1 rounded-full bg-green-100 text-green-700 border border-green-200 whitespace-nowrap">
                          ✓ Accepting
                        </span>
                      )}
                    </div>

                    {provider.hasBlackMamaTag && (
                      <div className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-gradient-to-r from-rose-50 to-pink-50 border border-rose-200">
                        <Award className="w-4 h-4 text-rose-600" />
                        <span className="text-xs text-rose-700 font-medium">Black Mama Approved</span>
                      </div>
                    )}
                  </div>

                  {/* Rating */}
                  <div className="flex items-center gap-2 mb-4">
                    <div className="flex items-center gap-1">
                      <Star className="w-5 h-5 fill-amber-400 text-amber-400" />
                      <span className="text-lg font-medium">{provider.rating}</span>
                    </div>
                    <span className="text-sm text-gray-500">({provider.reviews} reviews)</span>
                    <span className="text-gray-300">•</span>
                    <span className="text-sm text-gray-500">{provider.priceRange}</span>
                  </div>

                  {/* Quick Info */}
                  <div className="grid grid-cols-2 gap-3 mb-4 p-3 bg-gray-50 rounded-2xl">
                    <div className="flex items-center gap-2 text-xs text-gray-600">
                      <MapPin className="w-4 h-4 text-[#663399]" />
                      <span>{provider.distance}</span>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-gray-600">
                      <Phone className="w-4 h-4 text-[#663399]" />
                      <span>{provider.phone.slice(-8)}</span>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-gray-600 col-span-2">
                      <Clock className="w-4 h-4 text-[#663399]" />
                      <span>{provider.hours}</span>
                    </div>
                  </div>

                  {/* Specialties */}
                  <div className="mb-4">
                    <div className="flex flex-wrap gap-2">
                      {provider.specialties.map((specialty, i) => (
                        <span key={i} className="text-xs px-3 py-1 rounded-full bg-purple-50 text-[#663399] border border-purple-100">
                          {specialty}
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* Featured Review */}
                  {provider.recentReviews && provider.recentReviews[0] && (
                    <div className="bg-gradient-to-br from-[#fef3f3] to-[#fff0f8] rounded-2xl p-4 mb-4 border border-pink-100">
                      <div className="flex items-center gap-2 mb-2">
                        <Quote className="w-4 h-4 text-rose-400" />
                        <span className="text-xs text-gray-500">Recent review</span>
                      </div>
                      <div className="flex gap-0.5 mb-2">
                        {[...Array(5)].map((_, i) => (
                          <Star
                            key={i}
                            className={`w-3.5 h-3.5 ${
                              i < provider.recentReviews[0].rating
                                ? "fill-amber-400 text-amber-400"
                                : "text-gray-300"
                            }`}
                          />
                        ))}
                      </div>
                      <p className="text-sm text-gray-700 mb-2 line-clamp-3">"{provider.recentReviews[0].text}"</p>
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-gray-500">— {provider.recentReviews[0].author}</span>
                        <div className="flex items-center gap-1 text-gray-500">
                          <ThumbsUp className="w-3 h-3" />
                          <span>{provider.recentReviews[0].helpful}</span>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Action Buttons */}
                  <div className="flex gap-2">
                    <button className="flex-1 py-3 px-4 rounded-2xl bg-[#663399] text-white text-sm hover:bg-[#552288] transition-colors shadow-sm">
                      View Full Profile
                    </button>
                    <button className="px-4 py-3 rounded-2xl border border-gray-200 text-gray-700 text-sm hover:border-[#663399]/30 transition-colors">
                      <Phone className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Community Trust Badge */}
        <div className="mt-6 bg-gradient-to-br from-blue-50 to-purple-50 rounded-3xl p-5 shadow-sm border border-blue-100">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-2xl bg-blue-100 flex items-center justify-center flex-shrink-0">
              <Shield className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <h3 className="mb-1">Verified Reviews</h3>
              <p className="text-sm text-gray-600 mb-3">
                All reviews come from verified patients. Share your experience anonymously to help other mothers make informed choices.
              </p>
              <button className="text-sm text-[#663399] font-medium">Write a review →</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}