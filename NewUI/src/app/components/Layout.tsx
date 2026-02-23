import { Outlet, Link, useLocation } from "react-router";
import { Home, BookOpen, FileText, Heart, MessageCircle, User, Search, MessageSquare } from "lucide-react";

export function Layout() {
  const location = useLocation();

  const navItems = [
    { path: "/", icon: Home, label: "Home" },
    { path: "/learning", icon: BookOpen, label: "Learn" },
    { path: "/journal", icon: Heart, label: "Journal" },
    { path: "/community", icon: MessageCircle, label: "Community" },
    { path: "/profile", icon: User, label: "Profile" },
  ];

  return (
    <div className="min-h-screen bg-[#faf8f4] pb-20 relative overflow-hidden">
      {/* Subtle warm texture overlay */}
      <div 
        className="fixed inset-0 opacity-[0.02] pointer-events-none"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23663399' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`
        }}
      />

      {/* Main Content */}
      <main className="max-w-2xl mx-auto relative">
        <Outlet />
      </main>

      {/* Floating AI Assistant Button */}
      <button
        className="fixed bottom-24 right-6 w-14 h-14 bg-gradient-to-br from-[#8b7aa8] to-[#b89fb5] text-white rounded-full shadow-[0_8px_24px_rgba(102,51,153,0.3)] flex items-center justify-center z-10 hover:shadow-[0_12px_32px_rgba(102,51,153,0.4)] transition-all hover:scale-105"
        aria-label="Ask for support"
      >
        <MessageSquare className="w-6 h-6 stroke-[1.5]" />
      </button>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white/90 backdrop-blur-xl border-t border-[#e8dfe8] z-20 shadow-[0_-8px_32px_rgba(102,51,153,0.08)]">
        <div className="max-w-2xl mx-auto flex justify-around items-center h-16 px-4">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex flex-col items-center justify-center gap-1 transition-colors ${
                  isActive ? "text-[#663399]" : "text-[#a89cb5]"
                }`}
              >
                <Icon className="w-5 h-5 stroke-[1.5]" />
                <span className="text-xs font-light">{item.label}</span>
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
