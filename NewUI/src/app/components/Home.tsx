import { Link } from "react-router";
import { Search, Calendar, Heart, BookOpen, FileText, ClipboardList, MessageCircle, ChevronRight } from "lucide-react";

export function Home() {
  return (
    <div className="p-5">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#663399] to-[#cbbec9] flex items-center justify-center text-white text-lg">
              S
            </div>
            <div>
              <p className="text-gray-500 text-sm">Good morning,</p>
              <h1 className="text-xl">Sarah</h1>
            </div>
          </div>
        </div>

        {/* Search Bar */}
        <div className="relative">
          <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            type="text"
            placeholder="Search topics, providers, or questions"
            className="w-full pl-12 pr-4 py-3 rounded-2xl bg-white border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20"
          />
        </div>
      </div>

      {/* Your Pregnancy Journey */}
      <section className="mb-6">
        <h2 className="mb-3">Your Pregnancy Journey</h2>
        <div className="bg-gradient-to-br from-[#663399] to-[#8855bb] rounded-3xl p-6 text-white shadow-md">
          <div className="flex justify-between items-start mb-4">
            <div>
              <p className="text-white/90 text-sm mb-1">Week 24 of 40</p>
              <h3 className="text-2xl mb-1">Second Trimester</h3>
              <p className="text-white/80 text-sm">You're doing beautifully</p>
            </div>
            <div className="w-16 h-16 rounded-full bg-white/20 flex items-center justify-center">
              <span className="text-2xl">🤰</span>
            </div>
          </div>
          <div className="w-full h-2 bg-white/20 rounded-full overflow-hidden">
            <div className="h-full bg-white rounded-full" style={{ width: "60%" }}></div>
          </div>
        </div>
      </section>

      {/* Today's Support */}
      <section className="mb-6">
        <h2 className="mb-3">Today's Support</h2>
        
        {/* Appointment Reminder */}
        <div className="bg-white rounded-3xl p-5 mb-3 shadow-sm border border-gray-100">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 rounded-2xl bg-[#663399]/10 flex items-center justify-center flex-shrink-0">
              <Calendar className="w-6 h-6 text-[#663399]" />
            </div>
            <div className="flex-1">
              <h3 className="mb-1">Prenatal Appointment</h3>
              <p className="text-sm text-gray-600 mb-2">Tomorrow at 2:00 PM</p>
              <p className="text-sm text-gray-500">Dr. Johnson • Valley Health Center</p>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </div>
        </div>

        {/* Emotional Check-in */}
        <div className="bg-gradient-to-br from-[#fef3f3] to-[#fff0f8] rounded-3xl p-5 shadow-sm border border-pink-100">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 rounded-2xl bg-rose-100 flex items-center justify-center flex-shrink-0">
              <Heart className="w-6 h-6 text-rose-500" />
            </div>
            <div className="flex-1">
              <h3 className="mb-1">How are you feeling?</h3>
              <p className="text-sm text-gray-600">Take a moment to check in with yourself</p>
            </div>
          </div>
        </div>
      </section>

      {/* Learning Modules */}
      <section className="mb-6">
        <div className="flex items-center justify-between mb-3">
          <h2>Learning Modules</h2>
          <Link to="/learning" className="text-sm text-[#663399]">
            See all
          </Link>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <div className="w-10 h-10 rounded-2xl bg-blue-50 flex items-center justify-center mb-3">
              <BookOpen className="w-5 h-5 text-blue-500" />
            </div>
            <h3 className="text-sm mb-1">Week 24 Guide</h3>
            <p className="text-xs text-gray-500">Your baby this week</p>
          </div>

          <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
            <div className="w-10 h-10 rounded-2xl bg-purple-50 flex items-center justify-center mb-3">
              <FileText className="w-5 h-5 text-[#663399]" />
            </div>
            <h3 className="text-sm mb-1">Know Your Rights</h3>
            <p className="text-xs text-gray-500">Healthcare advocacy</p>
          </div>
        </div>
      </section>

      {/* Quick Tools */}
      <section className="mb-6">
        <h2 className="mb-3">Quick Tools</h2>
        <div className="space-y-3">
          <Link
            to="/birth-plan"
            className="flex items-center gap-4 bg-white rounded-3xl p-4 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors"
          >
            <div className="w-12 h-12 rounded-2xl bg-[#663399]/10 flex items-center justify-center">
              <ClipboardList className="w-6 h-6 text-[#663399]" />
            </div>
            <div className="flex-1">
              <h3 className="text-sm mb-0.5">Birth Plan Builder</h3>
              <p className="text-xs text-gray-500">Create your preferences</p>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </Link>

          <Link
            to="/after-visit"
            className="flex items-center gap-4 bg-white rounded-3xl p-4 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors"
          >
            <div className="w-12 h-12 rounded-2xl bg-green-50 flex items-center justify-center">
              <FileText className="w-6 h-6 text-green-600" />
            </div>
            <div className="flex-1">
              <h3 className="text-sm mb-0.5">After Visit Summary</h3>
              <p className="text-xs text-gray-500">Understand your visit</p>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </Link>

          <Link
            to="/journal"
            className="flex items-center gap-4 bg-white rounded-3xl p-4 shadow-sm border border-gray-100 hover:border-[#663399]/30 transition-colors"
          >
            <div className="w-12 h-12 rounded-2xl bg-amber-50 flex items-center justify-center">
              <Heart className="w-6 h-6 text-amber-600" />
            </div>
            <div className="flex-1">
              <h3 className="text-sm mb-0.5">Journal Entry</h3>
              <p className="text-xs text-gray-500">Reflect on today</p>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </Link>
        </div>
      </section>
    </div>
  );
}
