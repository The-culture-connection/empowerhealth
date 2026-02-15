import { Outlet, Link, useLocation } from "react-router";
import { Home, BookOpen, FileText, Heart, MessageCircle, User, Search, MessageSquare, X } from "lucide-react";
import { useState } from "react";
import { functionsService } from "../../services/functionsService";

export function Layout() {
  const location = useLocation();
  const [showAssistant, setShowAssistant] = useState(false);
  const [assistantMessage, setAssistantMessage] = useState("");
  const [assistantResponse, setAssistantResponse] = useState("");
  const [loading, setLoading] = useState(false);

  const navItems = [
    { path: "/", icon: Home, label: "Home" },
    { path: "/learning", icon: BookOpen, label: "Learn" },
    { path: "/journal", icon: Heart, label: "Journal" },
    { path: "/community", icon: MessageCircle, label: "Community" },
    { path: "/profile", icon: User, label: "Profile" },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] pb-20">
      {/* Main Content */}
      <main className="max-w-2xl mx-auto">
        <Outlet />
      </main>

      {/* Floating AI Assistant Button */}
      <button
        onClick={() => setShowAssistant(true)}
        className="fixed bottom-24 right-6 w-14 h-14 bg-gradient-to-br from-[#663399] to-[#8855bb] text-white rounded-full shadow-lg flex items-center justify-center z-10 hover:shadow-xl transition-shadow"
        aria-label="Ask for support"
      >
        <MessageSquare className="w-6 h-6" />
      </button>

      {/* AI Assistant Modal */}
      {showAssistant && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center p-4">
          <div className="bg-white rounded-3xl w-full max-w-md max-h-[80vh] flex flex-col shadow-xl">
            <div className="flex items-center justify-between p-4 border-b border-gray-200">
              <h2 className="text-lg font-semibold">AI Assistant</h2>
              <button
                onClick={() => {
                  setShowAssistant(false);
                  setAssistantMessage("");
                  setAssistantResponse("");
                }}
                className="p-2 hover:bg-gray-100 rounded-full transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto p-4 space-y-4">
              {assistantResponse && (
                <div className="bg-purple-50 rounded-2xl p-4">
                  <p className="text-sm text-gray-700 whitespace-pre-wrap">{assistantResponse}</p>
                </div>
              )}
              <div className="space-y-2">
                <textarea
                  value={assistantMessage}
                  onChange={(e) => setAssistantMessage(e.target.value)}
                  placeholder="Ask me anything about your pregnancy, care, or rights..."
                  rows={4}
                  className="w-full px-4 py-3 rounded-2xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#663399]/20 resize-none"
                />
                <button
                  onClick={async () => {
                    if (!assistantMessage.trim()) return;
                    setLoading(true);
                    try {
                      const response = await functionsService.simplifyText({ text: assistantMessage });
                      setAssistantResponse(response.simplifiedText || "I'm here to help! How can I assist you today?");
                    } catch (error: any) {
                      setAssistantResponse("I'm having trouble right now. Please try again later.");
                    } finally {
                      setLoading(false);
                    }
                  }}
                  disabled={loading || !assistantMessage.trim()}
                  className="w-full py-3 px-4 rounded-2xl bg-[#663399] text-white hover:bg-[#552288] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {loading ? "Thinking..." : "Ask"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-20">
        <div className="max-w-2xl mx-auto flex justify-around items-center h-16 px-4">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex flex-col items-center justify-center gap-1 transition-colors ${
                  isActive ? "text-[#663399]" : "text-gray-500"
                }`}
              >
                <Icon className="w-5 h-5" />
                <span className="text-xs">{item.label}</span>
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
