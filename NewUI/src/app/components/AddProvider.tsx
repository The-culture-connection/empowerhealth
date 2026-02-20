import { ArrowLeft, Info, CheckCircle2 } from "lucide-react";
import { Link } from "react-router";
import { useState } from "react";

export function AddProvider() {
  const [formData, setFormData] = useState({
    name: "",
    providerType: "",
    specialty: "",
    address: "",
    city: "",
    state: "OH",
    zipCode: "",
    phone: "",
    email: "",
    website: "",
    notes: ""
  });

  const [submitted, setSubmitted] = useState(false);

  const providerTypes = [
    "Doula",
    "Nurse Midwife (Individual)",
    "Nurse Midwife (Group Practice)",
    "Free Standing Birth Center",
    "Hospital - Birth Center",
    "Physician/Osteopath (OB-GYN)",
    "Physician/Osteopath (Family Medicine)",
    "Certified Nurse Midwife",
    "Mental Health Provider",
    "Lactation Consultant",
    "Pediatrician",
    "Other"
  ];

  const specialties = [
    "Prenatal Care",
    "High-Risk Pregnancy",
    "VBAC Support",
    "Home Birth",
    "Water Birth",
    "Gentle Cesarean",
    "Postpartum Care",
    "Birth Trauma Support",
    "Gestational Diabetes",
    "Hypertension Management",
    "Multiple Births",
    "Maternal Mental Health",
    "Lactation Support",
    "General OB-GYN",
    "Family Medicine"
  ];

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // In real implementation, this would send to moderation queue
    setSubmitted(true);
  };

  const canSubmit = formData.name && formData.providerType && formData.specialty && formData.address && formData.zipCode;

  if (submitted) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] pb-24">
        {/* Header */}
        <div className="bg-white border-b border-gray-100 px-5 py-4">
          <Link to="/providers/results" className="flex items-center gap-2 text-gray-600 hover:text-[#663399]">
            <ArrowLeft className="w-5 h-5" />
            <span className="text-sm">Back to search</span>
          </Link>
        </div>

        <div className="px-5 py-8 flex items-center justify-center min-h-[calc(100vh-200px)]">
          <div className="max-w-md w-full">
            {/* Success State */}
            <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-3xl p-8 text-center shadow-sm border border-green-100">
              <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-4">
                <CheckCircle2 className="w-8 h-8 text-green-600" />
              </div>
              <h2 className="text-2xl mb-3">Thank you!</h2>
              <p className="text-gray-700 mb-6">
                We've received your provider submission. Our team will review the information and publish it to help other mothers in the community.
              </p>
              <div className="bg-white rounded-2xl p-4 mb-6">
                <p className="text-sm text-gray-600 mb-2">
                  <strong>What happens next?</strong>
                </p>
                <ul className="text-sm text-gray-600 space-y-1 text-left">
                  <li>• Our team reviews the information (usually 1-2 business days)</li>
                  <li>• We may verify details with the provider</li>
                  <li>• Once approved, the provider appears in search results</li>
                  <li>• You'll receive a notification when it's published</li>
                </ul>
              </div>
              <div className="space-y-3">
                <Link
                  to="/providers/results"
                  className="block w-full py-3 px-4 rounded-2xl bg-[#663399] text-white hover:bg-[#552288] transition-colors shadow-sm"
                >
                  Back to search
                </Link>
                <button
                  onClick={() => setSubmitted(false)}
                  className="block w-full py-3 px-4 rounded-2xl bg-white text-gray-700 border border-gray-200 hover:border-[#663399]/30 transition-colors"
                >
                  Add another provider
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] pb-24">
      {/* Header */}
      <div className="bg-white border-b border-gray-100 px-5 py-4 sticky top-0 z-10">
        <div className="flex items-center justify-between">
          <Link to="/providers/results" className="flex items-center gap-2 text-gray-600 hover:text-[#663399]">
            <ArrowLeft className="w-5 h-5" />
            <span className="text-sm">Cancel</span>
          </Link>
          <button
            onClick={handleSubmit}
            disabled={!canSubmit}
            className={`py-2 px-6 rounded-2xl text-sm transition-colors ${
              canSubmit
                ? "bg-[#663399] text-white hover:bg-[#552288]"
                : "bg-gray-200 text-gray-400 cursor-not-allowed"
            }`}
          >
            Submit
          </button>
        </div>
      </div>

      <div className="px-5 py-5">
        {/* Intro */}
        <section className="mb-6">
          <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] rounded-3xl p-6 text-white shadow-md">
            <h1 className="text-2xl mb-2">Add a Provider</h1>
            <p className="text-white/90 text-sm">
              Can't find your provider? Help other mothers by adding them to our community directory. We'll review and publish soon.
            </p>
          </div>
        </section>

        {/* Info Notice */}
        <div className="mb-6 bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl p-4 border border-blue-100">
          <div className="flex items-start gap-3">
            <Info className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm text-gray-700 mb-2">
                <strong>Before you add:</strong> Search carefully to avoid duplicates. Our team will verify the information before publishing.
              </p>
              <p className="text-xs text-gray-600">
                All submissions go through a moderation process to ensure accuracy and safety.
              </p>
            </div>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Basic Information */}
          <section>
            <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
              <h2 className="mb-4">Basic Information</h2>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-2">
                    Provider Name <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="Dr. Jane Smith or Smith Family Practice"
                    className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Provider Type <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={formData.providerType}
                    onChange={(e) => setFormData({ ...formData, providerType: e.target.value })}
                    className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 appearance-none"
                    required
                  >
                    <option value="">Select provider type</option>
                    {providerTypes.map((type) => (
                      <option key={type} value={type}>{type}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Specialty <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={formData.specialty}
                    onChange={(e) => setFormData({ ...formData, specialty: e.target.value })}
                    className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 appearance-none"
                    required
                  >
                    <option value="">Select specialty</option>
                    {specialties.map((specialty) => (
                      <option key={specialty} value={specialty}>{specialty}</option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          </section>

          {/* Location */}
          <section>
            <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
              <h2 className="mb-4">Location</h2>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-2">
                    Street Address <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    placeholder="123 Main Street"
                    className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors"
                    required
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-sm font-medium mb-2">
                      City <span className="text-rose-500">*</span>
                    </label>
                    <input
                      type="text"
                      value={formData.city}
                      onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                      placeholder="Cleveland"
                      className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors"
                      required
                    />
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

                <div>
                  <label className="block text-sm font-medium mb-2">
                    ZIP Code <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    maxLength={5}
                    value={formData.zipCode}
                    onChange={(e) => setFormData({ ...formData, zipCode: e.target.value.replace(/\D/g, '') })}
                    placeholder="44115"
                    className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors"
                    required
                  />
                </div>
              </div>
            </div>
          </section>

          {/* Contact Information (Optional) */}
          <section>
            <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
              <h2 className="mb-2">Contact Information (Optional)</h2>
              <p className="text-xs text-gray-500 mb-4">Help others contact this provider</p>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-2">Phone Number</label>
                  <input
                    type="tel"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    placeholder="(216) 555-0100"
                    className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">Email</label>
                  <input
                    type="email"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    placeholder="office@provider.com"
                    className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">Website</label>
                  <input
                    type="url"
                    value={formData.website}
                    onChange={(e) => setFormData({ ...formData, website: e.target.value })}
                    placeholder="www.provider.com"
                    className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors"
                  />
                </div>
              </div>
            </div>
          </section>

          {/* Additional Notes */}
          <section>
            <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
              <h2 className="mb-2">Additional Notes (Optional)</h2>
              <p className="text-xs text-gray-500 mb-4">
                Share anything that might be helpful for other mothers
              </p>

              <textarea
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                rows={4}
                placeholder="Example: Accepts Medicaid, Spanish-speaking staff, evening appointments available..."
                className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 focus:bg-white transition-colors resize-none"
              ></textarea>
            </div>
          </section>

          {/* Moderation Notice */}
          <div className="bg-gradient-to-br from-amber-50 to-orange-50 rounded-2xl p-4 border border-amber-100">
            <p className="text-sm text-gray-700">
              <strong>Moderation process:</strong> All provider submissions are reviewed by our team to ensure accuracy and prevent spam. This usually takes 1-2 business days.
            </p>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={!canSubmit}
            className={`w-full py-4 px-4 rounded-2xl transition-colors shadow-sm ${
              canSubmit
                ? "bg-[#663399] text-white hover:bg-[#552288]"
                : "bg-gray-200 text-gray-400 cursor-not-allowed"
            }`}
          >
            Submit for Review
          </button>
        </form>
      </div>
    </div>
  );
}
