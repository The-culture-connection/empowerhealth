import { Upload, ExternalLink, Calendar } from "lucide-react";
import { useState } from "react";

export function Documentation() {
  const [activeTab, setActiveTab] = useState<"privacy" | "terms" | "support">("privacy");

  const documents = [
    {
      title: "Privacy Policy",
      description: "User data protection and privacy guidelines",
      lastUpdated: "February 15, 2026",
    },
    {
      title: "Terms & Conditions",
      description: "Platform usage terms and legal agreements",
      lastUpdated: "January 10, 2026",
    },
    {
      title: "Contact / Support",
      description: "Help resources and support contact information",
      lastUpdated: "February 28, 2026",
    },
  ];

  return (
    <div className="p-8">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl mb-2" style={{ color: 'var(--warm-600)' }}>
            Documentation
          </h1>
          <p style={{ color: 'var(--warm-400)' }}>
            Manage platform documentation and legal resources
          </p>
        </div>

        {/* Tab Navigation */}
        <div className="flex gap-2 mb-6 border-b" style={{ borderColor: 'var(--lavender-200)' }}>
          <button
            onClick={() => setActiveTab("privacy")}
            className={`px-6 py-3 transition-all border-b-2 ${
              activeTab === "privacy" ? "border-lavender-500" : "border-transparent"
            }`}
            style={{
              color: activeTab === "privacy" ? 'var(--lavender-600)' : 'var(--warm-500)',
              borderBottomColor: activeTab === "privacy" ? 'var(--lavender-500)' : 'transparent',
            }}
          >
            Privacy Policy
          </button>
          <button
            onClick={() => setActiveTab("terms")}
            className={`px-6 py-3 transition-all border-b-2 ${
              activeTab === "terms" ? "border-lavender-500" : "border-transparent"
            }`}
            style={{
              color: activeTab === "terms" ? 'var(--lavender-600)' : 'var(--warm-500)',
              borderBottomColor: activeTab === "terms" ? 'var(--lavender-500)' : 'transparent',
            }}
          >
            Terms & Conditions
          </button>
          <button
            onClick={() => setActiveTab("support")}
            className={`px-6 py-3 transition-all border-b-2 ${
              activeTab === "support" ? "border-lavender-500" : "border-transparent"
            }`}
            style={{
              color: activeTab === "support" ? 'var(--lavender-600)' : 'var(--warm-500)',
              borderBottomColor: activeTab === "support" ? 'var(--lavender-500)' : 'transparent',
            }}
          >
            Contact / Support
          </button>
        </div>

        {/* Tab Content */}
        <div
          className="p-8 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: 'var(--lavender-200)',
          }}
        >
          {/* Privacy Policy Tab */}
          {activeTab === "privacy" && (
            <div>
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h2 className="mb-2" style={{ color: 'var(--warm-600)' }}>
                    Privacy Policy
                  </h2>
                  <div className="flex items-center gap-2 text-sm" style={{ color: 'var(--warm-400)' }}>
                    <Calendar className="w-4 h-4" />
                    <span>Last updated: February 15, 2026</span>
                  </div>
                </div>
                <button
                  className="flex items-center gap-2 px-4 py-2 rounded-xl transition-all hover:shadow-sm"
                  style={{
                    backgroundColor: 'var(--lavender-200)',
                    color: 'var(--lavender-600)',
                  }}
                >
                  <Upload className="w-4 h-4" />
                  Update Document
                </button>
              </div>

              <div className="prose max-w-none space-y-4" style={{ color: 'var(--warm-600)' }}>
                <h3>1. Introduction</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  At EmpowerHealth, we are committed to protecting your privacy and ensuring the security of your personal health information. This Privacy Policy explains how we collect, use, and safeguard your data as you use our maternal health platform.
                </p>

                <h3>2. Information We Collect</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  We collect information that you provide directly to us, including:
                </p>
                <ul style={{ color: 'var(--warm-500)' }}>
                  <li>Account information (name, email address, password)</li>
                  <li>Pregnancy journey data (due date, trimester, milestones)</li>
                  <li>Health preferences and birth plan information</li>
                  <li>Journal entries and reflections</li>
                  <li>After visit summaries and appointment notes</li>
                </ul>

                <h3>3. How We Use Your Information</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  Your information is used to:
                </p>
                <ul style={{ color: 'var(--warm-500)' }}>
                  <li>Provide personalized maternal health education and support</li>
                  <li>Track your pregnancy journey and milestones</li>
                  <li>Generate anonymized research data to improve maternal health outcomes</li>
                  <li>Send you relevant notifications and reminders</li>
                  <li>Connect you with appropriate healthcare providers</li>
                </ul>

                <h3>4. Data Security</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  We implement industry-standard security measures to protect your data, including encryption, secure servers, and regular security audits. All data is HIPAA compliant and stored in secure, certified facilities.
                </p>

                <h3>5. Data Sharing</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  We do not sell your personal information. Anonymized data may be shared with research partners for the purpose of improving maternal health outcomes. You have full control over your data sharing preferences in your account settings.
                </p>

                <h3>6. Your Rights</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  You have the right to access, update, or delete your personal information at any time. You may also opt out of data collection for research purposes while continuing to use the platform.
                </p>
              </div>
            </div>
          )}

          {/* Terms & Conditions Tab */}
          {activeTab === "terms" && (
            <div>
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h2 className="mb-2" style={{ color: 'var(--warm-600)' }}>
                    Terms & Conditions
                  </h2>
                  <div className="flex items-center gap-2 text-sm" style={{ color: 'var(--warm-400)' }}>
                    <Calendar className="w-4 h-4" />
                    <span>Last updated: January 10, 2026</span>
                  </div>
                </div>
                <button
                  className="flex items-center gap-2 px-4 py-2 rounded-xl transition-all hover:shadow-sm"
                  style={{
                    backgroundColor: 'var(--lavender-200)',
                    color: 'var(--lavender-600)',
                  }}
                >
                  <Upload className="w-4 h-4" />
                  Update Document
                </button>
              </div>

              <div className="prose max-w-none space-y-4" style={{ color: 'var(--warm-600)' }}>
                <h3>1. Acceptance of Terms</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  By accessing and using EmpowerHealth, you accept and agree to be bound by the terms and conditions of this agreement. If you do not agree to these terms, please do not use our platform.
                </p>

                <h3>2. Platform Purpose</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  EmpowerHealth is designed to provide educational resources, support tools, and community connection for expecting and new parents. Our platform is not a substitute for professional medical advice, diagnosis, or treatment.
                </p>

                <h3>3. User Responsibilities</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  As a user, you agree to:
                </p>
                <ul style={{ color: 'var(--warm-500)' }}>
                  <li>Provide accurate and complete information</li>
                  <li>Maintain the confidentiality of your account credentials</li>
                  <li>Use the platform in a respectful and appropriate manner</li>
                  <li>Not share medical advice or misrepresent professional credentials</li>
                  <li>Respect the privacy and experiences of other community members</li>
                </ul>

                <h3>4. Medical Disclaimer</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  The content provided on EmpowerHealth is for informational purposes only. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition. Never disregard professional medical advice or delay in seeking it because of something you have read on this platform.
                </p>

                <h3>5. Community Guidelines</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  Our community spaces are designed to be supportive and inclusive. We do not tolerate harassment, discrimination, spam, or inappropriate content. Violations may result in account suspension or termination.
                </p>

                <h3>6. Intellectual Property</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  All content, features, and functionality on EmpowerHealth are owned by us or our licensors and are protected by copyright, trademark, and other intellectual property laws.
                </p>

                <h3>7. Limitation of Liability</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  EmpowerHealth and its affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the platform.
                </p>

                <h3>8. Changes to Terms</h3>
                <p style={{ color: 'var(--warm-500)' }}>
                  We reserve the right to modify these terms at any time. We will notify users of any material changes via email or platform notification. Continued use of the platform after changes constitutes acceptance of the new terms.
                </p>
              </div>
            </div>
          )}

          {/* Contact / Support Tab */}
          {activeTab === "support" && (
            <div>
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h2 className="mb-2" style={{ color: 'var(--warm-600)' }}>
                    Contact & Support
                  </h2>
                  <div className="flex items-center gap-2 text-sm" style={{ color: 'var(--warm-400)' }}>
                    <Calendar className="w-4 h-4" />
                    <span>Last updated: February 28, 2026</span>
                  </div>
                </div>
                <button
                  className="flex items-center gap-2 px-4 py-2 rounded-xl transition-all hover:shadow-sm"
                  style={{
                    backgroundColor: 'var(--lavender-200)',
                    color: 'var(--lavender-600)',
                  }}
                >
                  <Upload className="w-4 h-4" />
                  Update Document
                </button>
              </div>

              <div className="space-y-6">
                {/* Support Channels */}
                <div>
                  <h3 className="mb-4" style={{ color: 'var(--warm-600)' }}>
                    Get Help
                  </h3>
                  <div className="grid gap-4 md:grid-cols-2">
                    <div
                      className="p-6 rounded-xl border"
                      style={{
                        backgroundColor: 'var(--lavender-50)',
                        borderColor: 'var(--lavender-200)',
                      }}
                    >
                      <h4 className="mb-2" style={{ color: 'var(--lavender-600)' }}>
                        Email Support
                      </h4>
                      <p className="text-sm mb-3" style={{ color: 'var(--warm-500)' }}>
                        For general inquiries and technical support
                      </p>
                      <a
                        href="mailto:support@empowerhealth.org"
                        className="text-sm"
                        style={{ color: 'var(--lavender-600)' }}
                      >
                        support@empowerhealth.org
                      </a>
                      <p className="text-xs mt-2" style={{ color: 'var(--warm-400)' }}>
                        Response time: 24-48 hours
                      </p>
                    </div>

                    <div
                      className="p-6 rounded-xl border"
                      style={{
                        backgroundColor: 'var(--lavender-50)',
                        borderColor: 'var(--lavender-200)',
                      }}
                    >
                      <h4 className="mb-2" style={{ color: 'var(--lavender-600)' }}>
                        Research Inquiries
                      </h4>
                      <p className="text-sm mb-3" style={{ color: 'var(--warm-500)' }}>
                        For partnership and research collaboration
                      </p>
                      <a
                        href="mailto:research@empowerhealth.org"
                        className="text-sm"
                        style={{ color: 'var(--lavender-600)' }}
                      >
                        research@empowerhealth.org
                      </a>
                      <p className="text-xs mt-2" style={{ color: 'var(--warm-400)' }}>
                        Response time: 3-5 business days
                      </p>
                    </div>
                  </div>
                </div>

                {/* Office Hours */}
                <div>
                  <h3 className="mb-4" style={{ color: 'var(--warm-600)' }}>
                    Office Hours
                  </h3>
                  <div
                    className="p-6 rounded-xl border"
                    style={{
                      backgroundColor: 'white',
                      borderColor: 'var(--lavender-200)',
                    }}
                  >
                    <p className="mb-3" style={{ color: 'var(--warm-500)' }}>
                      Our support team is available:
                    </p>
                    <ul className="space-y-2" style={{ color: 'var(--warm-600)' }}>
                      <li>Monday - Friday: 9:00 AM - 6:00 PM EST</li>
                      <li>Saturday: 10:00 AM - 4:00 PM EST</li>
                      <li>Sunday: Closed</li>
                    </ul>
                    <p className="text-sm mt-4" style={{ color: 'var(--warm-400)' }}>
                      For urgent technical issues outside office hours, please email with "URGENT" in the subject line.
                    </p>
                  </div>
                </div>

                {/* FAQ & Resources */}
                <div>
                  <h3 className="mb-4" style={{ color: 'var(--warm-600)' }}>
                    Additional Resources
                  </h3>
                  <div className="space-y-3">
                    <a
                      href="#"
                      className="flex items-center justify-between p-4 rounded-xl border hover:shadow-md transition-shadow"
                      style={{
                        backgroundColor: 'white',
                        borderColor: 'var(--lavender-200)',
                      }}
                    >
                      <div>
                        <h4 className="mb-1" style={{ color: 'var(--warm-600)' }}>
                          Frequently Asked Questions
                        </h4>
                        <p className="text-sm" style={{ color: 'var(--warm-400)' }}>
                          Find answers to common questions
                        </p>
                      </div>
                      <ExternalLink className="w-5 h-5" style={{ color: 'var(--warm-400)' }} />
                    </a>

                    <a
                      href="#"
                      className="flex items-center justify-between p-4 rounded-xl border hover:shadow-md transition-shadow"
                      style={{
                        backgroundColor: 'white',
                        borderColor: 'var(--lavender-200)',
                      }}
                    >
                      <div>
                        <h4 className="mb-1" style={{ color: 'var(--warm-600)' }}>
                          User Guide
                        </h4>
                        <p className="text-sm" style={{ color: 'var(--warm-400)' }}>
                          Learn how to use platform features
                        </p>
                      </div>
                      <ExternalLink className="w-5 h-5" style={{ color: 'var(--warm-400)' }} />
                    </a>

                    <a
                      href="#"
                      className="flex items-center justify-between p-4 rounded-xl border hover:shadow-md transition-shadow"
                      style={{
                        backgroundColor: 'white',
                        borderColor: 'var(--lavender-200)',
                      }}
                    >
                      <div>
                        <h4 className="mb-1" style={{ color: 'var(--warm-600)' }}>
                          Community Guidelines
                        </h4>
                        <p className="text-sm" style={{ color: 'var(--warm-400)' }}>
                          Best practices for community interaction
                        </p>
                      </div>
                      <ExternalLink className="w-5 h-5" style={{ color: 'var(--warm-400)' }} />
                    </a>
                  </div>
                </div>

                {/* Emergency Notice */}
                <div
                  className="p-6 rounded-xl border"
                  style={{
                    backgroundColor: '#fef3c7',
                    borderColor: '#fbbf24',
                  }}
                >
                  <h4 className="mb-2" style={{ color: '#92400e' }}>
                    Medical Emergency
                  </h4>
                  <p style={{ color: '#92400e' }}>
                    If you are experiencing a medical emergency, please call 911 or go to your nearest emergency room immediately. EmpowerHealth is not equipped to handle medical emergencies.
                  </p>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}