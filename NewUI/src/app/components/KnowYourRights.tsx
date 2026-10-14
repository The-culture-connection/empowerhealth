import { ChevronLeft, ChevronRight, Heart, MessageCircle, Shield, HelpCircle, CheckCircle } from "lucide-react";
import { Link } from "react-router";
import { useState } from "react";

type RightsTopic = {
  id: string;
  title: string;
  icon: typeof Heart;
  iconColor: string;
  bgGradient: string;
  darkBgGradient: string;
  description: string;
};

const rightTopics: RightsTopic[] = [
  {
    id: "ask-questions",
    title: "Your right to ask questions",
    icon: MessageCircle,
    iconColor: "text-[#d4a574] dark:text-[#e0b589]",
    bgGradient: "from-[#f5eee0] to-[#ebe0d6]",
    darkBgGradient: "dark:from-[#3a3043] dark:to-[#4a3e5d]",
    description: "You deserve clear answers about your care"
  },
  {
    id: "informed-consent",
    title: "Your right to informed consent",
    icon: Shield,
    iconColor: "text-[#8b7aa8] dark:text-[#b89fb5]",
    bgGradient: "from-[#e8e0f0] to-[#ede7f3]",
    darkBgGradient: "dark:from-[#3d3547] dark:to-[#4a4057]",
    description: "Understanding your choices before any procedure"
  },
  {
    id: "pain-management",
    title: "Your right to pain management",
    icon: Heart,
    iconColor: "text-[#c9a9c0] dark:text-[#d4b5c9]",
    bgGradient: "from-[#f8edf3] to-[#fdf5f9]",
    darkBgGradient: "dark:from-[#3d3040] dark:to-[#433845]",
    description: "Asking for comfort during labor and delivery"
  },
  {
    id: "support-person",
    title: "Your right to a support person",
    icon: Heart,
    iconColor: "text-[#d4a574] dark:text-[#e0b589]",
    bgGradient: "from-[#f9f2e8] to-[#fef9f5]",
    darkBgGradient: "dark:from-[#3d3540] dark:to-[#453d48]",
    description: "Having someone you trust by your side"
  },
  {
    id: "understand-care",
    title: "Your right to understand your care",
    icon: HelpCircle,
    iconColor: "text-[#7d9d92] dark:text-[#89b5a6]",
    bgGradient: "from-[#dce8e4] to-[#e8f0ed]",
    darkBgGradient: "dark:from-[#2d3836] dark:to-[#354340]",
    description: "Getting information in words that make sense"
  }
];

export function KnowYourRights() {
  const [selectedTopic, setSelectedTopic] = useState<string | null>(null);

  if (selectedTopic) {
    return <RightsDetail topicId={selectedTopic} onBack={() => setSelectedTopic(null)} />;
  }

  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] relative overflow-hidden transition-colors duration-500">
      {/* Warm ambient light */}
      <div className="fixed inset-0 opacity-40 dark:opacity-30 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[140px]"></div>
        <div className="absolute bottom-1/4 left-1/4 w-[400px] h-[400px] rounded-full bg-[#b899d4] blur-[120px]"></div>
      </div>

      <div className="relative p-6 pb-24 max-w-2xl mx-auto">
        {/* Back Navigation */}
        <Link to="/learning" className="inline-flex items-center gap-2 mb-8 text-[#75657d] dark:text-[#cbbec9] hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors duration-300">
          <ChevronLeft className="w-4 h-4 stroke-[1.5]" />
          <span className="text-sm font-light tracking-wide">Learning Center</span>
        </Link>

        {/* Header */}
        <div className="mb-8">
          <h1 className="text-[32px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-3 tracking-[-0.01em]">Know Your Rights</h1>
          <p className="text-[#75657d] dark:text-[#cbbec9] text-[15px] font-light leading-relaxed">
            You have the right to be heard, respected, and informed during your care.
          </p>
        </div>

        {/* Rights Topics - Tile-based Cards */}
        <div className="space-y-4 mb-8">
          {rightTopics.map((topic) => {
            const Icon = topic.icon;
            return (
              <button
                key={topic.id}
                onClick={() => setSelectedTopic(topic.id)}
                className="w-full relative bg-white dark:bg-[#2a2435] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40 transition-all duration-500 hover:shadow-[0_12px_48px_rgba(102,51,153,0.16)] hover:translate-y-[-2px] text-left"
              >
                <div className="flex items-start gap-4">
                  <div className={`w-14 h-14 rounded-[18px] bg-gradient-to-br ${topic.bgGradient} ${topic.darkBgGradient} flex items-center justify-center shadow-[inset_0_2px_10px_rgba(0,0,0,0.08)] transition-all duration-300 flex-shrink-0`}>
                    <Icon className={`w-6 h-6 ${topic.iconColor} stroke-[1.5]`} />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-[#2d2235] dark:text-[#f5f0f7] text-[17px] font-[450] mb-2 tracking-[-0.005em]">{topic.title}</h3>
                    <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">{topic.description}</p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#b5a8c2] stroke-[1.5] flex-shrink-0 mt-2" />
                </div>
              </button>
            );
          })}
        </div>

        {/* Gentle Footer Disclaimer */}
        <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[24px] p-6 shadow-[0_4px_20px_rgba(102,51,153,0.08)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
          <p className="text-[#75657d] dark:text-[#cbbec9] text-xs font-light leading-relaxed text-center">
            This information is meant to support understanding and communication. It does not replace medical or legal advice.
          </p>
        </div>
      </div>
    </div>
  );
}

function RightsDetail({ topicId, onBack }: { topicId: string; onBack: () => void }) {
  const topic = rightTopics.find(t => t.id === topicId);
  if (!topic) return null;

  const Icon = topic.icon;

  // Content for each rights topic
  const topicContent: Record<string, {
    whatThisMeans: string;
    whatYouCanSay: string[];
    questionsToAsk: string[];
    whenToAskForHelp: string;
  }> = {
    "ask-questions": {
      whatThisMeans: "You have the right to ask questions and get clear answers. Your care team should explain things in a way you can understand.",
      whatYouCanSay: [
        "Can you explain that in a simpler way?",
        "I need a moment to think before deciding.",
        "Can you tell me more about why this is needed?"
      ],
      questionsToAsk: [
        "What are my options?",
        "What happens if I wait?",
        "Are there risks I should know about?",
        "How will this affect my baby?"
      ],
      whenToAskForHelp: "If you feel rushed or pressured to make a decision without understanding it fully, it's okay to ask for more time or speak with another member of your care team."
    },
    "informed-consent": {
      whatThisMeans: "Before any procedure or treatment, your provider should explain what will happen, why it's recommended, and what other options you have. You have the right to say yes or no.",
      whatYouCanSay: [
        "I'd like to understand what this procedure involves.",
        "What are the alternatives?",
        "I need more time to decide.",
        "Can I talk to my support person first?"
      ],
      questionsToAsk: [
        "Why is this procedure recommended for me?",
        "What are the benefits and risks?",
        "What happens if I choose not to do this?",
        "How much time do I have to decide?"
      ],
      whenToAskForHelp: "If you feel like you're being asked to consent to something you don't understand, or if you feel uncomfortable, you can ask to speak with a patient advocate or nurse."
    },
    "pain-management": {
      whatThisMeans: "You have the right to ask for pain relief during labor and delivery. Your preferences about pain management should be respected.",
      whatYouCanSay: [
        "I'm experiencing pain and would like to discuss my options.",
        "Can we talk about pain management choices?",
        "I'd like to try [specific method] for pain relief.",
        "This isn't working for me. What else can we try?"
      ],
      questionsToAsk: [
        "What pain management options are available?",
        "How will this affect my baby?",
        "Can I change my mind later?",
        "What are the side effects?"
      ],
      whenToAskForHelp: "If your requests for pain management are being dismissed or ignored, ask to speak with a charge nurse or patient advocate."
    },
    "support-person": {
      whatThisMeans: "You have the right to have a support person with you during labor, delivery, and recovery. This could be a partner, family member, doula, or friend.",
      whatYouCanSay: [
        "I'd like my support person to stay with me.",
        "Can my doula be present during delivery?",
        "I need my support person here for this decision.",
        "When will my support person be able to join me?"
      ],
      questionsToAsk: [
        "Can my support person be with me during all procedures?",
        "What are the visitor policies?",
        "Can I have more than one support person?",
        "Will my support person need to leave at any point?"
      ],
      whenToAskForHelp: "If you're being told you can't have a support person when you were expecting to, ask to speak with a supervisor or patient advocate about the hospital's policies."
    },
    "understand-care": {
      whatThisMeans: "You have the right to receive information about your care in language you can understand. If medical terms are confusing, your care team should explain them clearly.",
      whatYouCanSay: [
        "Can you use simpler words to explain that?",
        "I don't understand. Can you explain it differently?",
        "Can you write that down for me?",
        "Do you have any handouts I can read?"
      ],
      questionsToAsk: [
        "What does that medical term mean?",
        "Can you show me on a picture or diagram?",
        "What should I watch for at home?",
        "When should I call if something doesn't feel right?"
      ],
      whenToAskForHelp: "If you're not getting clear answers or feel like your questions are being dismissed, you can ask for a patient advocate or speak with another provider."
    }
  };

  const content = topicContent[topicId];

  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] relative overflow-hidden transition-colors duration-500">
      {/* Warm ambient light */}
      <div className="fixed inset-0 opacity-40 dark:opacity-30 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[140px]"></div>
      </div>

      <div className="relative p-6 pb-24 max-w-2xl mx-auto">
        {/* Back Navigation */}
        <button
          onClick={onBack}
          className="inline-flex items-center gap-2 mb-8 text-[#75657d] dark:text-[#cbbec9] hover:text-[#663399] dark:hover:text-[#d4a574] transition-colors duration-300"
        >
          <ChevronLeft className="w-4 h-4 stroke-[1.5]" />
          <span className="text-sm font-light tracking-wide">All Rights</span>
        </button>

        {/* Header with Icon */}
        <div className="mb-8">
          <div className={`inline-flex w-16 h-16 rounded-[20px] bg-gradient-to-br ${topic.bgGradient} ${topic.darkBgGradient} items-center justify-center shadow-[0_8px_24px_rgba(102,51,153,0.15)] mb-4`}>
            <Icon className={`w-8 h-8 ${topic.iconColor} stroke-[1.5]`} />
          </div>
          <h1 className="text-[28px] text-[#2d2235] dark:text-[#f5f0f7] font-[450] leading-[1.3] mb-2 tracking-[-0.01em]">{topic.title}</h1>
        </div>

        {/* What This Means */}
        <section className="mb-6">
          <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
            <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-3 font-medium">What this means</h2>
            <p className="text-[#2d2235] dark:text-[#f5f0f7] text-[15px] font-light leading-relaxed">
              {content.whatThisMeans}
            </p>
          </div>
        </section>

        {/* What You Can Say */}
        <section className="mb-6">
          <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
            <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-4 font-medium">What you can say</h2>
            <div className="space-y-3">
              {content.whatYouCanSay.map((phrase, index) => (
                <div key={index} className="flex items-start gap-3">
                  <MessageCircle className="w-4 h-4 text-[#d4a574] dark:text-[#e0b589] flex-shrink-0 mt-0.5 stroke-[1.5]" />
                  <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">
                    "{phrase}"
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Questions You May Want to Ask */}
        <section className="mb-6">
          <div className="relative bg-white dark:bg-[#2a2435] rounded-[24px] p-6 shadow-[0_8px_32px_rgba(102,51,153,0.1),_inset_0_1px_0_rgba(255,255,255,0.6)] dark:shadow-[0_8px_40px_rgba(0,0,0,0.4)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
            <h2 className="text-[#663399] dark:text-[#cbbec9] text-[13px] uppercase tracking-[0.08em] mb-4 font-medium">Questions you may want to ask</h2>
            <div className="space-y-2">
              {content.questionsToAsk.map((question, index) => (
                <div key={index} className="flex items-start gap-3 py-2">
                  <CheckCircle className="w-4 h-4 text-[#8b7aa8] dark:text-[#b89fb5] flex-shrink-0 mt-0.5 stroke-[1.5]" />
                  <p className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-light leading-relaxed">
                    {question}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* When to Ask for Help */}
        <section className="mb-6">
          <div className="relative bg-gradient-to-br from-[#f5eee0] via-[#faf8f4] to-[#ebe0d6] dark:from-[#2a2435] dark:via-[#2d2640] dark:to-[#3a3043] rounded-[24px] p-6 shadow-[0_4px_20px_rgba(102,51,153,0.08)] border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
            <div className="flex items-start gap-3">
              <Heart className="w-5 h-5 text-[#d4a574] dark:text-[#e0b589] stroke-[1.5] flex-shrink-0 mt-0.5" />
              <div>
                <h2 className="text-[#2d2235] dark:text-[#f5f0f7] text-sm font-[450] mb-2">When to ask for help</h2>
                <p className="text-[#75657d] dark:text-[#cbbec9] text-sm font-light leading-relaxed">
                  {content.whenToAskForHelp}
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Gentle Disclaimer */}
        <div className="relative bg-white/60 dark:bg-[#2a2435]/60 rounded-[20px] p-5 border border-[#e8e0f0]/40 dark:border-[#3a3043]/40">
          <p className="text-[#75657d] dark:text-[#cbbec9] text-xs font-light leading-relaxed text-center">
            This information is meant to support understanding and communication. It does not replace medical or legal advice.
          </p>
        </div>
      </div>
    </div>
  );
}
