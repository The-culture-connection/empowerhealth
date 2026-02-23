import { ArrowLeft, MapPin, Star, Heart, Phone, Clock, Award, Shield, Info, Bookmark, ChevronRight } from "lucide-react";
import { Link } from "react-router";
import { useState, useEffect } from "react";
import { ProviderSearchLoading } from "./ProviderSearchLoading";

export function ProviderSearchResults() {
  const [savedProviders, setSavedProviders] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Loading component will handle its own timing
  }, []);

  const toggleSave = (id: string) => {
    if (savedProviders.includes(id)) {
      setSavedProviders(savedProviders.filter(p => p !== id));
    } else {
      setSavedProviders([...savedProviders, id]);
    }
  };

  const providers = [
    {
      id: "1",
      name: "Dr. Aisha Williams",
      credentials: "MD, OB-GYN",
      specialty: "Maternal-Fetal Medicine",
      practice: "Cleveland Clinic Women's Health",
      address: "9500 Euclid Ave, Cleveland, OH 44195",
      distance: "4.2 miles",
      city: "Cleveland",
      mamaApproved: true,
      rating: 4.9,
      reviewCount: 127,
      acceptingNew: true,
      telehealth: true,
      identityTags: [
        { label: "Black / African American", status: "verified" },
        { label: "Cultural competency certified", status: "verified" },
        { label: "LGBTQ+ affirming", status: "pending" }
      ],
      phone: "(216) 444-6601"
    },
    {
      id: "2",
      name: "Ohio Midwifery Collective",
      credentials: "CNM Group Practice",
      specialty: "Certified Nurse Midwives",
      practice: "Ohio Midwifery Collective",
      address: "2800 Euclid Ave, Cleveland, OH 44115",
      distance: "5.1 miles",
      city: "Cleveland",
      mamaApproved: true,
      rating: 5.0,
      reviewCount: 89,
      acceptingNew: true,
      telehealth: false,
      identityTags: [
        { label: "Spanish-speaking", status: "verified" },
        { label: "Home birth support", status: "verified" }
      ],
      phone: "(216) 555-0142"
    },
    {
      id: "3",
      name: "Dr. Sarah Mitchell",
      credentials: "DO, Family Medicine",
      specialty: "Family Medicine, Prenatal Care",
      practice: "MetroHealth Family Health Center",
      address: "2500 MetroHealth Dr, Cleveland, OH 44109",
      distance: "6.8 miles",
      city: "Cleveland",
      mamaApproved: false,
      rating: 4.7,
      reviewCount: 56,
      acceptingNew: true,
      telehealth: true,
      identityTags: [
        { label: "Accepts Medicaid", status: "verified" }
      ],
      phone: "(216) 778-4321"
    }
  ];

  if (isLoading) {
    return <ProviderSearchLoading onComplete={() => setIsLoading(false)} />;
  }

  return (
    <div className="min-h-screen bg-[#f7f5f9] pb-24">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#ebe4f3] via-[#e0d5eb] to-[#e8dfe8] px-6 pt-6 pb-8 mb-6 relative overflow-hidden sticky top-0 z-10">
        <div className="absolute inset-0 opacity-5">
          <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-white blur-3xl"></div>
          <div className="absolute bottom-0 left-0 w-40 h-40 rounded-full bg-[#d4c5e0] blur-3xl"></div>
        </div>
        
        <div className="relative">
          <Link to="/providers/search" className="inline-flex items-center gap-2 text-[#8b7a95] hover:text-[#6b5c75] transition-colors mb-4 font-light text-sm">
            <ArrowLeft className="w-4 h-4 stroke-[1.5]" />
            Refine search
          </Link>
          <h1 className="text-2xl text-[#4a3f52] mb-2 font-normal">Search results</h1>
          <p className="text-[#6b5c75] text-sm font-light">{providers.length} providers found near you</p>
        </div>
      </div>

      <div className="px-6 max-w-2xl mx-auto">
        {/* Trust Banner */}
        <div className="mb-6 p-5 bg-gradient-to-br from-[#f0ead8] to-[#f5f0e8] rounded-[28px] border border-[#e8dfc8]/50 shadow-[0_2px_16px_rgba(0,0,0,0.04)]">
          <div className="flex items-start gap-3">
            <Shield className="w-5 h-5 text-[#c9b087] flex-shrink-0 mt-0.5 stroke-[1.5]" />
            <div>
              <p className="text-sm text-[#6b5c75] font-light leading-relaxed">
                These providers are sourced from <strong className="font-normal">Ohio Medicaid directories + NPI registry</strong>. Community trust indicators come from verified patient reviews.
              </p>
            </div>
          </div>
        </div>

        {/* Sorting */}
        <div className="flex items-center justify-between mb-6">
          <p className="text-sm text-[#8b7a95] font-light">Sorted by distance</p>
          <select className="text-xs px-4 py-2 rounded-[16px] bg-white/80 backdrop-blur-sm border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#6b5c75] font-light">
            <option>Nearest first</option>
            <option>Highest rated</option>
            <option>Most reviewed</option>
            <option>Mama Approved™</option>
          </select>
        </div>

        {/* Provider Results */}
        <div className="space-y-5">
          {providers.map((provider) => {
            const isSaved = savedProviders.includes(provider.id);
            
            return (
              <div
                key={provider.id}
                className="bg-white/60 backdrop-blur-sm rounded-[32px] shadow-[0_4px_24px_rgba(0,0,0,0.06)] border border-[#ede7f3]/50 overflow-hidden hover:shadow-[0_6px_32px_rgba(0,0,0,0.08)] transition-all"
              >
                <div className="p-6">
                  {/* Header */}
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <h3 className="text-lg text-[#4a3f52] font-normal">{provider.name}</h3>
                        {provider.mamaApproved && (
                          <Award className="w-5 h-5 text-[#c9a9c0] fill-[#f0e0e8] stroke-[1.5]" />
                        )}
                      </div>
                      <p className="text-sm text-[#8b7a95] mb-1 font-light">{provider.credentials}</p>
                      <p className="text-sm text-[#a89cb5] font-light">{provider.practice}</p>
                    </div>
                    <button
                      onClick={() => toggleSave(provider.id)}
                      className="text-[#a89cb5] hover:text-[#8b7a95] transition-colors"
                    >
                      <Bookmark className={`w-5 h-5 stroke-[1.5] ${isSaved ? 'fill-[#a89cb5]' : ''}`} />
                    </button>
                  </div>

                  {/* Mama Approved Badge */}
                  {provider.mamaApproved && (
                    <div className="inline-flex items-center gap-2 px-4 py-2 rounded-[16px] bg-gradient-to-r from-[#f0e0e8] to-[#f5e8f0] border border-[#e8d0e0]/50 mb-4">
                      <Award className="w-4 h-4 text-[#c9a9c0] stroke-[1.5]" />
                      <span className="text-xs text-[#c9a9c0] font-light">Mama Approved™</span>
                    </div>
                  )}

                  {/* Rating */}
                  <div className="flex items-center gap-3 mb-5">
                    <div className="flex items-center gap-1.5">
                      <Star className="w-5 h-5 fill-[#c9b087] text-[#c9b087]" />
                      <span className="text-lg font-normal text-[#4a3f52]">{provider.rating}</span>
                    </div>
                    <span className="text-sm text-[#a89cb5] font-light">({provider.reviewCount} reviews)</span>
                  </div>

                  {/* Quick Info Grid */}
                  <div className="grid grid-cols-2 gap-3 mb-5 p-4 bg-[#f7f5f9] rounded-[20px]">
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4 text-[#a89cb5] stroke-[1.5]" />
                      <span className="text-xs text-[#8b7a95] font-light">{provider.distance}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Phone className="w-4 h-4 text-[#a89cb5] stroke-[1.5]" />
                      <span className="text-xs text-[#8b7a95] font-light">{provider.phone.slice(-8)}</span>
                    </div>
                    {provider.acceptingNew && (
                      <div className="col-span-2">
                        <span className="text-xs px-3 py-1.5 rounded-[14px] bg-[#dce8e4]/80 text-[#6b9688] border border-[#c9e0d9]/30 font-light inline-block">
                          ✓ Accepting new patients
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Identity Tags */}
                  {provider.identityTags && provider.identityTags.length > 0 && (
                    <div className="mb-5">
                      <div className="flex items-center gap-2 mb-3">
                        <Info className="w-4 h-4 text-[#a89cb5] stroke-[1.5]" />
                        <span className="text-xs text-[#8b7a95] font-light">Background & specialties</span>
                      </div>
                      <div className="flex flex-wrap gap-2">
                        {provider.identityTags.map((tag, index) => (
                          <div
                            key={index}
                            className={`text-xs px-3 py-1.5 rounded-[14px] border font-light flex items-center gap-1.5 ${
                              tag.status === "verified"
                                ? "bg-[#e8e0f0]/60 text-[#8b7a95] border-[#d4c5e0]/30"
                                : "bg-[#f7f5f9] text-[#b5a8c2] border-[#e8e0f0]/50"
                            }`}
                          >
                            {tag.status === "verified" && <span className="text-[#8ba39c]">✓</span>}
                            {tag.label}
                            {tag.status === "pending" && (
                              <span className="text-[#b5a8c2] text-[10px]">(pending)</span>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Location */}
                  <div className="mb-5 p-4 bg-[#f7f5f9] rounded-[20px]">
                    <div className="flex items-start gap-3">
                      <MapPin className="w-4 h-4 text-[#a89cb5] stroke-[1.5] mt-0.5" />
                      <div>
                        <p className="text-sm text-[#6b5c75] font-light">{provider.address}</p>
                        <button className="text-xs text-[#a89cb5] font-light hover:text-[#8b7a95] transition-colors mt-1">
                          Get directions →
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex gap-3">
                    <Link
                      to={`/providers/${provider.id}`}
                      className="flex-1 py-3.5 px-4 rounded-[24px] bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] text-white text-sm hover:shadow-[0_4px_20px_rgba(168,156,181,0.25)] transition-all font-light shadow-[0_2px_12px_rgba(168,156,181,0.15)] text-center"
                    >
                      View full profile
                    </Link>
                    <button className="px-5 py-3.5 rounded-[24px] border border-[#e8e0f0]/50 text-[#8b7a95] text-sm hover:bg-[#f7f5f9] transition-colors font-light">
                      <Phone className="w-4 h-4 stroke-[1.5]" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Can't Find Provider */}
        <div className="mt-8 bg-gradient-to-br from-[#faf7fb] to-[#f9f5fb] rounded-[28px] p-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#f0e8f3]/50">
          <h3 className="mb-2 text-[#4a3f52] font-normal">Can't find who you're looking for?</h3>
          <p className="text-sm text-[#6b5c75] mb-4 font-light leading-relaxed">
            Help build this directory by adding providers you trust. Your contribution helps other mothers find quality care.
          </p>
          <Link
            to="/providers/add"
            className="inline-flex items-center gap-2 text-sm text-[#a89cb5] font-light hover:text-[#8b7a95] transition-colors"
          >
            Add a provider →
          </Link>
        </div>
      </div>
    </div>
  );
}
