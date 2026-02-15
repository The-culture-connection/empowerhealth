import { Search, MapPin, Star, Award, Filter, Shield, Heart } from "lucide-react";
import { useState } from "react";

export function ProviderSearch() {
  const [filters, setFilters] = useState({
    location: "",
    insurance: "",
    raceConcordance: false,
  });

  const providers = [
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
      specialties: ["High-risk pregnancy", "VBAC"],
      hasBlackMamaTag: false,
      raceMatch: false,
    },
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
      specialties: ["Cultural sensitivity", "Birth trauma"],
      hasBlackMamaTag: true,
      raceMatch: true,
    },
    {
      name: "Oakland Midwifery Collective",
      specialty: "Certified Nurse Midwife",
      practice: "Oakland Birth Center",
      location: "Oakland, CA",
      distance: "3.7 miles",
      rating: 5.0,
      reviews: 156,
      acceptingNew: true,
      languages: ["English", "Spanish", "Mandarin"],
      specialties: ["Home birth", "Water birth"],
      hasBlackMamaTag: true,
      raceMatch: false,
    },
    {
      name: "Dr. Lisa Chen",
      specialty: "Maternal-Fetal Medicine",
      practice: "UCSF Women's Health",
      location: "San Francisco, CA",
      distance: "12.5 miles",
      rating: 4.7,
      reviews: 312,
      acceptingNew: false,
      languages: ["English", "Mandarin", "Cantonese"],
      specialties: ["High-risk", "Multiple births"],
      hasBlackMamaTag: false,
      raceMatch: false,
    },
  ];

  return (
    <div className="p-5">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl mb-2">Find Your Provider</h1>
        <p className="text-gray-600">Search for care that feels right for you</p>
      </div>

      {/* Search Bar */}
      <div className="mb-4">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            type="text"
            placeholder="Search by name, practice, or specialty"
            className="w-full pl-12 pr-4 py-3 rounded-2xl bg-white border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20"
          />
        </div>
      </div>

      {/* Filters */}
      <section className="mb-6">
        <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
          <div className="flex items-center gap-2 mb-4">
            <Filter className="w-5 h-5 text-[#663399]" />
            <h2>Filters</h2>
          </div>
          <div className="space-y-4">
            <div>
              <label className="text-sm text-gray-600 mb-2 block">Location</label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                <input
                  type="text"
                  placeholder="City or ZIP code"
                  value={filters.location}
                  onChange={(e) => setFilters({ ...filters, location: e.target.value })}
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 text-sm"
                />
              </div>
            </div>

            <div>
              <label className="text-sm text-gray-600 mb-2 block">Insurance</label>
              <select
                value={filters.insurance}
                onChange={(e) => setFilters({ ...filters, insurance: e.target.value })}
                className="w-full px-4 py-2.5 rounded-xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 text-sm"
              >
                <option value="">Select insurance</option>
                <option value="bcbs">Blue Cross Blue Shield</option>
                <option value="kaiser">Kaiser Permanente</option>
                <option value="aetna">Aetna</option>
                <option value="cigna">Cigna</option>
              </select>
            </div>

            <div className="flex items-center justify-between pt-2">
              <div>
                <p className="text-sm">Race Concordance</p>
                <p className="text-xs text-gray-500">Show providers who match my background</p>
              </div>
              <button
                onClick={() => setFilters({ ...filters, raceConcordance: !filters.raceConcordance })}
                className={`w-12 h-6 rounded-full relative transition-colors ${
                  filters.raceConcordance ? "bg-[#663399]" : "bg-gray-200"
                }`}
              >
                <span
                  className={`absolute top-1 w-4 h-4 bg-white rounded-full transition-all ${
                    filters.raceConcordance ? "right-1" : "left-1"
                  }`}
                ></span>
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Results */}
      <section>
        <div className="flex items-center justify-between mb-3">
          <h2>Providers Near You</h2>
          <p className="text-sm text-gray-500">{providers.length} results</p>
        </div>

        <div className="space-y-4">
          {providers.map((provider, index) => (
            <div
              key={index}
              className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors cursor-pointer"
            >
              {/* Race Match Badge */}
              {provider.raceMatch && filters.raceConcordance && (
                <div className="mb-3 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-blue-50 text-blue-700 text-xs">
                  <Heart className="w-3.5 h-3.5" />
                  <span>Background match</span>
                </div>
              )}

              <div className="flex items-start gap-4">
                <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#663399] to-[#cbbec9] flex items-center justify-center flex-shrink-0 text-white text-lg">
                  {provider.name.charAt(0)}
                </div>
                <div className="flex-1">
                  <div className="flex items-start justify-between mb-1">
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="text-sm">{provider.name}</h3>
                        {provider.hasBlackMamaTag && (
                          <span className="text-xs px-2 py-0.5 rounded-lg bg-rose-100 text-rose-700 flex items-center gap-1">
                            <Award className="w-3 h-3" />
                          </span>
                        )}
                      </div>
                      <p className="text-sm text-gray-600">{provider.specialty}</p>
                      <p className="text-xs text-gray-500">{provider.practice}</p>
                    </div>
                    {provider.acceptingNew && (
                      <span className="text-xs px-2 py-1 rounded-lg bg-green-50 text-green-700">
                        Accepting new patients
                      </span>
                    )}
                  </div>

                  {/* Location */}
                  <div className="flex items-center gap-2 text-xs text-gray-500 mt-2 mb-3">
                    <MapPin className="w-3.5 h-3.5" />
                    <span>{provider.location}</span>
                    <span>•</span>
                    <span>{provider.distance}</span>
                  </div>

                  {/* Rating */}
                  <div className="flex items-center gap-2 mb-3">
                    <div className="flex items-center gap-1">
                      <Star className="w-4 h-4 fill-amber-400 text-amber-400" />
                      <span className="text-sm">{provider.rating}</span>
                      <span className="text-xs text-gray-500">({provider.reviews} reviews)</span>
                    </div>
                  </div>

                  {/* Languages */}
                  <div className="mb-3">
                    <p className="text-xs text-gray-500 mb-1">Languages:</p>
                    <div className="flex flex-wrap gap-1">
                      {provider.languages.map((lang, i) => (
                        <span key={i} className="text-xs px-2 py-0.5 rounded-lg bg-gray-100 text-gray-600">
                          {lang}
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* Specialties */}
                  <div>
                    <p className="text-xs text-gray-500 mb-1">Specialties:</p>
                    <div className="flex flex-wrap gap-1">
                      {provider.specialties.map((specialty, i) => (
                        <span key={i} className="text-xs px-2 py-1 rounded-lg bg-purple-50 text-[#663399]">
                          {specialty}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              </div>

              {/* Actions */}
              <div className="flex gap-2 mt-4 pt-4 border-t border-gray-100">
                <button className="flex-1 py-2 px-4 rounded-xl bg-[#663399] text-white text-sm hover:bg-[#552288] transition-colors">
                  View Profile
                </button>
                <button className="flex-1 py-2 px-4 rounded-xl border border-gray-200 text-gray-700 text-sm hover:border-[#663399]/30 transition-colors">
                  Read Reviews
                </button>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Anonymous Feedback Info */}
      <div className="mt-6 bg-gradient-to-br from-[#fef3f3] to-[#fff0f8] rounded-3xl p-5 shadow-sm border border-pink-100">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-2xl bg-rose-100 flex items-center justify-center flex-shrink-0">
            <Shield className="w-5 h-5 text-rose-600" />
          </div>
          <div>
            <h3 className="mb-1">Community Reviews</h3>
            <p className="text-sm text-gray-600">
              All provider reviews are anonymous and verified. Share your experience to help others make informed choices.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
