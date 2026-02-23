import { Search, MapPin, ChevronDown, Info, Heart, Plus, AlertCircle, Sparkles } from "lucide-react";
import { useState } from "react";
import { Link, useNavigate } from "react-router";

export function ProviderSearchEntry() {
  const navigate = useNavigate();
  
  // TIER 1: Core filters
  const [zipCode, setZipCode] = useState("");
  const [city, setCity] = useState("");
  const [radius, setRadius] = useState("10");
  const [healthPlan, setHealthPlan] = useState("");
  const [providerTypes, setProviderTypes] = useState<string[]>([]);
  const program = "Medicaid"; // Fixed default
  
  // TIER 2: Care-fit filters
  const [acceptingNew, setAcceptingNew] = useState(false);
  const [telehealth, setTelehealth] = useState(false);
  const [languagesSpoken, setLanguagesSpoken] = useState<string[]>([]);
  const [specialties, setSpecialties] = useState<string[]>([]);
  
  // TIER 3: Advanced filters
  const [acceptsPregnant, setAcceptsPregnant] = useState(true);
  const [showAdvanced, setShowAdvanced] = useState(false);
  
  // CLIENT-SIDE FILTERS (Not API params - filter after results)
  const [mamaApprovedOnly, setMamaApprovedOnly] = useState(false);
  const [identityTags, setIdentityTags] = useState<string[]>([]);
  
  // UI State
  const [showProviderTypes, setShowProviderTypes] = useState(false);
  const [showSpecialties, setShowSpecialties] = useState(false);
  const [showIdentityTags, setShowIdentityTags] = useState(false);
  const [showLanguages, setShowLanguages] = useState(false);

  // Ohio Medicaid Health Plans
  const healthPlans = [
    "Buckeye Health Plan",
    "CareSource",
    "Molina Healthcare",
    "UnitedHealthcare Community Plan",
    "Aetna Better Health",
    "Humana Healthy Horizons",
    "Anthem Blue Cross Blue Shield",
    "AmeriHealth Caritas"
  ];

  // Provider Types
  const providerTypeOptions = [
    { id: "001", label: "OB-GYN" },
    { id: "002", label: "Family Medicine" },
    { id: "003", label: "Certified Nurse Midwife" },
    { id: "004", label: "Birth Center" },
    { id: "005", label: "Doula" },
    { id: "006", label: "Mental Health Provider" },
    { id: "007", label: "Lactation Consultant" }
  ];

  // Specialties
  const specialtyOptions = [
    { id: "S001", label: "Prenatal Care" },
    { id: "S002", label: "High-Risk Pregnancy" },
    { id: "S003", label: "VBAC Support" },
    { id: "S004", label: "Home Birth" },
    { id: "S005", label: "Water Birth" },
    { id: "S006", label: "Gentle Cesarean" },
    { id: "S007", label: "Postpartum Care" },
    { id: "S008", label: "Birth Trauma Support" },
    { id: "S009", label: "Gestational Diabetes" },
    { id: "S010", label: "Maternal Mental Health" }
  ];

  // Languages
  const languageOptions = [
    "English",
    "Spanish",
    "Arabic",
    "French",
    "Haitian Creole",
    "Somali",
    "Mandarin",
    "Vietnamese",
    "Tagalog",
    "Portuguese",
    "Russian"
  ];

  // Identity Tags (CLIENT-SIDE FILTER - not API params)
  const identityTagOptions = [
    "Black / African American",
    "Latina/o/x",
    "Asian / Pacific Islander",
    "Native American / Indigenous",
    "Middle Eastern / North African",
    "LGBTQ+ affirming",
    "Cultural competency certified"
  ];

  const toggleItem = (item: string, list: string[], setter: (list: string[]) => void) => {
    if (list.includes(item)) {
      setter(list.filter(i => i !== item));
    } else {
      setter([...list, item]);
    }
  };

  const handleSearch = () => {
    // Navigate to results even if fields are empty
    navigate("/providers/results");
  };

  return (
    <div className="min-h-screen bg-[#f7f5f9] pb-24">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#ebe4f3] via-[#e0d5eb] to-[#e8dfe8] px-6 pt-6 pb-8 mb-6 relative overflow-hidden">
        <div className="absolute inset-0 opacity-5">
          <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-white blur-3xl"></div>
          <div className="absolute bottom-0 left-0 w-40 h-40 rounded-full bg-[#d4c5e0] blur-3xl"></div>
        </div>
        
        <div className="relative">
          <Link to="/providers" className="inline-flex items-center gap-2 text-[#8b7a95] hover:text-[#6b5c75] transition-colors mb-4 font-light text-sm">
            ← Back to providers
          </Link>
          <h1 className="text-2xl text-[#4a3f52] mb-2 font-normal">Find your care team</h1>
          <p className="text-[#6b5c75] text-sm font-light">Search Ohio providers with filters that matter to you</p>
        </div>
      </div>

      <div className="px-6 max-w-2xl mx-auto">
        {/* Info Banner */}
        <div className="mb-6 p-5 bg-gradient-to-br from-[#f0ead8] to-[#f5f0e8] rounded-[28px] border border-[#e8dfc8]/50 shadow-[0_2px_16px_rgba(0,0,0,0.04)]">
          <div className="flex items-start gap-3">
            <Info className="w-5 h-5 text-[#c9b087] flex-shrink-0 mt-0.5 stroke-[1.5]" />
            <div>
              <p className="text-sm text-[#6b5c75] mb-2 font-light leading-relaxed">
                <strong className="font-normal">How search works:</strong> We search Ohio Medicaid directories + NPI registry, then add community trust indicators.
              </p>
              <p className="text-xs text-[#a89cb5] font-light leading-relaxed">
                "Mama Approved™" and identity tags are community-powered filters.
              </p>
            </div>
          </div>
        </div>

        {/* TIER 1: Location */}
        <section className="mb-6">
          <div className="bg-white/60 backdrop-blur-sm rounded-[32px] p-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
            <div className="flex items-center gap-2 mb-5">
              <MapPin className="w-5 h-5 text-[#a89cb5] stroke-[1.5]" />
              <h2 className="text-[#4a3f52] font-normal">Location</h2>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm text-[#8b7a95] mb-2 font-light">ZIP code (optional)</label>
                <input
                  type="text"
                  maxLength={5}
                  value={zipCode}
                  onChange={(e) => setZipCode(e.target.value.replace(/\D/g, ''))}
                  placeholder="43215"
                  className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 transition-colors text-[#4a3f52] placeholder:text-[#b5a8c2] font-light"
                />
              </div>

              <div>
                <label className="block text-sm text-[#8b7a95] mb-2 font-light">City (optional)</label>
                <select
                  value={city}
                  onChange={(e) => setCity(e.target.value)}
                  className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 transition-colors text-[#4a3f52] font-light"
                >
                  <option value="">Select a city</option>
                  <option value="Columbus">Columbus</option>
                  <option value="Cleveland">Cleveland</option>
                  <option value="Cincinnati">Cincinnati</option>
                  <option value="Toledo">Toledo</option>
                  <option value="Akron">Akron</option>
                  <option value="Dayton">Dayton</option>
                </select>
              </div>

              <div>
                <label className="block text-sm text-[#8b7a95] mb-2 font-light">Search radius</label>
                <select
                  value={radius}
                  onChange={(e) => setRadius(e.target.value)}
                  className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 transition-colors text-[#4a3f52] font-light"
                >
                  <option value="5">5 miles</option>
                  <option value="10">10 miles</option>
                  <option value="25">25 miles</option>
                  <option value="50">50 miles</option>
                </select>
              </div>
            </div>
          </div>
        </section>

        {/* Health Plan */}
        <section className="mb-6">
          <div className="bg-white/60 backdrop-blur-sm rounded-[32px] p-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
            <h2 className="text-[#4a3f52] font-normal mb-2">Health plan (optional)</h2>
            <p className="text-sm text-[#8b7a95] mb-4 font-light">Which plan do you have?</p>
            
            <select
              value={healthPlan}
              onChange={(e) => setHealthPlan(e.target.value)}
              className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 transition-colors text-[#4a3f52] font-light"
            >
              <option value="">Select a health plan</option>
              {healthPlans.map(plan => (
                <option key={plan} value={plan}>{plan}</option>
              ))}
            </select>
          </div>
        </section>

        {/* Provider Types */}
        <section className="mb-6">
          <div className="bg-white/60 backdrop-blur-sm rounded-[32px] p-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
            <h2 className="text-[#4a3f52] font-normal mb-2">Provider type</h2>
            <p className="text-sm text-[#8b7a95] mb-4 font-light">What kind of provider are you looking for?</p>
            
            <div className="space-y-2">
              {providerTypeOptions.map(type => (
                <button
                  key={type.id}
                  onClick={() => toggleItem(type.id, providerTypes, setProviderTypes)}
                  className={`w-full text-left px-5 py-3.5 rounded-[20px] transition-all font-light ${
                    providerTypes.includes(type.id)
                      ? "bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] text-white shadow-[0_2px_12px_rgba(168,156,181,0.2)]"
                      : "bg-[#f7f5f9] text-[#6b5c75] hover:bg-[#ede7f3]/50"
                  }`}
                >
                  {type.label} {providerTypes.includes(type.id) && "✓"}
                </button>
              ))}
            </div>
          </div>
        </section>

        {/* Specialties */}
        <section className="mb-6">
          <div className="bg-white/60 backdrop-blur-sm rounded-[32px] p-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
            <h2 className="text-[#4a3f52] font-normal mb-2">Specialties (optional)</h2>
            <p className="text-sm text-[#8b7a95] mb-4 font-light">Any specific care needs?</p>
            
            <div className="space-y-2">
              {specialtyOptions.slice(0, showAdvanced ? specialtyOptions.length : 5).map(specialty => (
                <button
                  key={specialty.id}
                  onClick={() => toggleItem(specialty.id, specialties, setSpecialties)}
                  className={`w-full text-left px-5 py-3.5 rounded-[20px] transition-all font-light text-sm ${
                    specialties.includes(specialty.id)
                      ? "bg-[#e8e0f0]/80 text-[#6b5c75] border border-[#d4c5e0]/50"
                      : "bg-[#f7f5f9] text-[#8b7a95] hover:bg-[#ede7f3]/50"
                  }`}
                >
                  {specialty.label} {specialties.includes(specialty.id) && "✓"}
                </button>
              ))}
            </div>
            
            {!showAdvanced && (
              <button
                onClick={() => setShowAdvanced(true)}
                className="mt-3 text-sm text-[#a89cb5] font-light hover:text-[#8b7a95] transition-colors"
              >
                Show all specialties →
              </button>
            )}
          </div>
        </section>

        {/* Languages */}
        <section className="mb-6">
          <div className="bg-white/60 backdrop-blur-sm rounded-[32px] p-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
            <h2 className="text-[#4a3f52] font-normal mb-2">Languages spoken (optional)</h2>
            <p className="text-sm text-[#8b7a95] mb-4 font-light">Prefer a provider who speaks your language?</p>
            
            <div className="flex flex-wrap gap-2">
              {languageOptions.map(lang => (
                <button
                  key={lang}
                  onClick={() => toggleItem(lang, languagesSpoken, setLanguagesSpoken)}
                  className={`px-4 py-2 rounded-[16px] text-sm transition-all font-light ${
                    languagesSpoken.includes(lang)
                      ? "bg-[#e8e0f0]/80 text-[#6b5c75] border border-[#d4c5e0]/50"
                      : "bg-[#f7f5f9] text-[#8b7a95] hover:bg-[#ede7f3]/50"
                  }`}
                >
                  {lang}
                </button>
              ))}
            </div>
          </div>
        </section>

        {/* Community Filters */}
        <section className="mb-6">
          <div className="bg-gradient-to-br from-[#faf7fb] to-[#f9f5fb] rounded-[32px] p-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#f0e8f3]/50">
            <div className="flex items-center gap-2 mb-2">
              <Sparkles className="w-5 h-5 text-[#c9b087] stroke-[1.5]" />
              <h2 className="text-[#4a3f52] font-normal">Community filters</h2>
            </div>
            <p className="text-sm text-[#8b7a95] mb-4 font-light">These are powered by reviews from other mothers</p>
            
            <div className="space-y-3">
              <button
                onClick={() => setMamaApprovedOnly(!mamaApprovedOnly)}
                className={`w-full text-left px-5 py-3.5 rounded-[20px] transition-all font-light ${
                  mamaApprovedOnly
                    ? "bg-[#f0e0e8]/80 text-[#c9a9c0] border border-[#e8d0e0]/50"
                    : "bg-white/60 backdrop-blur-sm text-[#8b7a95] border border-[#ede7f3]/50"
                }`}
              >
                ⭐ Mama Approved™ only {mamaApprovedOnly && "✓"}
              </button>

              <div>
                <p className="text-sm text-[#8b7a95] mb-2 font-light">Background & identity match</p>
                <div className="flex flex-wrap gap-2">
                  {identityTagOptions.map(tag => (
                    <button
                      key={tag}
                      onClick={() => toggleItem(tag, identityTags, setIdentityTags)}
                      className={`px-4 py-2 rounded-[16px] text-xs transition-all font-light ${
                        identityTags.includes(tag)
                          ? "bg-[#e8e0f0]/80 text-[#6b5c75] border border-[#d4c5e0]/50"
                          : "bg-white/60 backdrop-blur-sm text-[#a89cb5] border border-[#ede7f3]/50"
                      }`}
                    >
                      {tag}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Quick Toggles */}
        <section className="mb-8">
          <div className="bg-white/60 backdrop-blur-sm rounded-[32px] p-6 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
            <h2 className="text-[#4a3f52] font-normal mb-4">Additional preferences</h2>
            
            <div className="space-y-3">
              <button
                onClick={() => setAcceptingNew(!acceptingNew)}
                className={`w-full text-left px-5 py-3.5 rounded-[20px] transition-all font-light flex items-center justify-between ${
                  acceptingNew
                    ? "bg-[#dce8e4]/60 text-[#6b9688]"
                    : "bg-[#f7f5f9] text-[#8b7a95]"
                }`}
              >
                <span>Accepting new patients</span>
                <span>{acceptingNew ? "✓" : ""}</span>
              </button>

              <button
                onClick={() => setTelehealth(!telehealth)}
                className={`w-full text-left px-5 py-3.5 rounded-[20px] transition-all font-light flex items-center justify-between ${
                  telehealth
                    ? "bg-[#e8e0f0]/60 text-[#8b7a95]"
                    : "bg-[#f7f5f9] text-[#8b7a95]"
                }`}
              >
                <span>Offers telehealth</span>
                <span>{telehealth ? "✓" : ""}</span>
              </button>
            </div>
          </div>
        </section>

        {/* Search Button */}
        <button
          onClick={handleSearch}
          className="w-full py-4 rounded-[24px] bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] text-white hover:shadow-[0_4px_20px_rgba(168,156,181,0.25)] transition-all font-light shadow-[0_2px_12px_rgba(168,156,181,0.15)]"
        >
          Search providers
        </button>

        <p className="text-center text-sm text-[#a89cb5] mt-4 font-light">
          All fields are optional. We'll show you the best matches.
        </p>
      </div>
    </div>
  );
}
