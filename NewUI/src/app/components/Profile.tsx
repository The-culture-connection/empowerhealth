import { User, Calendar, Heart, Users, FileText, Shield, Bell, LogOut, Sparkles } from "lucide-react";
import { PrivacySettings } from "./PrivacyComponents";
import { useState } from "react";

export function Profile() {
  const [showPrivacy, setShowPrivacy] = useState(false);

  return (
    <div className="p-6 pb-24">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl mb-2 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Your profile</h1>
        <p className="text-[#6b5c75] dark:text-[#c9bfd4] font-light transition-colors">Manage your information and preferences</p>
      </div>

      {/* Profile Card */}
      <section className="mb-8">
        <div className="bg-gradient-to-br from-[#ebe4f3] via-[#e0d5eb] to-[#e8dfe8] dark:from-[#2d2438] dark:via-[#352d40] dark:to-[#3a2f3d] rounded-[32px] p-7 shadow-[0_8px_32px_rgba(102,51,153,0.12)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] relative overflow-hidden border border-[#e0d3e8]/50 dark:border-[#4a4057]/30 transition-all duration-300">
          {/* Subtle background pattern */}
          <div className="absolute inset-0 opacity-30 dark:opacity-20 transition-opacity duration-300">
            <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-[#d4c5e0] dark:bg-[#663399] blur-3xl"></div>
            <div className="absolute bottom-0 left-0 w-40 h-40 rounded-full bg-[#e6d5b8] dark:bg-[#d4a574] blur-3xl"></div>
          </div>

          <div className="relative flex items-start gap-4 mb-4">
            <div className="w-16 h-16 rounded-[24px] bg-white/40 dark:bg-[#3d3547]/60 backdrop-blur-sm flex items-center justify-center text-2xl text-[#663399] dark:text-[#b89fb5] shadow-sm transition-all duration-300">
              S
            </div>
            <div className="flex-1">
              <h2 className="text-xl mb-1 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Sarah Mitchell</h2>
              <p className="text-[#6b5c75] dark:text-[#c9bfd4] text-sm font-light transition-colors">sarah.mitchell@email.com</p>
              <p className="text-[#6b5c75] dark:text-[#b89fb5] text-sm mt-2 font-light transition-colors">Due date: June 15, 2026</p>
            </div>
            <button className="text-[#8b7a95] dark:text-[#b89fb5] text-sm font-light hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors">Edit</button>
          </div>
        </div>
      </section>

      {/* Pregnancy Information */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#4a3f52] dark:text-[#c9bfd4] font-normal text-base tracking-wide transition-colors">Pregnancy details</h2>
        <div className="bg-white/60 dark:bg-[#2a2435] backdrop-blur-sm rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#ede7f3]/50 dark:border-[#3d3547] transition-all duration-300">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-[#9d8fb5] dark:text-[#9d8fb5] mb-1 font-light transition-colors">Current week</p>
                <p className="text-sm text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Week 24 of 40</p>
              </div>
              <Calendar className="w-5 h-5 text-[#b5a8c2] dark:text-[#9d8fb5] stroke-[1.5] transition-colors" />
            </div>
            <div className="h-px bg-[#ede7f3]/60 dark:bg-[#3d3547] transition-colors duration-300"></div>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-[#9d8fb5] dark:text-[#9d8fb5] mb-1 font-light transition-colors">Due date</p>
                <p className="text-sm text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">June 15, 2026</p>
              </div>
            </div>
            <div className="h-px bg-[#ede7f3]/60 dark:bg-[#3d3547] transition-colors duration-300"></div>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-[#9d8fb5] dark:text-[#9d8fb5] mb-1 font-light transition-colors">Trimester</p>
                <p className="text-sm text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Second trimester</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Care Team */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#4a3f52] dark:text-[#c9bfd4] font-normal text-base tracking-wide transition-colors">My care team</h2>
        <div className="space-y-3">
          <div className="bg-white/60 dark:bg-[#2a2435] backdrop-blur-sm rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#ede7f3]/50 dark:border-[#3d3547] transition-all duration-300">
            <div className="flex items-start gap-3">
              <div className="w-11 h-11 rounded-[20px] bg-[#e8e0f0]/60 dark:bg-[#3d3547] flex items-center justify-center flex-shrink-0 transition-all duration-300">
                <User className="w-5 h-5 text-[#9d8fb5] dark:text-[#b89fb5] stroke-[1.5] transition-colors" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-0.5 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Primary OB-GYN</h3>
                <p className="text-sm text-[#6b5c75] dark:text-[#c9bfd4] font-light transition-colors">Dr. Maria Johnson</p>
                <p className="text-xs text-[#9d8fb5] dark:text-[#9d8fb5] mt-1 font-light transition-colors">Valley Health Center</p>
              </div>
              <button className="text-xs text-[#9d8fb5] dark:text-[#9d8fb5] font-light hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors">Edit</button>
            </div>
          </div>

          <button className="w-full bg-white/60 dark:bg-[#2a2435] backdrop-blur-sm rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#ede7f3]/50 dark:border-[#3d3547] hover:shadow-[0_8px_32px_rgba(102,51,153,0.12)] dark:hover:shadow-[0_8px_32px_rgba(157,143,181,0.15)] hover:border-[#d4c5e0] dark:hover:border-[#4a4057] transition-all duration-300 text-left">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-[20px] bg-[#e8e0f0]/60 dark:bg-[#3d3547] flex items-center justify-center transition-all duration-300">
                <Users className="w-5 h-5 text-[#a89cb5] dark:text-[#9d8fb5] stroke-[1.5] transition-colors" />
              </div>
              <span className="text-sm text-[#6b5c75] dark:text-[#c9bfd4] font-light transition-colors">+ Add doula or support person</span>
            </div>
          </button>
        </div>
      </section>

      {/* Support System */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#4a3f52] dark:text-[#c9bfd4] font-normal text-base tracking-wide transition-colors">My support system</h2>
        <div className="bg-white/60 dark:bg-[#2a2435] backdrop-blur-sm rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#ede7f3]/50 dark:border-[#3d3547] transition-all duration-300">
          <div className="space-y-4">
            <div>
              <label className="text-sm text-[#6b5c75] dark:text-[#b89fb5] mb-2 block font-light transition-colors">Birth partner</label>
              <input
                type="text"
                defaultValue="James Mitchell"
                className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3d3547] focus:outline-none focus:ring-2 focus:ring-[#8b7aa8]/30 dark:focus:ring-[#9d8fb5]/30 text-[#2d2733] dark:text-[#f5f0f7] font-light transition-all duration-300"
              />
            </div>
            <div>
              <label className="text-sm text-[#6b5c75] dark:text-[#b89fb5] mb-2 block font-light transition-colors">Emergency contact</label>
              <input
                type="text"
                defaultValue="James Mitchell - (555) 123-4567"
                className="w-full px-5 py-3.5 rounded-[20px] bg-[#f7f5f9] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3d3547] focus:outline-none focus:ring-2 focus:ring-[#8b7aa8]/30 dark:focus:ring-[#9d8fb5]/30 text-[#2d2733] dark:text-[#f5f0f7] font-light transition-all duration-300"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Insurance */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#4a3f52] dark:text-[#c9bfd4] font-normal text-base tracking-wide transition-colors">Insurance information</h2>
        <div className="bg-white/60 dark:bg-[#2a2435] backdrop-blur-sm rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#ede7f3]/50 dark:border-[#3d3547] transition-all duration-300">
          <div className="flex items-start gap-3">
            <div className="w-11 h-11 rounded-[20px] bg-[#dce8e4]/60 dark:bg-[#2d3836] flex items-center justify-center flex-shrink-0 transition-all duration-300">
              <Shield className="w-5 h-5 text-[#8ba39c] dark:text-[#89b5a6] stroke-[1.5] transition-colors" />
            </div>
            <div className="flex-1">
              <h3 className="text-sm mb-0.5 text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Blue Cross Blue Shield</h3>
              <p className="text-xs text-[#9d8fb5] dark:text-[#9d8fb5] font-light transition-colors">Member ID: ****6789</p>
            </div>
            <button className="text-xs text-[#9d8fb5] dark:text-[#9d8fb5] font-light hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors">Edit</button>
          </div>
        </div>
      </section>

      {/* Preferences */}
      <section className="mb-8">
        <h2 className="mb-4 text-[#4a3f52] dark:text-[#c9bfd4] font-normal text-base tracking-wide transition-colors">App preferences</h2>
        <div className="bg-white/60 dark:bg-[#2a2435] backdrop-blur-sm rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#ede7f3]/50 dark:border-[#3d3547] transition-all duration-300">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-[#b5a8c2] dark:text-[#9d8fb5] stroke-[1.5] transition-colors" />
                <div>
                  <p className="text-sm text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Appointment reminders</p>
                  <p className="text-xs text-[#9d8fb5] dark:text-[#9d8fb5] font-light transition-colors">Get notified before visits</p>
                </div>
              </div>
              <button className="w-12 h-6 bg-gradient-to-br from-[#8b7aa8] to-[#b89fb5] dark:from-[#9d8fb5] dark:to-[#d4a574] rounded-full relative shadow-sm transition-all duration-300">
                <span className="absolute right-1 top-1 w-4 h-4 bg-white rounded-full shadow-sm"></span>
              </button>
            </div>
            <div className="h-px bg-[#ede7f3]/60 dark:bg-[#3d3547] transition-colors duration-300"></div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Heart className="w-5 h-5 text-[#c9a9c0] dark:text-[#d4a574] stroke-[1.5] transition-colors" />
                <div>
                  <p className="text-sm text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Daily check-ins</p>
                  <p className="text-xs text-[#9d8fb5] dark:text-[#9d8fb5] font-light transition-colors">Gentle emotional prompts</p>
                </div>
              </div>
              <button className="w-12 h-6 bg-gradient-to-br from-[#8b7aa8] to-[#b89fb5] dark:from-[#9d8fb5] dark:to-[#d4a574] rounded-full relative shadow-sm transition-all duration-300">
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
          className="w-full bg-gradient-to-br from-[#faf7fb] to-[#f9f5fb] dark:from-[#2a2435] dark:to-[#2d2438] rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#f0e8f3]/50 dark:border-[#3d3547] hover:shadow-[0_8px_32px_rgba(102,51,153,0.12)] dark:hover:shadow-[0_8px_32px_rgba(157,143,181,0.15)] hover:border-[#e6d5b8] dark:hover:border-[#4a4057] transition-all duration-300"
        >
          <div className="flex items-center gap-3">
            <Shield className="w-5 h-5 text-[#a89cb5] dark:text-[#b89fb5] stroke-[1.5] transition-colors" />
            <div className="flex-1 text-left">
              <p className="text-sm text-[#2d2733] dark:text-[#f5f0f7] font-normal transition-colors">Privacy & data settings</p>
              <p className="text-xs text-[#6b5c75] dark:text-[#b89fb5] font-light transition-colors">Manage your privacy preferences</p>
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
      <button className="w-full bg-white/60 dark:bg-[#2a2435] backdrop-blur-sm rounded-[28px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#ede7f3]/50 dark:border-[#3d3547] hover:shadow-[0_8px_32px_rgba(102,51,153,0.12)] dark:hover:shadow-[0_8px_32px_rgba(157,143,181,0.15)] hover:border-[#d4c5e0] dark:hover:border-[#4a4057] transition-all duration-300">
        <div className="flex items-center justify-center gap-2 text-[#6b5c75] dark:text-[#b89fb5] transition-colors">
          <LogOut className="w-5 h-5 stroke-[1.5]" />
          <span className="text-sm font-light">Sign out</span>
        </div>
      </button>
    </div>
  );
}
