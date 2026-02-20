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
    <div className="min-h-screen bg-gradient-to-b from-white to-[#f8f6f8] pb-20">
      {/* Main Content */}
      <main className="max-w-2xl mx-auto">
        <Outlet />
      </main>

      {/* Floating AI Assistant Button */}
      <button
        className="fixed bottom-24 right-6 w-14 h-14 bg-gradient-to-br from-[#663399] to-[#8855bb] text-white rounded-full shadow-lg flex items-center justify-center z-10 hover:shadow-xl transition-shadow"
        aria-label="Ask for support"
      >
        <MessageSquare className="w-6 h-6" />
      </button>

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
