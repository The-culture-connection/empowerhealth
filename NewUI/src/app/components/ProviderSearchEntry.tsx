import { Search, MapPin, ChevronDown, Info, Heart, Plus, AlertCircle } from "lucide-react";
import { useState } from "react";
import { Link } from "react-router";

export function ProviderSearchEntry() {
  // TIER 1: Core filters (Required for API)
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

  // Provider Types (mapped to ProviderTypeIDsDelimited)
  const providerTypeOptions = [
    { id: "001", label: "Physician/Osteopath (OB-GYN)" },
    { id: "002", label: "Physician/Osteopath (Family Medicine)" },
    { id: "003", label: "Certified Nurse Midwife" },
    { id: "004", label: "Nurse Midwife (Individual)" },
    { id: "005", label: "Nurse Midwife (Group Practice)" },
    { id: "006", label: "Free Standing Birth Center" },
    { id: "007", label: "Hospital - Birth Center" },
    { id: "008", label: "Doula" },
    { id: "009", label: "Mental Health Provider" },
    { id: "010", label: "Lactation Consultant" }
  ];

  // Specialties (mapped to SpecialtyTypeIDsDelimited - validated list)
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
    { id: "S010", label: "Hypertension Management" },
    { id: "S011", label: "Multiple Births" },
    { id: "S012", label: "Maternal Mental Health" }
  ];

  // Languages (mapped to LanguagesSpoken)
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
    "Haitian",
    "Nigerian",
    "Somali",
    "Spanish-speaking",
    "Arabic-speaking",
    "French-speaking",
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

  // Validation: Required fields per API spec
  const canSearch = zipCode.length === 5 && healthPlan && providerTypes.length > 0;

  const buildSearchParams = () => {
    // This would be sent to your API
    return {
      // TIER 1: Required
      State: "OH",
      Zip: zipCode,
      City: city,
      Radius: radius,
      HealthPlan: healthPlan,
      ProviderTypeIDsDelimited: providerTypes.join(","),
      Program: program,
      
      // TIER 2: Care-fit filters
      AcceptsNewPatients: acceptingNew ? "Yes" : undefined,
      Telehealth: telehealth ? "Yes" : undefined,
      LanguagesSpoken: languagesSpoken.length > 0 ? languagesSpoken.join(",") : undefined,
      SpecialtyTypeIDsDelimited: specialties.length > 0 ? specialties.join(",") : undefined,
      
      // TIER 3: Advanced
      AcceptsPregnantWomen: acceptsPregnant ? "Yes" : undefined,
      
      // CLIENT-SIDE (not sent to API)
      _clientFilters: {
        mamaApprovedOnly,
        identityTags
      }
    };
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] pb-24">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] px-5 pt-5 pb-8 mb-4">
        <div className="mb-2">
          <h1 className="text-2xl text-white mb-2">Find Your Care Team</h1>
          <p className="text-white/90 text-sm">Search Ohio Medicaid providers with filters that matter to you</p>
        </div>
      </div>

      <div className="px-5">
        {/* API Info Banner */}
        <div className="mb-4 p-4 bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl border border-blue-100">
          <div className="flex items-start gap-3">
            <Info className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm text-gray-700 mb-1">
                <strong>How search works:</strong> We search Ohio Medicaid directories + NPI registry, then filter by community trust indicators.
              </p>
              <p className="text-xs text-gray-600">
                Filters marked with * are required by the directory. "Mama Approved™" and identity tags are community-powered filters.
              </p>
            </div>
          </div>
        </div>

        {/* TIER 1: Core Location & Required Filters */}
        <section className="mb-4">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <div className="flex items-center gap-2 mb-4">
              <MapPin className="w-5 h-5 text-[#663399]" />
              <h2>Location & Directory</h2>
              <span className="ml-auto text-xs px-2 py-0.5 rounded-full bg-rose-50 text-rose-600 border border-rose-200">
                Required
              </span>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-2">
                  ZIP Code <span className="text-rose-500">*</span>
                </label>
                <input
                  type="text"
                  maxLength={5}
                  value={zipCode}
                  onChange={(e) => setZipCode(e.target.value.replace(/\D/g, ''))}
                  placeholder="44115"
                  className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors"
                />
                <p className="text-xs text-gray-500 mt-1">API param: <code className="text-[#663399]">Zip</code></p>
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">City (Optional)</label>
                <input
                  type="text"
                  value={city}
                  onChange={(e) => setCity(e.target.value)}
                  placeholder="Cleveland"
                  className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors"
                />
                <p className="text-xs text-gray-500 mt-1">API param: <code className="text-[#663399]">City</code></p>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium mb-2">
                    Search Radius <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={radius}
                    onChange={(e) => setRadius(e.target.value)}
                    className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 appearance-none"
                  >
                    <option value="3">3 miles</option>
                    <option value="5">5 miles</option>
                    <option value="10">10 miles</option>
                    <option value="15">15 miles</option>
                    <option value="25">25 miles</option>
                    <option value="50">50 miles</option>
                  </select>
                  <p className="text-xs text-gray-500 mt-1">API param: <code className="text-[#663399]">Radius</code></p>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">State</label>
                  <input
                    type="text"
                    value="Ohio"
                    disabled
                    className="w-full px-4 py-3 rounded-2xl bg-gray-100 border border-gray-200 text-gray-500"
                  />
                  <p className="text-xs text-gray-500 mt-1">API param: <code className="text-[#663399]">State=OH</code></p>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">
                  Health Plan <span className="text-rose-500">*</span>
                </label>
                <select
                  value={healthPlan}
                  onChange={(e) => setHealthPlan(e.target.value)}
                  className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 appearance-none"
                >
                  <option value="">Select your health plan</option>
                  {healthPlans.map((plan) => (
                    <option key={plan} value={plan}>{plan}</option>
                  ))}
                </select>
                <p className="text-xs text-gray-500 mt-1">
                  API param: <code className="text-[#663399]">HealthPlan</code> | Required for Medicaid directory
                </p>
              </div>

              <div className="p-3 bg-gray-50 rounded-2xl border border-gray-200">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium">Program</p>
                    <p className="text-xs text-gray-500">Fixed to Medicaid</p>
                  </div>
                  <span className="text-sm px-3 py-1 rounded-full bg-white border border-gray-200">
                    Medicaid
                  </span>
                </div>
                <p className="text-xs text-gray-500 mt-2">API param: <code className="text-[#663399]">Program=Medicaid</code></p>
              </div>
            </div>
          </div>
        </section>

        {/* TIER 1: Provider Type (Required) */}
        <section className="mb-4">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <h2>Provider Type <span className="text-rose-500">*</span></h2>
                <span className="text-xs px-2 py-0.5 rounded-full bg-rose-50 text-rose-600 border border-rose-200">
                  Required
                </span>
              </div>
            </div>
            <p className="text-xs text-gray-500 mb-3">
              API param: <code className="text-[#663399]">ProviderTypeIDsDelimited</code> | Choose at least one
            </p>

            <button
              onClick={() => setShowProviderTypes(!showProviderTypes)}
              className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 flex items-center justify-between text-left hover:border-[#663399]/30 transition-colors"
            >
              <span className="text-sm text-gray-600">
                {providerTypes.length > 0 ? `${providerTypes.length} selected` : "Select provider types"}
              </span>
              <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${showProviderTypes ? 'rotate-180' : ''}`} />
            </button>

            {showProviderTypes && (
              <div className="mt-3 flex flex-wrap gap-2">
                {providerTypeOptions.map((type) => (
                  <button
                    key={type.id}
                    onClick={() => toggleItem(type.id, providerTypes, setProviderTypes)}
                    className={`px-3 py-2 rounded-2xl text-sm transition-colors ${
                      providerTypes.includes(type.id)
                        ? "bg-[#663399] text-white"
                        : "bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30"
                    }`}
                  >
                    {type.label}
                  </button>
                ))}
              </div>
            )}

            {providerTypes.length > 0 && (
              <div className="mt-3 flex flex-wrap gap-2">
                {providerTypes.map((typeId) => {
                  const type = providerTypeOptions.find(t => t.id === typeId);
                  return (
                    <span key={typeId} className="px-3 py-1.5 rounded-2xl text-xs bg-[#663399] text-white flex items-center gap-2">
                      {type?.label}
                      <button
                        onClick={() => toggleItem(typeId, providerTypes, setProviderTypes)}
                        className="hover:bg-white/20 rounded-full"
                      >
                        ×
                      </button>
                    </span>
                  );
                })}
              </div>
            )}
          </div>
        </section>

        {/* TIER 2: Care-Fit Filters */}
        <section className="mb-4">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <div className="flex items-center gap-2 mb-4">
              <h2>Care Preferences</h2>
              <span className="text-xs px-2 py-0.5 rounded-full bg-blue-50 text-blue-600 border border-blue-200">
                Recommended
              </span>
            </div>
            <p className="text-xs text-gray-500 mb-4">High-value filters to find the right care for you</p>

            <div className="space-y-4">
              {/* Accepting New Patients */}
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-2xl border border-gray-200">
                <div className="flex-1">
                  <p className="text-sm font-medium">Accepting new patients</p>
                  <p className="text-xs text-gray-500">API param: <code className="text-[#663399]">AcceptsNewPatients=Yes</code></p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={acceptingNew}
                    onChange={(e) => setAcceptingNew(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-[#663399]/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#663399]"></div>
                </label>
              </div>

              {/* Telehealth */}
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-2xl border border-gray-200">
                <div className="flex-1">
                  <p className="text-sm font-medium">Telehealth available</p>
                  <p className="text-xs text-gray-500">API param: <code className="text-[#663399]">Telehealth=Yes</code></p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={telehealth}
                    onChange={(e) => setTelehealth(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-[#663399]/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#663399]"></div>
                </label>
              </div>

              {/* Languages Spoken */}
              <div>
                <label className="block text-sm font-medium mb-2">Languages Spoken</label>
                <p className="text-xs text-gray-500 mb-2">API param: <code className="text-[#663399]">LanguagesSpoken</code></p>
                
                <button
                  onClick={() => setShowLanguages(!showLanguages)}
                  className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 flex items-center justify-between text-left hover:border-[#663399]/30 transition-colors"
                >
                  <span className="text-sm text-gray-600">
                    {languagesSpoken.length > 0 ? `${languagesSpoken.length} selected` : "Any language"}
                  </span>
                  <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${showLanguages ? 'rotate-180' : ''}`} />
                </button>

                {showLanguages && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {languageOptions.map((language) => (
                      <button
                        key={language}
                        onClick={() => toggleItem(language, languagesSpoken, setLanguagesSpoken)}
                        className={`px-3 py-2 rounded-2xl text-sm transition-colors ${
                          languagesSpoken.includes(language)
                            ? "bg-[#663399] text-white"
                            : "bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30"
                        }`}
                      >
                        {language}
                      </button>
                    ))}
                  </div>
                )}

                {languagesSpoken.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {languagesSpoken.map((language) => (
                      <span key={language} className="px-3 py-1.5 rounded-2xl text-xs bg-blue-50 text-blue-700 border border-blue-200 flex items-center gap-2">
                        {language}
                        <button
                          onClick={() => toggleItem(language, languagesSpoken, setLanguagesSpoken)}
                          className="hover:bg-blue-100 rounded-full"
                        >
                          ×
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </div>

              {/* Specialty */}
              <div>
                <label className="block text-sm font-medium mb-2">Specialty (Optional)</label>
                <p className="text-xs text-gray-500 mb-2">API param: <code className="text-[#663399]">SpecialtyTypeIDsDelimited</code> | Validated IDs only</p>

                <button
                  onClick={() => setShowSpecialties(!showSpecialties)}
                  className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 flex items-center justify-between text-left hover:border-[#663399]/30 transition-colors"
                >
                  <span className="text-sm text-gray-600">
                    {specialties.length > 0 ? `${specialties.length} selected` : "Any specialty"}
                  </span>
                  <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${showSpecialties ? 'rotate-180' : ''}`} />
                </button>

                {showSpecialties && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {specialtyOptions.map((specialty) => (
                      <button
                        key={specialty.id}
                        onClick={() => toggleItem(specialty.id, specialties, setSpecialties)}
                        className={`px-3 py-2 rounded-2xl text-sm transition-colors ${
                          specialties.includes(specialty.id)
                            ? "bg-[#663399] text-white"
                            : "bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30"
                        }`}
                      >
                        {specialty.label}
                      </button>
                    ))}
                  </div>
                )}

                {specialties.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {specialties.map((specialtyId) => {
                      const specialty = specialtyOptions.find(s => s.id === specialtyId);
                      return (
                        <span key={specialtyId} className="px-3 py-1.5 rounded-2xl text-xs bg-purple-50 text-[#663399] border border-purple-100 flex items-center gap-2">
                          {specialty?.label}
                          <button
                            onClick={() => toggleItem(specialtyId, specialties, setSpecialties)}
                            className="hover:bg-[#663399]/10 rounded-full"
                          >
                            ×
                          </button>
                        </span>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>
          </div>
        </section>

        {/* TIER 3: Advanced Filters */}
        <section className="mb-4">
          <button
            onClick={() => setShowAdvanced(!showAdvanced)}
            className="w-full bg-white rounded-3xl p-4 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors flex items-center justify-between"
          >
            <div className="flex items-center gap-2">
              <span className="text-sm font-medium">Advanced Filters</span>
              <span className="text-xs px-2 py-0.5 rounded-full bg-gray-100 text-gray-600">
                Optional
              </span>
            </div>
            <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${showAdvanced ? 'rotate-180' : ''}`} />
          </button>

          {showAdvanced && (
            <div className="mt-4 bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
              <p className="text-xs text-gray-500 mb-4">Additional filters from the Medicaid directory</p>

              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-2xl border border-gray-200">
                <div className="flex-1">
                  <p className="text-sm font-medium">Accepts pregnant patients</p>
                  <p className="text-xs text-gray-500">API param: <code className="text-[#663399]">AcceptsPregnantWomen=Yes</code></p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={acceptsPregnant}
                    onChange={(e) => setAcceptsPregnant(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-[#663399]/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#663399]"></div>
                </label>
              </div>
            </div>
          )}
        </section>

        {/* CLIENT-SIDE FILTERS: Trust Layer */}
        <section className="mb-6">
          <div className="bg-gradient-to-br from-rose-50 to-pink-50 rounded-3xl p-5 shadow-sm border border-rose-100">
            <div className="flex items-center gap-2 mb-3">
              <Heart className="w-5 h-5 text-rose-600" />
              <h2>Community Trust Filters</h2>
              <span className="text-xs px-2 py-0.5 rounded-full bg-white/70 text-rose-700 border border-rose-200">
                Community-powered
              </span>
            </div>
            <p className="text-xs text-gray-600 mb-4">
              <strong>Note:</strong> These filters are applied <em>after</em> getting results from the directory. They're not API parameters—they filter based on community reviews and verified tags in our database.
            </p>

            <div className="space-y-4">
              {/* Mama Approved */}
              <div className="flex items-center justify-between p-3 bg-white rounded-2xl border border-rose-200">
                <div className="flex-1 flex items-center gap-2">
                  <p className="text-sm font-medium">Mama Approved™ only</p>
                  <button className="text-rose-600">
                    <Info className="w-4 h-4" />
                  </button>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={mamaApprovedOnly}
                    onChange={(e) => setMamaApprovedOnly(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-rose-300/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-rose-500"></div>
                </label>
              </div>
              <p className="text-xs text-gray-500 pl-3">
                Filter: <code className="text-rose-600">clientFilters.mamaApprovedOnly</code> | Applied locally after API results
              </p>

              {/* Identity Tags */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <label className="text-sm font-medium">Identity & Cultural Match</label>
                  <button className="text-rose-600">
                    <Info className="w-4 h-4" />
                  </button>
                </div>
                <p className="text-xs text-gray-500 mb-3">
                  Filter: <code className="text-rose-600">clientFilters.identityTags</code> | Tags are community-added with verification status
                </p>

                <button
                  onClick={() => setShowIdentityTags(!showIdentityTags)}
                  className="w-full px-4 py-3 rounded-2xl bg-white border border-rose-200 flex items-center justify-between text-left hover:border-rose-300 transition-colors"
                >
                  <span className="text-sm text-gray-700">
                    {identityTags.length > 0 ? `${identityTags.length} selected` : "Any identity/cultural match"}
                  </span>
                  <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${showIdentityTags ? 'rotate-180' : ''}`} />
                </button>

                {showIdentityTags && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {identityTagOptions.map((tag) => (
                      <button
                        key={tag}
                        onClick={() => toggleItem(tag, identityTags, setIdentityTags)}
                        className={`px-3 py-2 rounded-2xl text-sm transition-colors ${
                          identityTags.includes(tag)
                            ? "bg-rose-500 text-white"
                            : "bg-white text-gray-700 border border-rose-200 hover:border-rose-300"
                        }`}
                      >
                        {tag}
                      </button>
                    ))}
                  </div>
                )}

                {identityTags.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {identityTags.map((tag) => (
                      <span key={tag} className="px-3 py-1.5 rounded-2xl text-xs bg-rose-100 text-rose-700 border border-rose-200 flex items-center gap-2">
                        {tag}
                        <button
                          onClick={() => toggleItem(tag, identityTags, setIdentityTags)}
                          className="hover:bg-rose-200 rounded-full"
                        >
                          ×
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </section>

        {/* Search Button */}
        <div className="space-y-3">
          <Link
            to={canSearch ? "/providers/results" : "#"}
            className={`block w-full py-4 px-4 rounded-2xl text-center transition-colors shadow-sm ${
              canSearch
                ? "bg-[#663399] text-white hover:bg-[#552288]"
                : "bg-gray-200 text-gray-400 cursor-not-allowed"
            }`}
            onClick={(e) => {
              if (canSearch) {
                console.log("Search params:", buildSearchParams());
              } else {
                e.preventDefault();
              }
            }}
          >
            <Search className="w-5 h-5 inline mr-2" />
            Search Providers
          </Link>

          <Link
            to="/providers/add"
            className="block w-full py-3 px-4 rounded-2xl bg-white text-gray-700 border border-gray-200 hover:border-[#663399]/30 transition-colors flex items-center justify-center gap-2"
          >
            <Plus className="w-4 h-4" />
            Can't find your provider? Add them
          </Link>
        </div>

        {/* Developer Note */}
        <div className="mt-6 p-4 bg-gray-50 rounded-2xl border border-gray-200">
          <p className="text-xs text-gray-600">
            <strong>For developers:</strong> This form generates a properly structured API request with validated IDs. 
            The <code className="text-[#663399]">buildSearchParams()</code> function shows the exact parameters to send to the Ohio Medicaid API.
            Check the console when you search to see the full request structure.
          </p>
        </div>
      </div>
    </div>
  );
}