import { ArrowLeft, MapPin, Star, Phone, Clock, Award, Shield, Info, Bookmark, Mail, Globe, ThumbsUp, Calendar, Heart, AlertCircle, CheckCircle2, Flag, MessageCircle, Share2, Navigation, Video, DollarSign, Users, Stethoscope, GraduationCap, Languages, Building } from "lucide-react";
import { Link } from "react-router";
import { useState } from "react";

export function ProviderDetailProfile() {
  const [isSaved, setIsSaved] = useState(false);
  const [showMamaApprovedInfo, setShowMamaApprovedInfo] = useState(false);
  const [activeTab, setActiveTab] = useState<"overview" | "reviews" | "about">("overview");

  const provider = {
    id: "1",
    name: "Dr. Aisha Williams",
    credentials: "MD, OB-GYN, FACOG",
    title: "Maternal-Fetal Medicine Specialist",
    specialty: "Maternal-Fetal Medicine",
    practice: "Cleveland Clinic Women's Health Center",
    address: "9500 Euclid Ave, Cleveland, OH 44195",
    city: "Cleveland",
    state: "OH",
    zipCode: "44195",
    distance: "4.2 miles",
    phone: "(216) 444-6601",
    email: "williams.a@ccf.org",
    website: "clevelandclinic.org/womenshealth",
    mamaApproved: true,
    rating: 4.9,
    reviewCount: 127,
    acceptingNew: true,
    telehealth: true,
    hours: {
      monday: "8:00 AM - 5:00 PM",
      tuesday: "8:00 AM - 5:00 PM",
      wednesday: "8:00 AM - 5:00 PM",
      thursday: "8:00 AM - 7:00 PM",
      friday: "8:00 AM - 4:00 PM",
      saturday: "Closed",
      sunday: "Closed"
    },
    languages: ["English", "Spanish", "French"],
    yearsOfExperience: 15,
    education: [
      "MD - Case Western Reserve University School of Medicine",
      "Residency - OB-GYN, Cleveland Clinic",
      "Fellowship - Maternal-Fetal Medicine, Ohio State University"
    ],
    certifications: [
      "Board Certified in Obstetrics & Gynecology",
      "Maternal-Fetal Medicine Subspecialty Certification",
      "Fellow, American College of Obstetricians and Gynecologists (FACOG)",
      "Cultural Competency in Healthcare Certificate"
    ],
    insurance: [
      "Medicaid (All Ohio Plans)",
      "Buckeye Health Plan",
      "CareSource",
      "Molina Healthcare",
      "UnitedHealthcare Community Plan",
      "Medicare",
      "Aetna",
      "Anthem Blue Cross Blue Shield",
      "Humana",
      "Most major private insurances"
    ],
    specialties: [
      "High-Risk Pregnancy Management",
      "VBAC Support & Counseling",
      "Gestational Diabetes Care",
      "Hypertension Management",
      "Multiple Pregnancy Care",
      "Genetic Counseling",
      "Fetal Monitoring",
      "Preterm Labor Prevention"
    ],
    identityTags: [
      { 
        label: "Black / African American", 
        status: "verified", 
        source: "Self-identified", 
        verifiedBy: "Professional credential",
        date: "January 2024",
        addedBy: "Provider"
      },
      { 
        label: "Cultural competency certified", 
        status: "verified", 
        source: "Professional credential", 
        verifiedBy: "Cleveland Clinic HR",
        date: "March 2023",
        addedBy: "Institution"
      },
      { 
        label: "LGBTQ+ affirming", 
        status: "verified", 
        source: "Community-added", 
        verifiedBy: "Multiple patient confirmations",
        date: "November 2025",
        addedBy: "Community (12 confirmations)"
      },
      { 
        label: "Spanish-speaking", 
        status: "verified", 
        source: "Self-identified", 
        verifiedBy: "Language proficiency test",
        date: "January 2024",
        addedBy: "Provider"
      },
      { 
        label: "Birth trauma informed", 
        status: "pending", 
        source: "Community-added", 
        verifiedBy: "Awaiting provider confirmation",
        date: "February 2026",
        addedBy: "Community (3 suggestions)"
      }
    ],
    experienceRatings: {
      feltHeard: 4.9,
      feltRespected: 5.0,
      explainedClearly: 4.8,
      wouldRecommend: 98
    },
    reviews: [
      {
        id: "1",
        author: "Jasmine M.",
        verified: true,
        date: "2 weeks ago",
        rating: 5,
        feltHeard: 5,
        feltRespected: 5,
        explainedClearly: 5,
        wouldRecommend: true,
        text: "Dr. Williams took the time to listen to all my concerns and made me feel truly heard. She respected my birth plan and was so supportive throughout my high-risk pregnancy. As a Black mother, I felt she understood the unique challenges I faced and advocated fiercely for me and my baby. I can't recommend her enough!",
        helpful: 45,
        responses: 12
      },
      {
        id: "2",
        author: "Keisha R.",
        verified: true,
        date: "1 month ago",
        rating: 5,
        feltHeard: 5,
        feltRespected: 5,
        explainedClearly: 5,
        wouldRecommend: true,
        text: "Finally found a provider who understands the unique challenges Black mothers face in healthcare. Dr. Williams is knowledgeable, compassionate, and advocates fiercely for her patients. She took my concerns about preeclampsia seriously from day one and monitored me closely. I felt safe and respected throughout my entire pregnancy journey.",
        helpful: 38,
        responses: 8
      },
      {
        id: "3",
        author: "Maria S.",
        verified: true,
        date: "2 months ago",
        rating: 5,
        feltHeard: 4,
        feltRespected: 5,
        explainedClearly: 5,
        wouldRecommend: true,
        text: "Dr. Williams helped me navigate my gestational diabetes with patience and clear explanations. She spoke Spanish with me which made me feel so much more comfortable. I felt safe and cared for throughout my entire pregnancy. The office staff is also wonderful!",
        helpful: 29,
        responses: 5
      },
      {
        id: "4",
        author: "Anonymous",
        verified: true,
        date: "3 months ago",
        rating: 5,
        feltHeard: 5,
        feltRespected: 5,
        explainedClearly: 4,
        wouldRecommend: true,
        text: "After a traumatic first birth experience, I was anxious about trying for a VBAC. Dr. Williams was incredibly supportive and helped me understand all my options without any pressure. She respected my choices and made me feel empowered. I had a successful VBAC thanks to her guidance!",
        helpful: 34,
        responses: 6
      },
      {
        id: "5",
        author: "Destiny L.",
        verified: true,
        date: "4 months ago",
        rating: 5,
        feltHeard: 5,
        feltRespected: 5,
        explainedClearly: 5,
        wouldRecommend: true,
        text: "Dr. Williams is phenomenal. She treated me like family and explained everything in terms I could understand. Never felt rushed or dismissed. She's the kind of doctor every pregnant person deserves!",
        helpful: 41,
        responses: 9
      }
    ],
    clinicalInterests: [
      "Maternal health equity",
      "Reducing maternal mortality in Black communities",
      "Patient-centered birth planning",
      "Trauma-informed obstetric care"
    ],
    hospitalAffiliations: [
      "Cleveland Clinic Main Campus",
      "Cleveland Clinic Hillcrest Hospital",
      "Cleveland Clinic Fairview Hospital"
    ],
    awards: [
      "Top Doctor - Cleveland Magazine 2025",
      "Patient's Choice Award 2024",
      "Compassionate Care Award - Cleveland Clinic 2023"
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
          <div className="flex items-center gap-2">
            <button className="p-2 rounded-xl bg-gray-50 text-gray-600 hover:bg-gray-100 transition-colors">
              <Share2 className="w-5 h-5" />
            </button>
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
      </div>

      <div className="px-5 py-5">
        {/* Provider Hero Card */}
        <section className="mb-4">
          <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] rounded-3xl p-6 text-white shadow-lg">
            <div className="flex items-start gap-4 mb-4">
              {/* Provider Avatar */}
              <div className="w-20 h-20 rounded-2xl bg-white/20 backdrop-blur-sm flex items-center justify-center text-3xl font-medium flex-shrink-0 border-2 border-white/30">
                AW
              </div>
              
              <div className="flex-1">
                <h1 className="text-2xl mb-1">{provider.name}</h1>
                <p className="text-white/90 text-sm mb-0.5">{provider.credentials}</p>
                <p className="text-white/80 text-sm">{provider.title}</p>
                
                {/* Mama Approved Badge */}
                {provider.mamaApproved && (
                  <button
                    onClick={() => setShowMamaApprovedInfo(!showMamaApprovedInfo)}
                    className="mt-3 inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/20 border border-white/30 hover:bg-white/30 transition-colors"
                  >
                    <Award className="w-4 h-4" />
                    <span className="text-sm font-medium">Mama Approved™</span>
                    <Info className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>
            </div>

            {showMamaApprovedInfo && (
              <div className="mt-4 p-4 bg-white/10 rounded-2xl border border-white/20 backdrop-blur-sm">
                <p className="text-sm text-white/90 mb-2">
                  <strong>Mama Approved™</strong> is a community experience-based trust indicator, not a medical certification.
                </p>
                <p className="text-xs text-white/80">
                  This provider has received consistently positive reviews from mothers in our community, with high ratings for feeling heard, respected, and supported during their pregnancy journey.
                </p>
              </div>
            )}

            {/* Rating Summary */}
            <div className="flex items-center gap-4 mt-4 pt-4 border-t border-white/20">
              <div className="flex items-center gap-2">
                <Star className="w-6 h-6 fill-white text-white" />
                <div>
                  <div className="text-2xl font-medium">{provider.rating}</div>
                  <div className="text-xs text-white/80">Rating</div>
                </div>
              </div>
              <div className="h-12 w-px bg-white/20"></div>
              <div>
                <div className="text-2xl font-medium">{provider.reviewCount}</div>
                <div className="text-xs text-white/80">Reviews</div>
              </div>
              <div className="h-12 w-px bg-white/20"></div>
              <div>
                <div className="text-2xl font-medium">{provider.yearsOfExperience}</div>
                <div className="text-xs text-white/80">Years</div>
              </div>
            </div>
          </div>
        </section>

        {/* Quick Action Buttons */}
        <section className="mb-4">
          <div className="grid grid-cols-3 gap-3">
            <a
              href={`tel:${provider.phone}`}
              className="py-3 px-4 rounded-2xl bg-[#663399] text-white text-sm hover:bg-[#552288] transition-colors shadow-sm flex flex-col items-center justify-center gap-1"
            >
              <Phone className="w-5 h-5" />
              <span className="text-xs">Call</span>
            </a>
            <button className="py-3 px-4 rounded-2xl bg-white border border-gray-200 text-gray-700 text-sm hover:border-[#663399]/30 transition-colors flex flex-col items-center justify-center gap-1">
              <Calendar className="w-5 h-5" />
              <span className="text-xs">Book</span>
            </button>
            <button className="py-3 px-4 rounded-2xl bg-white border border-gray-200 text-gray-700 text-sm hover:border-[#663399]/30 transition-colors flex flex-col items-center justify-center gap-1">
              <MessageCircle className="w-5 h-5" />
              <span className="text-xs">Message</span>
            </button>
          </div>
        </section>

        {/* Status Chips */}
        <section className="mb-4">
          <div className="flex flex-wrap gap-2">
            {provider.acceptingNew && (
              <span className="px-3 py-1.5 rounded-full text-xs bg-green-50 text-green-700 border border-green-200 flex items-center gap-1.5">
                <CheckCircle2 className="w-3.5 h-3.5" />
                Accepting new patients
              </span>
            )}
            {provider.telehealth && (
              <span className="px-3 py-1.5 rounded-full text-xs bg-blue-50 text-blue-700 border border-blue-200 flex items-center gap-1.5">
                <Video className="w-3.5 h-3.5" />
                Telehealth available
              </span>
            )}
            <span className="px-3 py-1.5 rounded-full text-xs bg-purple-50 text-[#663399] border border-purple-200 flex items-center gap-1.5">
              <MapPin className="w-3.5 h-3.5" />
              {provider.distance} away
            </span>
          </div>
        </section>

        {/* Tab Navigation */}
        <section className="mb-4">
          <div className="bg-white rounded-2xl p-1 shadow-sm border border-gray-100 flex">
            <button
              onClick={() => setActiveTab("overview")}
              className={`flex-1 py-2.5 px-4 rounded-xl text-sm transition-colors ${
                activeTab === "overview"
                  ? "bg-[#663399] text-white shadow-sm"
                  : "text-gray-600 hover:text-gray-900"
              }`}
            >
              Overview
            </button>
            <button
              onClick={() => setActiveTab("reviews")}
              className={`flex-1 py-2.5 px-4 rounded-xl text-sm transition-colors ${
                activeTab === "reviews"
                  ? "bg-[#663399] text-white shadow-sm"
                  : "text-gray-600 hover:text-gray-900"
              }`}
            >
              Reviews ({provider.reviewCount})
            </button>
            <button
              onClick={() => setActiveTab("about")}
              className={`flex-1 py-2.5 px-4 rounded-xl text-sm transition-colors ${
                activeTab === "about"
                  ? "bg-[#663399] text-white shadow-sm"
                  : "text-gray-600 hover:text-gray-900"
              }`}
            >
              About
            </button>
          </div>
        </section>

        {/* Tab Content: Overview */}
        {activeTab === "overview" && (
          <>
            {/* Contact & Location */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <h2 className="mb-4">Contact & Location</h2>

                <div className="space-y-4">
                  <div className="flex items-start gap-3">
                    <MapPin className="w-5 h-5 text-[#663399] flex-shrink-0 mt-0.5" />
                    <div className="flex-1">
                      <p className="text-sm font-medium mb-0.5">{provider.practice}</p>
                      <p className="text-sm text-gray-600">{provider.address}</p>
                      <a
                        href={`https://maps.google.com/?q=${encodeURIComponent(provider.address)}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-xs text-[#663399] mt-2 hover:underline"
                      >
                        <Navigation className="w-3 h-3" />
                        Get directions
                      </a>
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
                </div>
              </div>
            </section>

            {/* Office Hours */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center gap-2 mb-4">
                  <Clock className="w-5 h-5 text-[#663399]" />
                  <h2>Office Hours</h2>
                </div>

                <div className="space-y-2">
                  {Object.entries(provider.hours).map(([day, hours]) => (
                    <div key={day} className="flex items-center justify-between text-sm">
                      <span className="capitalize text-gray-600">{day}</span>
                      <span className={hours === "Closed" ? "text-gray-400" : "text-gray-900"}>
                        {hours}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </section>

            {/* Identity & Cultural Tags */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-2">
                    <h2>Identity & Cultural Tags</h2>
                    <button className="text-[#663399]">
                      <Info className="w-4 h-4" />
                    </button>
                  </div>
                  <Link to={`/providers/${provider.id}/add-tag`} className="text-sm text-[#663399]">
                    + Add tag
                  </Link>
                </div>

                <div className="mb-4 p-4 bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl border border-blue-100">
                  <p className="text-xs text-gray-700 mb-2">
                    <strong>About identity tags:</strong> These help mothers find culturally concordant care and providers who understand their unique experiences.
                  </p>
                  <p className="text-xs text-gray-600">
                    Tags show their source and verification status for transparency. Community members can suggest tags, which are then reviewed by our team and the provider.
                  </p>
                </div>

                <div className="space-y-3">
                  {provider.identityTags.map((tag, index) => (
                    <div key={index} className={`p-4 rounded-2xl border ${getStatusColor(tag.status)}`}>
                      <div className="flex items-start justify-between mb-3">
                        <div className="flex items-center gap-2">
                          {getStatusIcon(tag.status)}
                          <span className="font-medium text-sm">{tag.label}</span>
                        </div>
                        <span className="text-xs px-2.5 py-1 rounded-full bg-white/70 capitalize font-medium">
                          {tag.status}
                        </span>
                      </div>
                      <div className="text-xs space-y-1 opacity-90">
                        <p><strong>Source:</strong> {tag.source}</p>
                        <p><strong>Verified by:</strong> {tag.verifiedBy}</p>
                        <p><strong>Added:</strong> {tag.date} by {tag.addedBy}</p>
                      </div>
                    </div>
                  ))}
                </div>

                <button className="mt-4 w-full py-2.5 px-4 rounded-2xl bg-gray-50 text-gray-700 text-sm border border-gray-200 hover:border-[#663399]/30 transition-colors flex items-center justify-center gap-2">
                  <Flag className="w-4 h-4" />
                  Report incorrect information
                </button>
              </div>
            </section>

            {/* Experience Ratings Summary */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <h2 className="mb-4">How Patients Feel</h2>
                
                <div className="space-y-4">
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm text-gray-700">Felt heard</span>
                      <span className="text-sm font-medium">{provider.experienceRatings.feltHeard}/5</span>
                    </div>
                    <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div 
                        className="h-full bg-gradient-to-r from-[#663399] to-[#8855bb] rounded-full"
                        style={{ width: `${(provider.experienceRatings.feltHeard / 5) * 100}%` }}
                      ></div>
                    </div>
                  </div>

                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm text-gray-700">Felt respected</span>
                      <span className="text-sm font-medium">{provider.experienceRatings.feltRespected}/5</span>
                    </div>
                    <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div 
                        className="h-full bg-gradient-to-r from-[#663399] to-[#8855bb] rounded-full"
                        style={{ width: `${(provider.experienceRatings.feltRespected / 5) * 100}%` }}
                      ></div>
                    </div>
                  </div>

                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm text-gray-700">Explained clearly</span>
                      <span className="text-sm font-medium">{provider.experienceRatings.explainedClearly}/5</span>
                    </div>
                    <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div 
                        className="h-full bg-gradient-to-r from-[#663399] to-[#8855bb] rounded-full"
                        style={{ width: `${(provider.experienceRatings.explainedClearly / 5) * 100}%` }}
                      ></div>
                    </div>
                  </div>

                  <div className="pt-3 border-t border-gray-100">
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-700">Would recommend</span>
                      <span className="text-lg font-medium text-green-600">{provider.experienceRatings.wouldRecommend}%</span>
                    </div>
                  </div>
                </div>
              </div>
            </section>

            {/* Specialties */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center gap-2 mb-4">
                  <Stethoscope className="w-5 h-5 text-[#663399]" />
                  <h2>Areas of Expertise</h2>
                </div>
                <div className="flex flex-wrap gap-2">
                  {provider.specialties.map((specialty, index) => (
                    <span key={index} className="px-3 py-2 rounded-2xl text-sm bg-purple-50 text-[#663399] border border-purple-100">
                      {specialty}
                    </span>
                  ))}
                </div>
              </div>
            </section>

            {/* Languages */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center gap-2 mb-4">
                  <Languages className="w-5 h-5 text-[#663399]" />
                  <h2>Languages Spoken</h2>
                </div>
                <div className="flex flex-wrap gap-2">
                  {provider.languages.map((language, index) => (
                    <span key={index} className="px-3 py-2 rounded-2xl text-sm bg-blue-50 text-blue-700 border border-blue-200">
                      {language}
                    </span>
                  ))}
                </div>
              </div>
            </section>

            {/* Insurance */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center gap-2 mb-4">
                  <Shield className="w-5 h-5 text-[#663399]" />
                  <h2>Insurance Accepted</h2>
                </div>
                <div className="space-y-2">
                  {provider.insurance.slice(0, 5).map((ins, index) => (
                    <div key={index} className="flex items-center gap-2">
                      <CheckCircle2 className="w-4 h-4 text-green-600" />
                      <span className="text-sm text-gray-700">{ins}</span>
                    </div>
                  ))}
                  {provider.insurance.length > 5 && (
                    <button className="text-sm text-[#663399] hover:underline">
                      + {provider.insurance.length - 5} more plans
                    </button>
                  )}
                </div>
              </div>
            </section>
          </>
        )}

        {/* Tab Content: Reviews */}
        {activeTab === "reviews" && (
          <>
            {/* Review Summary */}
            <section className="mb-4">
              <div className="bg-gradient-to-br from-[#fef3f3] to-[#fff0f8] rounded-3xl p-6 shadow-sm border border-pink-100">
                <div className="flex items-center gap-6 mb-6">
                  <div className="text-center">
                    <div className="text-5xl font-medium mb-2">{provider.rating}</div>
                    <div className="flex gap-1 mb-2">
                      {[...Array(5)].map((_, i) => (
                        <Star key={i} className="w-5 h-5 fill-amber-400 text-amber-400" />
                      ))}
                    </div>
                    <p className="text-sm text-gray-600">{provider.reviewCount} reviews</p>
                  </div>
                  <div className="flex-1 space-y-2">
                    {[5, 4, 3, 2, 1].map((stars) => {
                      const percentage = stars === 5 ? 85 : stars === 4 ? 12 : 3;
                      return (
                        <div key={stars} className="flex items-center gap-2">
                          <span className="text-xs text-gray-600 w-8">{stars} ★</span>
                          <div className="flex-1 h-2 bg-white rounded-full overflow-hidden">
                            <div 
                              className="h-full bg-amber-400 rounded-full"
                              style={{ width: `${percentage}%` }}
                            ></div>
                          </div>
                          <span className="text-xs text-gray-600 w-10">{percentage}%</span>
                        </div>
                      );
                    })}
                  </div>
                </div>

                <Link
                  to={`/providers/${provider.id}/review`}
                  className="block w-full py-3 px-4 rounded-2xl bg-[#663399] text-white text-sm text-center hover:bg-[#552288] transition-colors"
                >
                  Write a review
                </Link>
              </div>
            </section>

            {/* Individual Reviews */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center justify-between mb-4">
                  <h2>Patient Reviews</h2>
                  <select className="text-xs px-3 py-1.5 rounded-xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20">
                    <option>Most recent</option>
                    <option>Highest rated</option>
                    <option>Most helpful</option>
                  </select>
                </div>

                <div className="space-y-4">
                  {provider.reviews.map((review, index) => (
                    <div key={review.id} className={`${index !== 0 ? 'pt-4 border-t border-gray-100' : ''}`}>
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
                                  className={`w-4 h-4 ${
                                    i < review.rating ? "fill-amber-400 text-amber-400" : "text-gray-300"
                                  }`}
                                />
                              ))}
                            </div>
                            <span className="text-xs text-gray-500">{review.date}</span>
                          </div>
                        </div>
                        {review.wouldRecommend && (
                          <span className="text-xs px-2 py-1 rounded-full bg-green-100 text-green-700 border border-green-200 whitespace-nowrap">
                            ✓ Recommends
                          </span>
                        )}
                      </div>

                      {/* Experience ratings mini bars */}
                      <div className="flex gap-3 mb-3 text-xs">
                        <div className="flex items-center gap-1">
                          <span className="text-gray-500">Heard:</span>
                          <span className="font-medium">{review.feltHeard}/5</span>
                        </div>
                        <div className="flex items-center gap-1">
                          <span className="text-gray-500">Respected:</span>
                          <span className="font-medium">{review.feltRespected}/5</span>
                        </div>
                        <div className="flex items-center gap-1">
                          <span className="text-gray-500">Clear:</span>
                          <span className="font-medium">{review.explainedClearly}/5</span>
                        </div>
                      </div>

                      <p className="text-sm text-gray-700 mb-3 leading-relaxed">{review.text}</p>
                      
                      <div className="flex items-center gap-4">
                        <button className="flex items-center gap-1 text-xs text-gray-500 hover:text-[#663399] transition-colors">
                          <ThumbsUp className="w-3.5 h-3.5" />
                          Helpful ({review.helpful})
                        </button>
                        <button className="flex items-center gap-1 text-xs text-gray-500 hover:text-[#663399] transition-colors">
                          <MessageCircle className="w-3.5 h-3.5" />
                          {review.responses} responses
                        </button>
                      </div>
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
          </>
        )}

        {/* Tab Content: About */}
        {activeTab === "about" && (
          <>
            {/* Education */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center gap-2 mb-4">
                  <GraduationCap className="w-5 h-5 text-[#663399]" />
                  <h2>Education & Training</h2>
                </div>
                <div className="space-y-3">
                  {provider.education.map((edu, index) => (
                    <div key={index} className="flex items-start gap-3">
                      <div className="w-2 h-2 rounded-full bg-[#663399] flex-shrink-0 mt-2"></div>
                      <p className="text-sm text-gray-700">{edu}</p>
                    </div>
                  ))}
                </div>
              </div>
            </section>

            {/* Certifications */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center gap-2 mb-4">
                  <Award className="w-5 h-5 text-[#663399]" />
                  <h2>Certifications</h2>
                </div>
                <div className="space-y-2">
                  {provider.certifications.map((cert, index) => (
                    <div key={index} className="flex items-start gap-2">
                      <CheckCircle2 className="w-4 h-4 text-[#663399] flex-shrink-0 mt-0.5" />
                      <p className="text-sm text-gray-700">{cert}</p>
                    </div>
                  ))}
                </div>
              </div>
            </section>

            {/* Clinical Interests */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center gap-2 mb-4">
                  <Heart className="w-5 h-5 text-[#663399]" />
                  <h2>Clinical Interests</h2>
                </div>
                <div className="flex flex-wrap gap-2">
                  {provider.clinicalInterests.map((interest, index) => (
                    <span key={index} className="px-3 py-2 rounded-2xl text-sm bg-rose-50 text-rose-700 border border-rose-200">
                      {interest}
                    </span>
                  ))}
                </div>
              </div>
            </section>

            {/* Hospital Affiliations */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center gap-2 mb-4">
                  <Building className="w-5 h-5 text-[#663399]" />
                  <h2>Hospital Affiliations</h2>
                </div>
                <div className="space-y-2">
                  {provider.hospitalAffiliations.map((hospital, index) => (
                    <div key={index} className="flex items-center gap-2">
                      <div className="w-2 h-2 rounded-full bg-[#663399]"></div>
                      <p className="text-sm text-gray-700">{hospital}</p>
                    </div>
                  ))}
                </div>
              </div>
            </section>

            {/* Awards & Recognition */}
            <section className="mb-4">
              <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
                <div className="flex items-center gap-2 mb-4">
                  <Award className="w-5 h-5 text-[#663399]" />
                  <h2>Awards & Recognition</h2>
                </div>
                <div className="space-y-3">
                  {provider.awards.map((award, index) => (
                    <div key={index} className="p-3 bg-gradient-to-br from-amber-50 to-orange-50 rounded-2xl border border-amber-200">
                      <p className="text-sm text-gray-700">{award}</p>
                    </div>
                  ))}
                </div>
              </div>
            </section>
          </>
        )}

        {/* Help Other Mothers CTA */}
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
