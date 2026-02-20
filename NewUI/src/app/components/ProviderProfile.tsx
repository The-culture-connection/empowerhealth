import { ArrowLeft, MapPin, Star, Phone, Clock, Award, Shield, Info, Bookmark, Mail, Globe, ThumbsUp, Calendar, Heart, AlertCircle, CheckCircle2, Flag } from "lucide-react";
import { Link } from "react-router";
import { useState } from "react";

export function ProviderProfile() {
  const [isSaved, setIsSaved] = useState(false);
  const [showMamaApprovedInfo, setShowMamaApprovedInfo] = useState(false);
  const [showTagInfo, setShowTagInfo] = useState(false);

  const provider = {
    id: "1",
    name: "Dr. Aisha Williams",
    credentials: "MD, OB-GYN",
    specialty: "Maternal-Fetal Medicine",
    practice: "Cleveland Clinic Women's Health",
    address: "9500 Euclid Ave, Cleveland, OH 44195",
    city: "Cleveland, OH",
    distance: "4.2 miles",
    phone: "(216) 444-6601",
    email: "williams.a@ccf.org",
    website: "clevelandclinic.org",
    mamaApproved: true,
    rating: 4.9,
    reviewCount: 127,
    acceptingNew: true,
    telehealth: true,
    hours: "Mon-Fri 8:00 AM - 5:00 PM",
    languages: ["English", "Spanish"],
    education: "Case Western Reserve University School of Medicine",
    certifications: ["Board Certified in OB-GYN", "Maternal-Fetal Medicine Subspecialty"],
    insurance: ["Medicaid", "Buckeye Health Plan", "CareSource", "Medicare", "Most major insurances"],
    specialties: ["High-Risk Pregnancy", "VBAC Support", "Gestational Diabetes", "Hypertension Management"],
    identityTags: [
      { label: "Black / African American", status: "verified", source: "Self-identified", date: "Jan 2024" },
      { label: "Cultural competency certified", status: "verified", source: "Professional credential", date: "Mar 2023" },
      { label: "LGBTQ+ affirming", status: "pending", source: "Community-added", date: "Feb 2026" }
    ],
    reviews: [
      {
        author: "Jasmine M.",
        verified: true,
        date: "2 weeks ago",
        rating: 5,
        feltHeard: 5,
        feltRespected: 5,
        explainedClearly: 5,
        wouldRecommend: true,
        text: "Dr. Williams took the time to listen to all my concerns and made me feel truly heard. She respected my birth plan and was so supportive throughout my high-risk pregnancy.",
        helpful: 45
      },
      {
        author: "Keisha R.",
        verified: true,
        date: "1 month ago",
        rating: 5,
        feltHeard: 5,
        feltRespected: 5,
        explainedClearly: 5,
        wouldRecommend: true,
        text: "Finally found a provider who understands the unique challenges Black mothers face. She's knowledgeable, compassionate, and advocates fiercely for her patients.",
        helpful: 38
      },
      {
        author: "Maria S.",
        verified: true,
        date: "2 months ago",
        rating: 5,
        feltHeard: 4,
        feltRespected: 5,
        explainedClearly: 5,
        wouldRecommend: true,
        text: "Dr. Williams helped me navigate my gestational diabetes with patience and clear explanations. I felt safe and cared for throughout my entire pregnancy.",
        helpful: 29
      }
    ]
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "verified":
        return "text-green-700 bg-green-50 border-green-200";
      case "pending":
        return "text-amber-700 bg-amber-50 border-amber-200";
      case "disputed":
        return "text-gray-700 bg-gray-50 border-gray-300";
      default:
        return "text-gray-700 bg-gray-50 border-gray-200";
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "verified":
        return <CheckCircle2 className="w-4 h-4" />;
      case "pending":
        return <Clock className="w-4 h-4" />;
      case "disputed":
        return <AlertCircle className="w-4 h-4" />;
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] pb-24">
      {/* Header */}
      <div className="bg-white border-b border-gray-100 px-5 py-4 sticky top-0 z-10">
        <div className="flex items-center justify-between">
          <Link to="/providers/results" className="flex items-center gap-2 text-gray-600 hover:text-[#663399]">
            <ArrowLeft className="w-5 h-5" />
            <span className="text-sm">Back to results</span>
          </Link>
          <button
            onClick={() => setIsSaved(!isSaved)}
            className={`p-2 rounded-xl transition-colors ${
              isSaved ? "bg-[#663399] text-white" : "bg-gray-50 text-gray-400 hover:bg-gray-100"
            }`}
          >
            <Bookmark className="w-5 h-5" fill={isSaved ? "currentColor" : "none"} />
          </button>
        </div>
      </div>

      <div className="px-5 py-5">
        {/* Provider Header */}
        <section className="mb-4">
          <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] rounded-3xl p-6 text-white shadow-md">
            <div className="flex items-start justify-between mb-3">
              <div className="flex-1">
                <h1 className="text-2xl mb-1">{provider.name}</h1>
                <p className="text-white/90 text-sm mb-1">{provider.credentials}</p>
                <p className="text-white/80 text-sm">{provider.specialty}</p>
              </div>
              {provider.mamaApproved && (
                <button
                  onClick={() => setShowMamaApprovedInfo(!showMamaApprovedInfo)}
                  className="flex items-center gap-1 px-3 py-1.5 rounded-full bg-white/20 border border-white/30"
                >
                  <Award className="w-4 h-4" />
                  <span className="text-xs font-medium">Mama Approved™</span>
                  <Info className="w-3.5 h-3.5" />
                </button>
              )}
            </div>

            {showMamaApprovedInfo && (
              <div className="mt-4 p-4 bg-white/10 rounded-2xl border border-white/20 backdrop-blur-sm">
                <p className="text-sm text-white/90 mb-2">
                  <strong>Mama Approved™</strong> is a community experience-based trust indicator, not a medical certification.
                </p>
                <p className="text-xs text-white/80">
                  This provider has received consistently positive reviews from mothers in our community, with high ratings for feeling heard, respected, and supported.
                </p>
              </div>
            )}

            <div className="flex items-center gap-2 mt-4">
              <div className="flex items-center gap-1">
                <Star className="w-5 h-5 fill-white text-white" />
                <span className="text-lg font-medium">{provider.rating}</span>
              </div>
              <span className="text-white/80 text-sm">({provider.reviewCount} reviews)</span>
            </div>
          </div>
        </section>

        {/* Quick Actions */}
        <section className="mb-4">
          <div className="grid grid-cols-2 gap-3">
            <a
              href={`tel:${provider.phone}`}
              className="py-3 px-4 rounded-2xl bg-[#663399] text-white text-sm hover:bg-[#552288] transition-colors shadow-sm flex items-center justify-center gap-2"
            >
              <Phone className="w-4 h-4" />
              Call Now
            </a>
            <button className="py-3 px-4 rounded-2xl bg-white border border-gray-200 text-gray-700 text-sm hover:border-[#663399]/30 transition-colors flex items-center justify-center gap-2">
              <Calendar className="w-4 h-4" />
              Book Appointment
            </button>
          </div>
        </section>

        {/* Contact Information */}
        <section className="mb-4">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <h2 className="mb-4">Contact & Location</h2>

            <div className="space-y-4">
              <div className="flex items-start gap-3">
                <MapPin className="w-5 h-5 text-[#663399] flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <p className="text-sm font-medium mb-0.5">{provider.practice}</p>
                  <p className="text-sm text-gray-600">{provider.address}</p>
                  <p className="text-xs text-[#663399] mt-1">{provider.distance} away</p>
                </div>
              </div>

              <div className="h-px bg-gray-100"></div>

              <div className="flex items-center gap-3">
                <Phone className="w-5 h-5 text-[#663399]" />
                <a href={`tel:${provider.phone}`} className="text-sm text-gray-700 hover:text-[#663399]">
                  {provider.phone}
                </a>
              </div>

              <div className="h-px bg-gray-100"></div>

              <div className="flex items-center gap-3">
                <Mail className="w-5 h-5 text-[#663399]" />
                <a href={`mailto:${provider.email}`} className="text-sm text-gray-700 hover:text-[#663399]">
                  {provider.email}
                </a>
              </div>

              <div className="h-px bg-gray-100"></div>

              <div className="flex items-center gap-3">
                <Globe className="w-5 h-5 text-[#663399]" />
                <a href={`https://${provider.website}`} target="_blank" rel="noopener noreferrer" className="text-sm text-gray-700 hover:text-[#663399]">
                  {provider.website}
                </a>
              </div>

              <div className="h-px bg-gray-100"></div>

              <div className="flex items-start gap-3">
                <Clock className="w-5 h-5 text-[#663399] flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-sm text-gray-700">{provider.hours}</p>
                  {provider.acceptingNew && (
                    <span className="inline-block mt-1 text-xs px-2 py-0.5 rounded-full bg-green-50 text-green-700 border border-green-200">
                      ✓ Accepting new patients
                    </span>
                  )}
                  {provider.telehealth && (
                    <span className="inline-block mt-1 ml-2 text-xs px-2 py-0.5 rounded-full bg-blue-50 text-blue-700 border border-blue-200">
                      Telehealth available
                    </span>
                  )}
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Identity Tags with Transparency */}
        <section className="mb-4">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <h2>Identity & Cultural Tags</h2>
                <button
                  onClick={() => setShowTagInfo(!showTagInfo)}
                  className="text-[#663399]"
                >
                  <Info className="w-4 h-4" />
                </button>
              </div>
              <Link to={`/providers/${provider.id}/add-tag`} className="text-sm text-[#663399]">
                + Add tag
              </Link>
            </div>

            {showTagInfo && (
              <div className="mb-4 p-4 bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl border border-blue-100">
                <p className="text-sm text-gray-700 mb-2">
                  <strong>About identity tags:</strong> These help mothers find culturally concordant care.
                </p>
                <p className="text-xs text-gray-600">
                  Tags show their source and verification status for transparency. Community members can add tags, which are then reviewed by our team.
                </p>
              </div>
            )}

            <div className="space-y-3">
              {provider.identityTags.map((tag, index) => (
                <div key={index} className={`p-4 rounded-2xl border ${getStatusColor(tag.status)}`}>
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex items-center gap-2">
                      {getStatusIcon(tag.status)}
                      <span className="font-medium text-sm">{tag.label}</span>
                    </div>
                    <span className="text-xs px-2 py-0.5 rounded-full bg-white/50 capitalize">{tag.status}</span>
                  </div>
                  <div className="text-xs opacity-80">
                    <p><strong>Source:</strong> {tag.source}</p>
                    <p><strong>Added:</strong> {tag.date}</p>
                  </div>
                </div>
              ))}
            </div>

            <button className="mt-4 w-full py-2.5 px-4 rounded-2xl bg-gray-50 text-gray-700 text-sm border border-gray-200 hover:border-[#663399]/30 transition-colors flex items-center justify-center gap-2">
              <Flag className="w-4 h-4" />
              Report incorrect info
            </button>
          </div>
        </section>

        {/* About */}
        <section className="mb-4">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <h2 className="mb-4">About</h2>

            <div className="space-y-4">
              <div>
                <h3 className="text-sm font-medium mb-2">Specialties</h3>
                <div className="flex flex-wrap gap-2">
                  {provider.specialties.map((specialty, index) => (
                    <span key={index} className="px-3 py-1.5 rounded-2xl text-xs bg-purple-50 text-[#663399] border border-purple-100">
                      {specialty}
                    </span>
                  ))}
                </div>
              </div>

              <div>
                <h3 className="text-sm font-medium mb-2">Languages</h3>
                <div className="flex flex-wrap gap-2">
                  {provider.languages.map((language, index) => (
                    <span key={index} className="px-3 py-1.5 rounded-2xl text-xs bg-blue-50 text-blue-700 border border-blue-200">
                      {language}
                    </span>
                  ))}
                </div>
              </div>

              <div>
                <h3 className="text-sm font-medium mb-2">Education</h3>
                <p className="text-sm text-gray-600">{provider.education}</p>
              </div>

              <div>
                <h3 className="text-sm font-medium mb-2">Certifications</h3>
                <ul className="space-y-1">
                  {provider.certifications.map((cert, index) => (
                    <li key={index} className="text-sm text-gray-600 flex items-start gap-2">
                      <Shield className="w-4 h-4 text-[#663399] flex-shrink-0 mt-0.5" />
                      {cert}
                    </li>
                  ))}
                </ul>
              </div>

              <div>
                <h3 className="text-sm font-medium mb-2">Insurance Accepted</h3>
                <div className="flex flex-wrap gap-2">
                  {provider.insurance.map((ins, index) => (
                    <span key={index} className="px-3 py-1.5 rounded-2xl text-xs bg-green-50 text-green-700 border border-green-200">
                      {ins}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Reviews */}
        <section className="mb-4">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <h2>Patient Experiences ({provider.reviewCount})</h2>
              <Link to={`/providers/${provider.id}/review`} className="text-sm text-[#663399]">
                Add review
              </Link>
            </div>

            {/* Experience Ratings */}
            <div className="mb-6 p-4 bg-gradient-to-br from-[#fef3f3] to-[#fff0f8] rounded-2xl border border-pink-100">
              <h3 className="text-sm font-medium mb-3">Experience-Based Ratings</h3>
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Felt heard</span>
                  <div className="flex items-center gap-2">
                    <div className="flex gap-0.5">
                      {[...Array(5)].map((_, i) => (
                        <Star key={i} className="w-4 h-4 fill-amber-400 text-amber-400" />
                      ))}
                    </div>
                    <span className="text-sm font-medium">4.9</span>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Felt respected</span>
                  <div className="flex items-center gap-2">
                    <div className="flex gap-0.5">
                      {[...Array(5)].map((_, i) => (
                        <Star key={i} className="w-4 h-4 fill-amber-400 text-amber-400" />
                      ))}
                    </div>
                    <span className="text-sm font-medium">5.0</span>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Explained clearly</span>
                  <div className="flex items-center gap-2">
                    <div className="flex gap-0.5">
                      {[...Array(5)].map((_, i) => (
                        <Star key={i} className="w-4 h-4 fill-amber-400 text-amber-400" />
                      ))}
                    </div>
                    <span className="text-sm font-medium">4.9</span>
                  </div>
                </div>
                <div className="flex items-center justify-between pt-2 border-t border-pink-200">
                  <span className="text-sm text-gray-600">Would recommend</span>
                  <span className="text-sm font-medium text-green-600">98% Yes</span>
                </div>
              </div>
            </div>

            {/* Individual Reviews */}
            <div className="space-y-4">
              {provider.reviews.map((review, index) => (
                <div key={index} className="p-4 bg-gray-50 rounded-2xl">
                  <div className="flex items-start justify-between mb-2">
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-sm font-medium">{review.author}</span>
                        {review.verified && (
                          <span className="text-xs px-2 py-0.5 rounded-full bg-blue-100 text-blue-700 border border-blue-200">
                            Verified Patient
                          </span>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        <div className="flex gap-0.5">
                          {[...Array(5)].map((_, i) => (
                            <Star
                              key={i}
                              className={`w-3.5 h-3.5 ${
                                i < review.rating ? "fill-amber-400 text-amber-400" : "text-gray-300"
                              }`}
                            />
                          ))}
                        </div>
                        <span className="text-xs text-gray-500">{review.date}</span>
                      </div>
                    </div>
                    {review.wouldRecommend && (
                      <span className="text-xs px-2 py-1 rounded-full bg-green-100 text-green-700 border border-green-200">
                        ✓ Would recommend
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-gray-700 mb-3">{review.text}</p>
                  <button className="flex items-center gap-1 text-xs text-gray-500 hover:text-[#663399]">
                    <ThumbsUp className="w-3.5 h-3.5" />
                    Helpful ({review.helpful})
                  </button>
                </div>
              ))}
            </div>

            <Link
              to={`/providers/${provider.id}/reviews`}
              className="block mt-4 w-full py-3 px-4 rounded-2xl bg-gray-50 text-gray-700 text-sm text-center border border-gray-200 hover:border-[#663399]/30 transition-colors"
            >
              View all {provider.reviewCount} reviews
            </Link>
          </div>
        </section>

        {/* Community Note */}
        <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-3xl p-5 shadow-sm border border-blue-100">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-2xl bg-[#663399] flex items-center justify-center flex-shrink-0">
              <Heart className="w-5 h-5 text-white" />
            </div>
            <div>
              <h3 className="mb-2">Help Other Mothers</h3>
              <p className="text-sm text-gray-600 mb-3">
                Your experience matters. Share your story to help other mothers make informed decisions about their care.
              </p>
              <Link to={`/providers/${provider.id}/review`} className="text-sm text-[#663399] font-medium">
                Write a review →
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
