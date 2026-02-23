import { User, Calendar, Heart, Users, FileText, Shield, Bell, LogOut, Sparkles } from "lucide-react";
import { PrivacySettings } from "./PrivacyComponents";
import { useState } from "react";

export function Profile() {
  const [showPrivacy, setShowPrivacy] = useState(false);

  return (
    <div className="p-6 pb-24">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl mb-2 text-[#4a3f52] font-normal">Your profile</h1>
        <p className="text-[#8b7a95] font-light">Manage your information and preferences</p>
      </div>

      {/* Profile Card */}
      <section className="mb-8">
        <div className="bg-gradient-to-br from-[#ebe4f3] via-[#e0d5eb] to-[#e8dfe8] rounded-[32px] p-7 shadow-[0_4px_24px_rgba(0,0,0,0.06)] relative overflow-hidden">
          {/* Subtle background pattern */}
          <div className="absolute inset-0 opacity-5">
            <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-white blur-3xl"></div>
            <div className="absolute bottom-0 left-0 w-40 h-40 rounded-full bg-[#d4c5e0] blur-3xl"></div>
          </div>

          <div className="relative flex items-start gap-4 mb-4">
            <div className="w-16 h-16 rounded-[24px] bg-white/40 backdrop-blur-sm flex items-center justify-center text-2xl text-[#6b5c75] shadow-sm">
              S
            </div>
            <div className="flex-1">
              <h2 className="text-xl mb-1 text-[#4a3f52] font-normal">Sarah Mitchell</h2>
              <p className="text-[#6b5c75] text-sm font-light">sarah.mitchell@email.com</p>
              <p className="text-[#6b5c75] text-sm mt-2 font-light">Due date: June 15, 2026</p>
            </div>
            <button className="text-[#8b7a95] text-sm font-light hover:text-[#6b5c75] transition-colors">Edit</button>
          </div>
        </div>
      </section>

      {/* Pregnancy Information */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#6b5c75] font-normal text-base tracking-wide">Pregnancy details</h2>
        <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-[#a89cb5] mb-1 font-light">Current week</p>
                <p className="text-sm text-[#4a3f52] font-normal">Week 24 of 40</p>
              </div>
              <Calendar className="w-5 h-5 text-[#b5a8c2] stroke-[1.5]" />
            </div>
            <div className="h-px bg-[#ede7f3]/60"></div>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-[#a89cb5] mb-1 font-light">Due date</p>
                <p className="text-sm text-[#4a3f52] font-normal">June 15, 2026</p>
              </div>
            </div>
            <div className="h-px bg-[#ede7f3]/60"></div>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-[#a89cb5] mb-1 font-light">Trimester</p>
                <p className="text-sm text-[#4a3f52] font-normal">Second trimester</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Care Team */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#6b5c75] font-normal text-base tracking-wide">My care team</h2>
        <div className="space-y-3">
          <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
            <div className="flex items-start gap-3">
              <div className="w-11 h-11 rounded-[20px] bg-[#e8e0f0]/60 flex items-center justify-center flex-shrink-0">
                <User className="w-5 h-5 text-[#9d8fb5] stroke-[1.5]" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-0.5 text-[#4a3f52] font-normal">Primary OB-GYN</h3>
                <p className="text-sm text-[#6b5c75] font-light">Dr. Maria Johnson</p>
                <p className="text-xs text-[#a89cb5] mt-1 font-light">Valley Health Center</p>
              </div>
              <button className="text-xs text-[#a89cb5] font-light hover:text-[#8b7a95] transition-colors">Edit</button>
            </div>
          </div>

          <button className="w-full bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50 hover:shadow-[0_4px_24px_rgba(0,0,0,0.06)] transition-all text-left">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-[20px] bg-[#e8e0f0]/60 flex items-center justify-center">
                <Users className="w-5 h-5 text-[#a89cb5] stroke-[1.5]" />
              </div>
              <span className="text-sm text-[#6b5c75] font-light">+ Add doula or support person</span>
            </div>
          </button>
        </div>
      </section>

      {/* Support System */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#6b5c75] font-normal text-base tracking-wide">My support system</h2>
        <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
          <div className="space-y-4">
            <div>
              <label className="text-sm text-[#8b7a95] mb-2 block font-light">Birth partner</label>
              <input
                type="text"
                defaultValue="James Mitchell"
                className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] font-light"
              />
            </div>
            <div>
              <label className="text-sm text-[#8b7a95] mb-2 block font-light">Emergency contact</label>
              <input
                type="text"
                defaultValue="James Mitchell - (555) 123-4567"
                className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] border border-[#e8e0f0]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 text-[#4a3f52] font-light"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Insurance */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#6b5c75] font-normal text-base tracking-wide">Insurance information</h2>
        <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
          <div className="flex items-start gap-3">
            <div className="w-11 h-11 rounded-[20px] bg-[#dce8e4]/60 flex items-center justify-center flex-shrink-0">
              <Shield className="w-5 h-5 text-[#8ba39c] stroke-[1.5]" />
            </div>
            <div className="flex-1">
              <h3 className="text-sm mb-0.5 text-[#4a3f52] font-normal">Blue Cross Blue Shield</h3>
              <p className="text-xs text-[#a89cb5] font-light">Member ID: ****6789</p>
            </div>
            <button className="text-xs text-[#a89cb5] font-light hover:text-[#8b7a95] transition-colors">Edit</button>
          </div>
        </div>
      </section>

      {/* Preferences */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#6b5c75] font-normal text-base tracking-wide">App preferences</h2>
        <div className="bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-[#b5a8c2] stroke-[1.5]" />
                <div>
                  <p className="text-sm text-[#4a3f52] font-normal">Appointment reminders</p>
                  <p className="text-xs text-[#a89cb5] font-light">Get notified before visits</p>
                </div>
              </div>
              <button className="w-12 h-6 bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] rounded-full relative shadow-sm">
                <span className="absolute right-1 top-1 w-4 h-4 bg-white rounded-full shadow-sm"></span>
              </button>
            </div>
            <div className="h-px bg-[#ede7f3]/60"></div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Heart className="w-5 h-5 text-[#c9a9c0] stroke-[1.5]" />
                <div>
                  <p className="text-sm text-[#4a3f52] font-normal">Daily check-ins</p>
                  <p className="text-xs text-[#a89cb5] font-light">Gentle emotional prompts</p>
                </div>
              </div>
              <button className="w-12 h-6 bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] rounded-full relative shadow-sm">
                <span className="absolute right-1 top-1 w-4 h-4 bg-white rounded-full shadow-sm"></span>
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Privacy Settings */}
      <section className="mb-8">
        <button
          onClick={() => setShowPrivacy(!showPrivacy)}
          className="w-full bg-gradient-to-br from-[#faf7fb] to-[#f9f5fb] rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#f0e8f3]/50 hover:shadow-[0_4px_24px_rgba(0,0,0,0.06)] transition-all"
        >
          <div className="flex items-center gap-3">
            <Shield className="w-5 h-5 text-[#a89cb5] stroke-[1.5]" />
            <div className="flex-1 text-left">
              <p className="text-sm text-[#4a3f52] font-normal">Privacy & data settings</p>
              <p className="text-xs text-[#8b7a95] font-light">Manage your privacy preferences</p>
            </div>
          </div>
        </button>

        {showPrivacy && (
          <div className="mt-4">
            <PrivacySettings />
          </div>
        )}
      </section>

      {/* Sign Out */}
      <button className="w-full bg-white/60 backdrop-blur-sm rounded-[28px] p-5 shadow-[0_2px_16px_rgba(0,0,0,0.04)] border border-[#ede7f3]/50 hover:shadow-[0_4px_24px_rgba(0,0,0,0.06)] transition-all">
        <div className="flex items-center justify-center gap-2 text-[#8b7a95]">
          <LogOut className="w-5 h-5 stroke-[1.5]" />
          <span className="text-sm font-light">Sign out</span>
        </div>
      </button>
    </div>
  );
}
