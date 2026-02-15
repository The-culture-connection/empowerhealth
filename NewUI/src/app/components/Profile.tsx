import { User, Calendar, Heart, Users, FileText, Shield, Bell, LogOut } from "lucide-react";

export function Profile() {
  return (
    <div className="p-5">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl mb-2">Your Profile</h1>
        <p className="text-gray-600">Manage your information and preferences</p>
      </div>

      {/* Profile Card */}
      <section className="mb-6">
        <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] rounded-3xl p-6 text-white shadow-md">
          <div className="flex items-start gap-4 mb-4">
            <div className="w-16 h-16 rounded-2xl bg-white/20 flex items-center justify-center text-2xl">
              S
            </div>
            <div className="flex-1">
              <h2 className="text-xl mb-1">Sarah Mitchell</h2>
              <p className="text-white/80 text-sm">sarah.mitchell@email.com</p>
              <p className="text-white/80 text-sm mt-2">Due Date: June 15, 2026</p>
            </div>
            <button className="text-white/90 text-sm">Edit</button>
          </div>
        </div>
      </section>

      {/* Pregnancy Information */}
      <section className="mb-6">
        <h2 className="mb-3">Pregnancy Details</h2>
        <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500 mb-1">Current Week</p>
                <p className="text-sm">Week 24 of 40</p>
              </div>
              <Calendar className="w-5 h-5 text-gray-400" />
            </div>
            <div className="h-px bg-gray-100"></div>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500 mb-1">Due Date</p>
                <p className="text-sm">June 15, 2026</p>
              </div>
            </div>
            <div className="h-px bg-gray-100"></div>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500 mb-1">Trimester</p>
                <p className="text-sm">Second Trimester</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Care Team */}
      <section className="mb-6">
        <h2 className="mb-3">My Care Team</h2>
        <div className="space-y-3">
          <div className="bg-white rounded-3xl p-4 shadow-sm border border-gray-100">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-2xl bg-blue-50 flex items-center justify-center flex-shrink-0">
                <User className="w-5 h-5 text-blue-500" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-0.5">Primary OB-GYN</h3>
                <p className="text-sm text-gray-600">Dr. Maria Johnson</p>
                <p className="text-xs text-gray-500 mt-1">Valley Health Center</p>
              </div>
              <button className="text-xs text-[#663399]">Edit</button>
            </div>
          </div>

          <button className="w-full bg-white rounded-3xl p-4 shadow-sm border border-gray-200 hover:border-[#663399]/30 transition-colors text-left">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-purple-50 flex items-center justify-center">
                <Users className="w-5 h-5 text-[#663399]" />
              </div>
              <span className="text-sm text-gray-600">+ Add Doula or Support Person</span>
            </div>
          </button>
        </div>
      </section>

      {/* Support System */}
      <section className="mb-6">
        <h2 className="mb-3">My Support System</h2>
        <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
          <div className="space-y-4">
            <div>
              <label className="text-sm text-gray-500 mb-2 block">Birth Partner</label>
              <input
                type="text"
                defaultValue="James Mitchell"
                className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20"
              />
            </div>
            <div>
              <label className="text-sm text-gray-500 mb-2 block">Emergency Contact</label>
              <input
                type="text"
                defaultValue="James Mitchell - (555) 123-4567"
                className="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Insurance */}
      <section className="mb-6">
        <h2 className="mb-3">Insurance Information</h2>
        <div className="bg-white rounded-3xl p-4 shadow-sm border border-gray-100">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-2xl bg-green-50 flex items-center justify-center flex-shrink-0">
              <Shield className="w-5 h-5 text-green-600" />
            </div>
            <div className="flex-1">
              <h3 className="text-sm mb-0.5">Blue Cross Blue Shield</h3>
              <p className="text-xs text-gray-500">Member ID: ****6789</p>
            </div>
            <button className="text-xs text-[#663399]">Edit</button>
          </div>
        </div>
      </section>

      {/* Preferences */}
      <section className="mb-6">
        <h2 className="mb-3">App Preferences</h2>
        <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-gray-400" />
                <div>
                  <p className="text-sm">Appointment Reminders</p>
                  <p className="text-xs text-gray-500">Get notified before visits</p>
                </div>
              </div>
              <button className="w-12 h-6 bg-[#663399] rounded-full relative">
                <span className="absolute right-1 top-1 w-4 h-4 bg-white rounded-full"></span>
              </button>
            </div>
            <div className="h-px bg-gray-100"></div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Heart className="w-5 h-5 text-gray-400" />
                <div>
                  <p className="text-sm">Daily Check-ins</p>
                  <p className="text-xs text-gray-500">Gentle emotional prompts</p>
                </div>
              </div>
              <button className="w-12 h-6 bg-[#663399] rounded-full relative">
                <span className="absolute right-1 top-1 w-4 h-4 bg-white rounded-full"></span>
              </button>
            </div>
            <div className="h-px bg-gray-100"></div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <FileText className="w-5 h-5 text-gray-400" />
                <div>
                  <p className="text-sm">Weekly Updates</p>
                  <p className="text-xs text-gray-500">Pregnancy milestones</p>
                </div>
              </div>
              <button className="w-12 h-6 bg-gray-200 rounded-full relative">
                <span className="absolute left-1 top-1 w-4 h-4 bg-white rounded-full"></span>
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Account Actions */}
      <section className="mb-6">
        <div className="space-y-3">
          <button className="w-full bg-white rounded-3xl p-4 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors flex items-center gap-3">
            <Shield className="w-5 h-5 text-gray-600" />
            <span className="text-sm text-gray-700">Privacy & Data</span>
          </button>
          <button className="w-full bg-white rounded-3xl p-4 shadow-sm border border-gray-100 hover:border-red-200 transition-colors flex items-center gap-3 text-red-600">
            <LogOut className="w-5 h-5" />
            <span className="text-sm">Sign Out</span>
          </button>
        </div>
      </section>

      {/* Research Participation */}
      <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-3xl p-5 shadow-sm border border-blue-100">
        <h3 className="mb-2">Help Improve Maternal Care</h3>
        <p className="text-sm text-gray-600 mb-3">
          Your anonymized feedback helps researchers understand and improve the pregnancy experience for all families.
        </p>
        <button className="text-sm text-[#663399]">Learn about research →</button>
      </div>
    </div>
  );
}
