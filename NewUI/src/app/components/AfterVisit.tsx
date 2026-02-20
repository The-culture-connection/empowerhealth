import { FileText, Calendar, Pill, Activity, AlertCircle, CheckCircle, Flag, Share2 } from "lucide-react";
import { useState } from "react";
import { PHIBoundaryNotice, SecureIndicator, EmergencyFooter } from "./PrivacyComponents";

export function AfterVisit() {
  const [flagged, setFlagged] = useState(false);

  return (
    <div className="p-5 pb-24">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl mb-2">After Visit Summary</h1>
        <p className="text-gray-600">Your visit explained in simple terms</p>
      </div>

      {/* PHI Boundary Notice */}
      <div className="mb-4">
        <PHIBoundaryNotice />
      </div>

      {/* Visit Info */}
      <div className="bg-white rounded-3xl p-5 mb-4 shadow-sm border border-gray-100">
        <div className="flex items-start justify-between mb-4">
          <div>
            <p className="text-sm text-gray-500 mb-1">February 14, 2026</p>
            <h2 className="text-lg mb-1">24-Week Prenatal Checkup</h2>
            <p className="text-sm text-gray-600">Dr. Maria Johnson</p>
          </div>
          <button className="text-[#663399] flex items-center gap-2 text-sm">
            <Share2 className="w-4 h-4" />
            Share
          </button>
        </div>

        <div className="flex items-center gap-2 p-3 bg-green-50 rounded-2xl mb-3">
          <CheckCircle className="w-5 h-5 text-green-600 flex-shrink-0" />
          <p className="text-sm text-green-900">Everything looks great! You and baby are doing well.</p>
        </div>

        <SecureIndicator />
      </div>

      {/* What We Checked */}
      <section className="mb-4">
        <h2 className="mb-3">What We Checked Today</h2>
        <div className="space-y-3">
          <div className="bg-white rounded-3xl p-4 shadow-sm border border-gray-100">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-2xl bg-blue-50 flex items-center justify-center flex-shrink-0">
                <Activity className="w-5 h-5 text-blue-500" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-1">Baby's Heartbeat</h3>
                <p className="text-sm text-gray-600 mb-2">145 beats per minute</p>
                <p className="text-xs text-gray-500">
                  This is a healthy heart rate for your baby right now. A normal range is between 110-160 beats per minute.
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-3xl p-4 shadow-sm border border-gray-100">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-2xl bg-purple-50 flex items-center justify-center flex-shrink-0">
                <Activity className="w-5 h-5 text-[#663399]" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-1">Your Blood Pressure</h3>
                <p className="text-sm text-gray-600 mb-2">118/76 mmHg</p>
                <p className="text-xs text-gray-500">
                  Your blood pressure is in the normal range. We'll keep monitoring it to make sure you stay healthy.
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-3xl p-4 shadow-sm border border-gray-100">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-2xl bg-amber-50 flex items-center justify-center flex-shrink-0">
                <Activity className="w-5 h-5 text-amber-600" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-1">Fundal Height</h3>
                <p className="text-sm text-gray-600 mb-2">24 centimeters</p>
                <p className="text-xs text-gray-500">
                  This measures how your baby is growing. At 24 weeks, a measurement around 24 cm means baby is right on track.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Medications */}
      <section className="mb-4">
        <h2 className="mb-3">Your Medications</h2>
        <div className="bg-white rounded-3xl p-4 shadow-sm border border-gray-100">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-2xl bg-green-50 flex items-center justify-center flex-shrink-0">
              <Pill className="w-5 h-5 text-green-600" />
            </div>
            <div className="flex-1">
              <h3 className="text-sm mb-1">Prenatal Vitamin</h3>
              <p className="text-xs text-gray-600 mb-2">Take once daily with food</p>
              <p className="text-xs text-gray-500">
                Your vitamin has extra folic acid and iron to help your baby's brain and spine develop. Take it with food to avoid stomach upset.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Next Steps */}
      <section className="mb-4">
        <h2 className="mb-3">What to Do Next</h2>
        <div className="space-y-3">
          <div className="bg-white rounded-3xl p-4 shadow-sm border border-gray-100">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-2xl bg-[#663399]/10 flex items-center justify-center flex-shrink-0">
                <Calendar className="w-5 h-5 text-[#663399]" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-1">Schedule Your Glucose Test</h3>
                <p className="text-xs text-gray-600 mb-2">Due in 2-3 weeks (weeks 26-28)</p>
                <p className="text-xs text-gray-500 mb-3">
                  This test checks for gestational diabetes. You'll drink a sweet drink and have your blood tested.
                </p>
                <button className="text-xs text-[#663399]">Schedule now →</button>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-3xl p-4 shadow-sm border border-gray-100">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-2xl bg-blue-50 flex items-center justify-center flex-shrink-0">
                <FileText className="w-5 h-5 text-blue-500" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm mb-1">Next Appointment</h3>
                <p className="text-xs text-gray-600 mb-2">March 14 at 10:00 AM</p>
                <p className="text-xs text-gray-500">Your regular 28-week checkup</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Emotional Flag */}
      <section className="mb-4">
        <div className="bg-gradient-to-br from-[#fef3f3] to-[#fff0f8] rounded-3xl p-5 shadow-sm border border-pink-100">
          <div className="flex items-start justify-between mb-3">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-2xl bg-rose-100 flex items-center justify-center flex-shrink-0">
                <Flag className="w-5 h-5 text-rose-600" />
              </div>
              <div>
                <h3 className="mb-1">Mark an Emotional Moment</h3>
                <p className="text-sm text-gray-600">
                  Did something during this visit feel uncomfortable, unclear, or important to remember?
                </p>
              </div>
            </div>
          </div>
          <button
            onClick={() => setFlagged(!flagged)}
            className={`w-full py-2 px-4 rounded-2xl transition-colors ${
              flagged
                ? "bg-[#663399] text-white"
                : "bg-white border border-gray-200 text-gray-700"
            }`}
          >
            {flagged ? "Moment flagged ✓" : "Flag this visit"}
          </button>
        </div>
      </section>

      {/* Questions */}
      <section>
        <div className="bg-white rounded-3xl p-5 shadow-sm border border-gray-100">
          <div className="flex items-start gap-3 mb-3">
            <div className="w-10 h-10 rounded-2xl bg-amber-50 flex items-center justify-center flex-shrink-0">
              <AlertCircle className="w-5 h-5 text-amber-600" />
            </div>
            <div>
              <h3 className="mb-1">Have Questions?</h3>
              <p className="text-sm text-gray-600">
                It's okay to not understand everything. Ask our AI assistant to explain anything in simpler terms.
              </p>
            </div>
          </div>
          <button className="w-full py-3 px-4 rounded-2xl bg-[#663399] text-white hover:bg-[#552288] transition-colors">
            Ask for Support
          </button>
        </div>
      </section>

      {/* Emergency Footer */}
      <div className="mt-6">
        <EmergencyFooter />
      </div>
    </div>
  );
}