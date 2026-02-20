import { ArrowLeft, MapPin, Star, Heart, Phone, Clock, Award, Shield, Info, Bookmark, ChevronRight } from "lucide-react";
import { Link } from "react-router";
import { useState } from "react";

export function ProviderSearchResults() {
  const [savedProviders, setSavedProviders] = useState<string[]>([]);

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
        { label: "Home birth support", status: "verified" },
        { label: "Latina/o/x", status: "verified" }
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
        { label: "Spanish-speaking", status: "verified" },
        { label: "Accepts Medicaid", status: "verified" }
      ],
      phone: "(216) 778-4321"
    },
    {
      id: "4",
      name: "Amara Johnson, CD(DONA)",
      credentials: "Certified Doula",
      specialty: "Birth & Postpartum Doula",
      practice: "Sacred Beginnings Doula Services",
      address: "Cleveland, OH",
      distance: "3.5 miles",
      city: "Cleveland",
      mamaApproved: true,
      rating: 5.0,
      reviewCount: 143,
      acceptingNew: true,
      telehealth: false,
      identityTags: [
        { label: "Black / African American", status: "verified" },
        { label: "VBAC support", status: "verified" },
        { label: "Birth trauma support", status: "verified" }
      ],
      phone: "(216) 555-0198"
    }
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case "verified":
        return "text-green-600 bg-green-50 border-green-200";
      case "pending":
        return "text-amber-600 bg-amber-50 border-amber-200";
      case "disputed":
        return "text-gray-600 bg-gray-50 border-gray-200";
      default:
        return "text-gray-600 bg-gray-50 border-gray-200";
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "verified":
        return "✓";
      case "pending":
        return "⏱";
      case "disputed":
        return "?";
      default:
        return "";
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] pb-24">
      {/* Header */}
      <div className="bg-white border-b border-gray-100 px-5 py-4 sticky top-0 z-10">
        <div className="flex items-center gap-3">
          <Link to="/providers/search" className="text-gray-600 hover:text-[#663399]">
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <div>
            <h1 className="text-lg">Search Results</h1>
            <p className="text-xs text-gray-500">{providers.length} providers near Cleveland, OH</p>
          </div>
        </div>
      </div>

      {/* Filters Summary */}
      <div className="px-5 py-4 bg-gradient-to-br from-purple-50 to-blue-50 border-b border-blue-100">
        <div className="flex items-center justify-between mb-2">
          <p className="text-sm text-gray-700">Within 10 miles of 44115</p>
          <Link to="/providers/search" className="text-xs text-[#663399]">Edit filters</Link>
        </div>
        <div className="flex flex-wrap gap-2">
          <span className="px-2.5 py-1 rounded-full text-xs bg-white border border-gray-200">Buckeye Health Plan</span>
          <span className="px-2.5 py-1 rounded-full text-xs bg-white border border-gray-200">OB-GYN</span>
          <span className="px-2.5 py-1 rounded-full text-xs bg-white border border-gray-200">Accepting new patients</span>
        </div>
      </div>

      <div className="px-5 py-5">
        {/* Sort */}
        <div className="flex items-center justify-between mb-4">
          <p className="text-sm text-gray-600">Sorted by relevance</p>
          <select className="text-xs px-3 py-1.5 rounded-xl bg-white border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20">
            <option>Most relevant</option>
            <option>Highest rated</option>
            <option>Nearest</option>
            <option>Most reviewed</option>
            <option>Mama Approved first</option>
          </select>
        </div>

        {/* Results */}
        <div className="space-y-4">
          {providers.map((provider) => (
            <div key={provider.id} className="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
              {/* Provider Header */}
              <div className="p-5">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="text-lg">{provider.name}</h3>
                      {provider.mamaApproved && (
                        <div className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-gradient-to-r from-rose-50 to-pink-50 border border-rose-200">
                          <Award className="w-3.5 h-3.5 text-rose-600" />
                          <span className="text-xs text-rose-700 font-medium">Mama Approved™</span>
                        </div>
                      )}
                    </div>
                    <p className="text-sm text-gray-600 mb-1">{provider.credentials}</p>
                    <p className="text-sm text-gray-500">{provider.specialty}</p>
                  </div>
                  <button
                    onClick={() => toggleSave(provider.id)}
                    className={`p-2 rounded-xl transition-colors ${
                      savedProviders.includes(provider.id)
                        ? "bg-[#663399] text-white"
                        : "bg-gray-50 text-gray-400 hover:bg-gray-100"
                    }`}
                  >
                    <Bookmark className="w-5 h-5" fill={savedProviders.includes(provider.id) ? "currentColor" : "none"} />
                  </button>
                </div>

                {/* Rating */}
                <div className="flex items-center gap-2 mb-4">
                  <div className="flex items-center gap-1">
                    <Star className="w-4 h-4 fill-amber-400 text-amber-400" />
                    <span className="font-medium">{provider.rating}</span>
                  </div>
                  <span className="text-sm text-gray-500">({provider.reviewCount} reviews)</span>
                  {provider.acceptingNew && (
                    <>
                      <span className="text-gray-300">•</span>
                      <span className="text-xs px-2 py-0.5 rounded-full bg-green-50 text-green-700 border border-green-200">
                        ✓ Accepting
                      </span>
                    </>
                  )}
                  {provider.telehealth && (
                    <>
                      <span className="text-gray-300">•</span>
                      <span className="text-xs text-gray-500">Telehealth</span>
                    </>
                  )}
                </div>

                {/* Location */}
                <div className="flex items-start gap-2 mb-4 p-3 bg-gray-50 rounded-2xl">
                  <MapPin className="w-4 h-4 text-[#663399] flex-shrink-0 mt-0.5" />
                  <div className="flex-1 text-sm">
                    <p className="text-gray-700">{provider.practice}</p>
                    <p className="text-gray-500 text-xs">{provider.address}</p>
                    <p className="text-[#663399] text-xs mt-1">{provider.distance} away</p>
                  </div>
                </div>

                {/* Identity Tags */}
                {provider.identityTags.length > 0 && (
                  <div className="mb-4">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-xs text-gray-500">Identity & Cultural Tags</span>
                      <button className="text-[#663399]">
                        <Info className="w-3.5 h-3.5" />
                      </button>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {provider.identityTags.map((tag, index) => (
                        <div
                          key={index}
                          className={`px-2.5 py-1 rounded-full text-xs border flex items-center gap-1.5 ${getStatusColor(tag.status)}`}
                        >
                          <span>{tag.label}</span>
                          <span className="opacity-60">{getStatusIcon(tag.status)}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Actions */}
                <div className="flex gap-2">
                  <Link
                    to={`/providers/${provider.id}`}
                    className="flex-1 py-3 px-4 rounded-2xl bg-[#663399] text-white text-sm text-center hover:bg-[#552288] transition-colors shadow-sm"
                  >
                    View Profile
                  </Link>
                  <a
                    href={`tel:${provider.phone}`}
                    className="px-4 py-3 rounded-2xl border border-gray-200 text-gray-700 hover:border-[#663399]/30 transition-colors"
                  >
                    <Phone className="w-4 h-4" />
                  </a>
                  <Link
                    to={`/providers/${provider.id}/review`}
                    className="px-4 py-3 rounded-2xl border border-gray-200 text-gray-700 hover:border-[#663399]/30 transition-colors text-sm flex items-center gap-1"
                  >
                    Review
                  </Link>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Add Provider CTA */}
        <div className="mt-6 bg-gradient-to-br from-blue-50 to-purple-50 rounded-3xl p-5 shadow-sm border border-blue-100">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-2xl bg-[#663399] flex items-center justify-center flex-shrink-0">
              <Heart className="w-5 h-5 text-white" />
            </div>
            <div className="flex-1">
              <h3 className="mb-2">Don't see your provider?</h3>
              <p className="text-sm text-gray-600 mb-3">
                Help other mothers by adding your provider to our community directory.
              </p>
              <Link
                to="/providers/add"
                className="inline-flex items-center gap-2 text-sm text-[#663399] font-medium"
              >
                Add a provider
                <ChevronRight className="w-4 h-4" />
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
