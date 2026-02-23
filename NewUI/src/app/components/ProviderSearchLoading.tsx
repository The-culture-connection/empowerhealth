import { Heart, Search, Shield, Sparkles } from "lucide-react";
import { useEffect, useState } from "react";

interface ProviderSearchLoadingProps {
  onComplete?: () => void;
}

export function ProviderSearchLoading({ onComplete }: ProviderSearchLoadingProps) {
  const [currentStage, setCurrentStage] = useState(0);

  const stages = [
    {
      icon: Search,
      message: "Searching Ohio Medicaid directories...",
      subtext: "Looking through thousands of providers just for you",
      color: "from-[#e8e0f0] to-[#d4c5e0]"
    },
    {
      icon: Shield,
      message: "Checking insurance and availability...",
      subtext: "Making sure they accept your health plan",
      color: "from-[#e0d5eb] to-[#d4c5e0]"
    },
    {
      icon: Heart,
      message: "Adding community trust indicators...",
      subtext: "Including reviews from mothers like you",
      color: "from-[#f0e0e8] to-[#d4c5e0]"
    },
    {
      icon: Sparkles,
      message: "Almost ready...",
      subtext: "Preparing your personalized results",
      color: "from-[#f0ead8] to-[#e6d5b8]"
    }
  ];

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentStage((prev) => {
        if (prev < stages.length - 1) {
          return prev + 1;
        } else {
          clearInterval(timer);
          if (onComplete) {
            setTimeout(onComplete, 800);
          }
          return prev;
        }
      });
    }, 1800);

    return () => clearInterval(timer);
  }, [onComplete]);

  const CurrentIcon = stages[currentStage].icon;
  const progress = ((currentStage + 1) / stages.length) * 100;

  return (
    <div className="min-h-screen bg-[#f7f5f9] flex items-center justify-center px-6 relative overflow-hidden">
      {/* Subtle texture overlay */}
      <div 
        className="absolute inset-0 opacity-[0.03] pointer-events-none"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23000000' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`
        }}
      />

      <div className="max-w-md w-full relative">
        {/* Main Loading Card */}
        <div className="bg-white/60 backdrop-blur-sm rounded-[32px] p-8 shadow-[0_4px_32px_rgba(0,0,0,0.08)] border border-[#ede7f3]/50 mb-6">
          {/* Animated Icon */}
          <div className="relative mb-8">
            <div className={`w-24 h-24 rounded-full bg-gradient-to-br ${stages[currentStage].color} mx-auto flex items-center justify-center animate-pulse shadow-[0_8px_32px_rgba(168,156,181,0.2)]`}>
              <CurrentIcon className="w-11 h-11 text-[#6b5c75] stroke-[1.5]" />
            </div>
            
            {/* Ripple effect */}
            <div className={`absolute inset-0 w-24 h-24 mx-auto rounded-full bg-gradient-to-br ${stages[currentStage].color} opacity-20 animate-ping`}></div>
          </div>

          {/* Stage Message */}
          <div className="text-center mb-8">
            <h2 className="text-xl mb-2 text-[#4a3f52] font-normal animate-fade-in">{stages[currentStage].message}</h2>
            <p className="text-sm text-[#8b7a95] animate-fade-in font-light leading-relaxed">{stages[currentStage].subtext}</p>
          </div>

          {/* Progress Bar */}
          <div className="mb-5">
            <div className="h-1.5 bg-[#ede7f3]/60 rounded-full overflow-hidden">
              <div 
                className={`h-full bg-gradient-to-r ${stages[currentStage].color} rounded-full transition-all duration-500 ease-out`}
                style={{ width: `${progress}%` }}
              ></div>
            </div>
          </div>

          {/* Stage Indicators */}
          <div className="flex justify-between items-center">
            {stages.map((stage, index) => {
              const StageIcon = stage.icon;
              const isActive = index === currentStage;
              const isComplete = index < currentStage;
              
              return (
                <div key={index} className="flex flex-col items-center gap-1.5">
                  <div
                    className={`w-9 h-9 rounded-full flex items-center justify-center transition-all duration-300 ${
                      isComplete
                        ? "bg-gradient-to-br from-[#d4c5e0] to-[#a89cb5] shadow-[0_2px_12px_rgba(168,156,181,0.2)]"
                        : isActive
                        ? "bg-gradient-to-br from-[#ebe4f3] to-[#e0d5eb] shadow-[0_2px_16px_rgba(168,156,181,0.15)]"
                        : "bg-[#f7f5f9]"
                    }`}
                  >
                    <StageIcon className={`w-4 h-4 stroke-[1.5] ${
                      isComplete ? "text-white" : isActive ? "text-[#8b7a95]" : "text-[#b5a8c2]"
                    }`} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Supportive Message */}
        <div className="text-center">
          <p className="text-sm text-[#a89cb5] font-light">
            Finding providers who are right for you
          </p>
        </div>
      </div>
    </div>
  );
}
