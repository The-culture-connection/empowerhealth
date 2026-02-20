import { Search, MapPin, ChevronDown, Info, Heart, Plus } from "lucide-react";
import { useState } from "react";
import { Link } from "react-router";

export function ProviderSearchEntry() {
  const [zipCode, setZipCode] = useState("");
  const [radius, setRadius] = useState("10");
  const [healthPlan, setHealthPlan] = useState("");
  const [includeNPI, setIncludeNPI] = useState(false);
  const [providerTypes, setProviderTypes] = useState<string[]>([]);
  const [specialties, setSpecialties] = useState<string[]>([]);
  const [showAdvanced, setShowAdvanced] = useState(false);
  
  // Advanced filters
  const [acceptingNew, setAcceptingNew] = useState(false);
  const [telehealth, setTelehealth] = useState(false);
  const [acceptsPregnant, setAcceptsPregnant] = useState(true);
  const [mamaApprovedOnly, setMamaApprovedOnly] = useState(false);
  const [identityTags, setIdentityTags] = useState<string[]>([]);
  const [languages, setLanguages] = useState<string[]>([]);
  const [showProviderTypes, setShowProviderTypes] = useState(false);
  const [showSpecialties, setShowSpecialties] = useState(false);
  const [showIdentityTags, setShowIdentityTags] = useState(false);
  const [showLanguages, setShowLanguages] = useState(false);

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

  const providerTypeOptions = [
    "Doula",
    "Nurse Midwife (Individual)",
    "Nurse Midwife (Group Practice)",
    "Free Standing Birth Center",
    "Hospital - Birth Center",
    "Physician/Osteopath (OB-GYN)",
    "Physician/Osteopath (Family Medicine)",
    "Certified Nurse Midwife",
    "Mental Health Provider",
    "Lactation Consultant"
  ];

  const specialtyOptions = [
    "High-Risk Pregnancy",
    "VBAC Support",
    "Home Birth",
    "Water Birth",
    "Gentle Cesarean",
    "Prenatal Care",
    "Postpartum Care",
    "Birth Trauma Support",
    "Gestational Diabetes",
    "Hypertension Management",
    "Multiple Births",
    "Maternal Mental Health"
  ];

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

  const languageOptions = [
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

  const toggleItem = (item: string, list: string[], setter: (list: string[]) => void) => {
    if (list.includes(item)) {
      setter(list.filter(i => i !== item));
    } else {
      setter([...list, item]);
    }
  };

  const canSearch = zipCode.length === 5 && radius && healthPlan && providerTypes.length > 0;

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] pb-24">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] px-5 pt-5 pb-8 mb-4">
        <div className="mb-2">
          <h1 className="text-2xl text-white mb-2">Find Your Care Team</h1>
          <p className="text-white/90 text-sm">Find care that feels safe and respectful</p>
        </div>
      </div>

      <div className="px-5">
        {/* Location Section */}
        <section className="mb-4">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <h2 className="mb-4 flex items-center gap-2">
              <MapPin className="w-5 h-5 text-[#663399]" />
              Location
            </h2>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-2">ZIP Code <span className="text-rose-500">*</span></label>
                <input
                  type="text"
                  maxLength={5}
                  value={zipCode}
                  onChange={(e) => setZipCode(e.target.value.replace(/\D/g, ''))}
                  placeholder="Enter your ZIP code"
                  className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium mb-2">Search Radius <span className="text-rose-500">*</span></label>
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
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">State</label>
                  <input
                    type="text"
                    value="Ohio"
                    disabled
                    className="w-full px-4 py-3 rounded-2xl bg-gray-100 border border-gray-200 text-gray-500"
                  />
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Insurance / Data Source */}
        <section className="mb-4">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <h2 className="mb-4">Insurance & Directory</h2>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-2">Health Plan <span className="text-rose-500">*</span></label>
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
                <p className="text-xs text-gray-500 mt-2">Plan required for Ohio Medicaid directory</p>
              </div>

              <div className="p-4 bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl border border-blue-100">
                <label className="flex items-start gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={includeNPI}
                    onChange={(e) => setIncludeNPI(e.target.checked)}
                    className="mt-1 w-5 h-5 rounded border-gray-300 text-[#663399] focus:ring-[#663399]/20"
                  />
                  <div>
                    <span className="block text-sm font-medium mb-1">Include providers from NPI directory</span>
                    <span className="text-xs text-gray-600">
                      Adds all providers if no Medicaid match is found
                    </span>
                  </div>
                </label>
              </div>
            </div>
          </div>
        </section>

        {/* Provider Type */}
        <section className="mb-4">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <h2 className="mb-2">Provider Type <span className="text-rose-500">*</span></h2>
            <p className="text-xs text-gray-500 mb-3">Choose at least one</p>

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
                    key={type}
                    onClick={() => toggleItem(type, providerTypes, setProviderTypes)}
                    className={`px-3 py-2 rounded-2xl text-sm transition-colors ${
                      providerTypes.includes(type)
                        ? "bg-[#663399] text-white"
                        : "bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30"
                    }`}
                  >
                    {type}
                  </button>
                ))}
              </div>
            )}

            {providerTypes.length > 0 && (
              <div className="mt-3 flex flex-wrap gap-2">
                {providerTypes.map((type) => (
                  <span key={type} className="px-3 py-1.5 rounded-2xl text-xs bg-[#663399] text-white flex items-center gap-2">
                    {type}
                    <button
                      onClick={() => toggleItem(type, providerTypes, setProviderTypes)}
                      className="hover:bg-white/20 rounded-full"
                    >
                      ×
                    </button>
                  </span>
                ))}
              </div>
            )}
          </div>
        </section>

        {/* Specialty */}
        <section className="mb-4">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <h2 className="mb-2">Specialty (Optional)</h2>
            <p className="text-xs text-gray-500 mb-3">Start typing to find a specialty, then select from suggestions</p>

            <button
              onClick={() => setShowSpecialties(!showSpecialties)}
              className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 flex items-center justify-between text-left hover:border-[#663399]/30 transition-colors"
            >
              <span className="text-sm text-gray-600">
                {specialties.length > 0 ? `${specialties.length} selected` : "Select specialties"}
              </span>
              <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${showSpecialties ? 'rotate-180' : ''}`} />
            </button>

            {showSpecialties && (
              <div className="mt-3 flex flex-wrap gap-2">
                {specialtyOptions.map((specialty) => (
                  <button
                    key={specialty}
                    onClick={() => toggleItem(specialty, specialties, setSpecialties)}
                    className={`px-3 py-2 rounded-2xl text-sm transition-colors ${
                      specialties.includes(specialty)
                        ? "bg-[#663399] text-white"
                        : "bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30"
                    }`}
                  >
                    {specialty}
                  </button>
                ))}
              </div>
            )}

            {specialties.length > 0 && (
              <div className="mt-3 flex flex-wrap gap-2">
                {specialties.map((specialty) => (
                  <span key={specialty} className="px-3 py-1.5 rounded-2xl text-xs bg-purple-50 text-[#663399] border border-purple-100 flex items-center gap-2">
                    {specialty}
                    <button
                      onClick={() => toggleItem(specialty, specialties, setSpecialties)}
                      className="hover:bg-[#663399]/10 rounded-full"
                    >
                      ×
                    </button>
                  </span>
                ))}
              </div>
            )}
          </div>
        </section>

        {/* Advanced Filters */}
        <section className="mb-6">
          <button
            onClick={() => setShowAdvanced(!showAdvanced)}
            className="w-full bg-white rounded-3xl p-4 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors flex items-center justify-between"
          >
            <span className="text-sm font-medium">Advanced Filters</span>
            <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${showAdvanced ? 'rotate-180' : ''}`} />
          </button>

          {showAdvanced && (
            <div className="mt-4 space-y-4">
              {/* Quick Toggles */}
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100 space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium">Accepting new patients</p>
                    <p className="text-xs text-gray-500">Currently taking appointments</p>
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

                <div className="h-px bg-gray-100"></div>

                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium">Telehealth available</p>
                    <p className="text-xs text-gray-500">Virtual appointments offered</p>
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

                <div className="h-px bg-gray-100"></div>

                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium">Accepts pregnant patients</p>
                    <p className="text-xs text-gray-500">Prenatal care provided</p>
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

                <div className="h-px bg-gray-100"></div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-medium">Mama Approved™ only</p>
                    <button className="text-[#663399]">
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
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-[#663399]/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#663399]"></div>
                  </label>
                </div>
              </div>

              {/* Identity Tags */}
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-medium">Identity & Cultural Match</h3>
                  <button className="text-[#663399]">
                    <Info className="w-4 h-4" />
                  </button>
                </div>
                <p className="text-xs text-gray-500 mb-3">Tags are community-added and may be pending verification</p>

                <button
                  onClick={() => setShowIdentityTags(!showIdentityTags)}
                  className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 flex items-center justify-between text-left hover:border-[#663399]/30 transition-colors"
                >
                  <span className="text-sm text-gray-600">
                    {identityTags.length > 0 ? `${identityTags.length} selected` : "Select identity tags"}
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
                            ? "bg-blue-500 text-white"
                            : "bg-gray-50 text-gray-700 border border-gray-200 hover:border-blue-300"
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
                      <span key={tag} className="px-3 py-1.5 rounded-2xl text-xs bg-blue-50 text-blue-700 border border-blue-200 flex items-center gap-2">
                        {tag}
                        <button
                          onClick={() => toggleItem(tag, identityTags, setIdentityTags)}
                          className="hover:bg-blue-100 rounded-full"
                        >
                          ×
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </div>

              {/* Languages */}
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <h3 className="text-sm font-medium mb-3">Languages Spoken</h3>

                <button
                  onClick={() => setShowLanguages(!showLanguages)}
                  className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 flex items-center justify-between text-left hover:border-[#663399]/30 transition-colors"
                >
                  <span className="text-sm text-gray-600">
                    {languages.length > 0 ? `${languages.length} selected` : "Select languages"}
                  </span>
                  <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${showLanguages ? 'rotate-180' : ''}`} />
                </button>

                {showLanguages && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {languageOptions.map((language) => (
                      <button
                        key={language}
                        onClick={() => toggleItem(language, languages, setLanguages)}
                        className={`px-3 py-2 rounded-2xl text-sm transition-colors ${
                          languages.includes(language)
                            ? "bg-[#663399] text-white"
                            : "bg-gray-50 text-gray-700 border border-gray-200 hover:border-[#663399]/30"
                        }`}
                      >
                        {language}
                      </button>
                    ))}
                  </div>
                )}

                {languages.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {languages.map((language) => (
                      <span key={language} className="px-3 py-1.5 rounded-2xl text-xs bg-purple-50 text-[#663399] border border-purple-100 flex items-center gap-2">
                        {language}
                        <button
                          onClick={() => toggleItem(language, languages, setLanguages)}
                          className="hover:bg-[#663399]/10 rounded-full"
                        >
                          ×
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
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
      </div>
    </div>
  );
}
