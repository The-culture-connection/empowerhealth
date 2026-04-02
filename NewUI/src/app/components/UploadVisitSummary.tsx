import { ChevronLeft, Calendar, Upload, FileText, Type, Shield, AlertCircle, Camera } from "lucide-react";
import { Link } from "react-router";
import { useState } from "react";

export function UploadVisitSummary() {
  const [uploadMethod, setUploadMethod] = useState<"pdf" | "text">("pdf");
  const [appointmentDate, setAppointmentDate] = useState("");
  const [isDragging, setIsDragging] = useState(false);

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    // Handle file drop logic here
  };

  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] relative overflow-hidden transition-colors duration-500">
      {/* Warm ambient light */}
      <div className="fixed inset-0 opacity-40 dark:opacity-30 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[140px]"></div>
        <div className="absolute bottom-1/4 left-1/4 w-[400px] h-[400px] rounded-full bg-[#b899d4] blur-[120px]"></div>
      </div>

      <div className="relative p-6 pb-24 max-w-2xl mx-auto">
        {/* Back Navigation */}
        <Link to="/my-visits" className="inline-flex items-center gap-2 mb-8 text-[#75657d] dark:text-[#cbbec9] hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors duration-300">
          <ChevronLeft className="w-4 h-4 stroke-[1.5]" />
          <span className="text-sm font-light tracking-wide">My Visits</span>
        </Link>

        {/* Header */}
        <div className="mb-8">
          <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-2 tracking-[-0.01em] transition-colors duration-300">Understand Your Visit</h1>
          <p className="text-[#75657d] dark:text-[#cbbec9] text-[15px] font-light leading-relaxed transition-colors duration-300">
            Add notes from your appointment
          </p>
        </div>

        {/* Privacy Notice Card */}
        <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 mb-6 transition-all duration-500">
          {/* Warm gold glow */}
          <div className="absolute inset-0 opacity-[0.05] pointer-events-none rounded-[24px] overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-[#d4a574] blur-[60px]"></div>
          </div>

          <div className="relative flex items-start gap-4">
            <div className="w-11 h-11 rounded-[16px] bg-gradient-to-br from-[#f5eee0] to-[#ebe0d6] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
              <Shield className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5]" />
            </div>
            <div className="flex-1">
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-[450] mb-2 tracking-[-0.005em] transition-colors duration-300">We help simplify documents you choose to upload</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed transition-colors duration-300">
                This tool makes medical language easier to understand. It does not provide medical advice or diagnosis.
              </p>
            </div>
          </div>
        </div>

        {/* Appointment Date */}
        <section className="mb-6">
          <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-4 font-medium transition-colors duration-300">Appointment Date</h2>

          <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[24px] p-5 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
            <div className="flex items-center gap-4">
              <div className="w-11 h-11 rounded-[16px] bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-300">
                <Calendar className="w-5 h-5 text-[#663399] dark:text-[#9d7ab8] stroke-[1.5]" />
              </div>
              <input
                type="date"
                value={appointmentDate}
                onChange={(e) => setAppointmentDate(e.target.value)}
                placeholder="Tap to select date"
                className="flex-1 px-5 py-3 rounded-[18px] bg-[#f7f5f9] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 transition-colors text-[#4a3f52] dark:text-[#f5f0f7] placeholder:text-[#b5a8c2] font-light"
              />
            </div>
          </div>
        </section>

        {/* Upload Method Toggle */}
        <section className="mb-6">
          <div className="flex gap-3 mb-6">
            <button
              onClick={() => setUploadMethod("pdf")}
              className={`flex-1 py-3.5 px-5 rounded-[20px] transition-all duration-300 font-light flex items-center justify-center gap-2 ${
                uploadMethod === "pdf"
                  ? "bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] text-white shadow-[0_4px_16px_rgba(102,51,153,0.25)]"
                  : "bg-[#faf8f4] dark:bg-[#2a2435] text-[#75657d] dark:text-[#cbbec9] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50"
              }`}
            >
              <FileText className="w-5 h-5 stroke-[1.5]" />
              Upload PDF
            </button>
            <button
              onClick={() => setUploadMethod("text")}
              className={`flex-1 py-3.5 px-5 rounded-[20px] transition-all duration-300 font-light flex items-center justify-center gap-2 ${
                uploadMethod === "text"
                  ? "bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] text-white shadow-[0_4px_16px_rgba(102,51,153,0.25)]"
                  : "bg-[#faf8f4] dark:bg-[#2a2435] text-[#75657d] dark:text-[#cbbec9] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50"
              }`}
            >
              <Type className="w-5 h-5 stroke-[1.5]" />
              Type Text
            </button>
          </div>
        </section>

        {/* Upload Area */}
        {uploadMethod === "pdf" && (
          <section className="mb-6">
            <div
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              className={`relative rounded-[28px] p-10 transition-all duration-300 cursor-pointer ${
                isDragging
                  ? "bg-gradient-to-br from-[#e8e0f0] to-[#d8cfe5] dark:from-[#3a3043] dark:to-[#4a3e5d] border-2 border-dashed border-[#663399] shadow-[0_12px_48px_rgba(102,51,153,0.2)]"
                  : "bg-[#faf8f4] dark:bg-[#2a2435] border-2 border-dashed border-[#e8e0f0] dark:border-[#3a3043] shadow-[0_8px_32px_rgba(102,51,153,0.1)] hover:border-[#d4c5e0] dark:hover:border-[#4a4057]"
              }`}
            >
              <div className="flex flex-col items-center text-center">
                {/* Cloud Upload Icon */}
                <div className="relative mb-6">
                  <div className="w-20 h-20 rounded-full bg-gradient-to-br from-[#b899d4] to-[#9d7ab8] dark:from-[#3a3043] dark:to-[#4a3e5d] flex items-center justify-center shadow-[0_8px_24px_rgba(184,153,212,0.3)] dark:shadow-[0_8px_24px_rgba(0,0,0,0.4)]">
                    <Upload className="w-10 h-10 text-white stroke-[1.5]" />
                  </div>
                </div>

                <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[17px] font-[450] mb-2 tracking-[-0.005em] transition-colors duration-300">Upload Visit Summary PDF</h3>
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed mb-6 max-w-sm transition-colors duration-300">
                  Tap to select PDF file from your device
                </p>

                {/* Action Buttons */}
                <div className="flex gap-3">
                  <button className="px-6 py-3 rounded-[18px] bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] text-white hover:shadow-[0_8px_24px_rgba(102,51,153,0.3)] transition-all duration-300 font-light flex items-center gap-2">
                    <FileText className="w-4 h-4 stroke-[2]" />
                    Choose File
                  </button>
                  <button className="px-6 py-3 rounded-[18px] bg-gradient-to-br from-[#d4a574] to-[#e0b589] text-white hover:shadow-[0_8px_24px_rgba(212,165,116,0.3)] transition-all duration-300 font-light flex items-center gap-2">
                    <Camera className="w-4 h-4 stroke-[2]" />
                    Take Photo
                  </button>
                </div>
              </div>
            </div>

            <p className="text-center text-xs text-[#9b8ba5] dark:text-[#9b8ba5] mt-4 font-light transition-colors duration-300">
              This works best with paperwork you were given after your visit
            </p>
          </section>
        )}

        {/* Text Input Area */}
        {uploadMethod === "text" && (
          <section className="mb-6">
            <div className="relative bg-[#faf8f4] dark:bg-[#2a2435] rounded-[28px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500">
              <textarea
                rows={10}
                placeholder="Type or paste your visit notes here..."
                className="w-full px-5 py-4 rounded-[20px] bg-[#f7f5f9] dark:bg-[#1a1520] border border-[#e8e0f0]/50 dark:border-[#3a3043]/50 focus:outline-none focus:ring-2 focus:ring-[#d4c5e0]/30 resize-none text-[#4a3f52] dark:text-[#f5f0f7] placeholder:text-[#b5a8c2] font-light leading-relaxed"
              ></textarea>

              <button className="w-full mt-4 py-3.5 px-6 rounded-[20px] bg-gradient-to-br from-[#663399] via-[#7744aa] to-[#8855bb] text-white hover:shadow-[0_8px_24px_rgba(102,51,153,0.3)] transition-all duration-300 font-light">
                Process Notes
              </button>
            </div>
          </section>
        )}

        {/* Processing Info */}
        <div className="relative bg-gradient-to-br from-[#faf7f3] via-[#f5f0eb] to-[#f0ead8] dark:from-[#2d2438] dark:via-[#2a2435] dark:to-[#2f2638] rounded-[24px] p-5 shadow-[0_4px_20px_rgba(102,51,153,0.08)] dark:shadow-[0_4px_20px_rgba(0,0,0,0.3)] border border-[#e8dfc8]/50 dark:border-[#3d3547] transition-all duration-300">
          <div className="flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5] flex-shrink-0 mt-0.5" />
            <div>
              <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-1 tracking-[-0.005em] transition-colors duration-300">We're making this easier to understand</h3>
              <p className="text-[#75657d] dark:text-[#cbbec9] text-xs font-light leading-relaxed transition-colors duration-300">
                We'll turn your visit summary into plain-language explanations. Medical terms will be simplified. Nothing is shared without your permission.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
