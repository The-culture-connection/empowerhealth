import { Outlet, Link, useLocation } from "react-router";
import { Home, BookOpen, FileText, Heart, MessageCircle, User, Moon, Sun } from "lucide-react";
import { useState, useEffect } from "react";

export function Layout() {
  const location = useLocation();
  const [darkMode, setDarkMode] = useState(false);

  useEffect(() => {
    const isDark = localStorage.getItem('darkMode') === 'true';
    setDarkMode(isDark);
    if (isDark) {
      document.documentElement.classList.add('dark');
    }
  }, []);

  const toggleDarkMode = () => {
    const newDarkMode = !darkMode;
    setDarkMode(newDarkMode);
    localStorage.setItem('darkMode', String(newDarkMode));
    if (newDarkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  const navItems = [
    { path: "/", icon: Home, label: "Home" },
    { path: "/learning", icon: BookOpen, label: "Learn" },
    { path: "/journal", icon: Heart, label: "Journal" },
    { path: "/community", icon: MessageCircle, label: "Community" },
    { path: "/profile", icon: User, label: "You" },
  ];

  return (
    <div className="min-h-screen bg-[#faf8f4] dark:bg-[#1a1520] pb-20 relative overflow-hidden transition-colors duration-500">
      {/* Subtle texture overlay */}
      <div 
        className="fixed inset-0 opacity-[0.015] pointer-events-none"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='%23663399' fill-opacity='1'%3E%3Ccircle cx='2' cy='2' r='1'/%3E%3Ccircle cx='50' cy='50' r='1'/%3E%3C/g%3E%3C/svg%3E")`
        }}
      />

      {/* Warm ambient glow */}
      <div className="fixed inset-0 opacity-0 dark:opacity-25 pointer-events-none transition-opacity duration-500">
        <div className="absolute top-0 right-1/4 w-[500px] h-[500px] rounded-full bg-[#d4a574] blur-[150px]"></div>
        <div className="absolute bottom-1/4 left-1/4 w-[400px] h-[400px] rounded-full bg-[#b899d4] blur-[120px]"></div>
      </div>

      {/* Main Content */}
      <main className="max-w-2xl mx-auto relative">
        <Outlet />
      </main>

      {/* Dark Mode Toggle - Like a lamp switch */}
      <button
        onClick={toggleDarkMode}
        className="fixed top-6 right-6 w-11 h-11 bg-white dark:bg-[#2a2435] rounded-full shadow-[0_8px_32px_rgba(102,51,153,0.15)] dark:shadow-[0_8px_32px_rgba(0,0,0,0.4)] flex items-center justify-center z-10 hover:scale-105 transition-all duration-300 border border-[#e8e0f0]/40 dark:border-[#3a3043]/40"
        aria-label="Toggle dark mode"
      >
        {darkMode ? (
          <Sun className="w-5 h-5 text-[#d4a574] stroke-[1.5]" />
        ) : (
          <Moon className="w-5 h-5 text-[#663399] stroke-[1.5]" />
        )}
      </button>

      {/* Bottom Navigation - Like a cushioned panel */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white/95 dark:bg-[#2a2435]/95 backdrop-blur-xl border-t border-[#e8e0f0] dark:border-[#3a3043] z-20 shadow-[0_-16px_48px_rgba(102,51,153,0.12)] dark:shadow-[0_-16px_56px_rgba(0,0,0,0.4)] transition-all duration-500">
        <div className="max-w-2xl mx-auto flex justify-around items-center h-20 px-6">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex flex-col items-center justify-center gap-1.5 transition-all duration-300 ${
                  isActive 
                    ? "text-[#663399] dark:text-[#d4a574]" 
                    : "text-[#cbbec9] dark:text-[#75657d] hover:text-[#75657d] dark:hover:text-[#cbbec9]"
                }`}
              >
                <div className={`transition-all duration-300 ${isActive ? "scale-110" : "scale-100"}`}>
                  <Icon className="w-5 h-5 stroke-[1.5]" />
                </div>
                <span className="text-[11px] font-light tracking-wide">{item.label}</span>
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
}