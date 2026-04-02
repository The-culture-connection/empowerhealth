import { Outlet, NavLink } from "react-router";
import { Home, FileText, Code2, Users, BarChart3, FileBarChart, Bell } from "lucide-react";

export function Layout() {
  const navItems = [
    { to: "/", label: "Dashboard", icon: Home },
    { to: "/documentation", label: "Documentation", icon: FileText },
    { to: "/technology", label: "Technology Overview", icon: Code2 },
    { to: "/users-roles", label: "Users & Roles", icon: Users },
    { to: "/analytics", label: "Analytics", icon: BarChart3 },
    { to: "/reports", label: "Reports", icon: FileBarChart },
    { to: "/notifications", label: "Notifications", icon: Bell },
  ];

  return (
    <div className="flex min-h-screen" style={{ backgroundColor: 'var(--eh-background)' }}>
      {/* Left Sidebar Navigation */}
      <aside className="w-64 border-r flex flex-col" style={{ 
        borderColor: 'var(--lavender-200)',
        backgroundColor: 'var(--eh-surface)'
      }}>
        {/* Logo / Brand */}
        <div className="p-6 border-b" style={{ borderColor: 'var(--lavender-200)' }}>
          <h1 className="text-xl" style={{ color: 'var(--eh-primary)' }}>
            EmpowerHealth
          </h1>
          <p className="text-sm mt-1" style={{ color: 'var(--warm-500)' }}>
            Admin Dashboard
          </p>
        </div>

        {/* Navigation Links */}
        <nav className="flex-1 p-4 space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.to === "/"}
                className={({ isActive }) =>
                  `flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                    isActive
                      ? "shadow-sm"
                      : "hover:shadow-sm"
                  }`
                }
                style={({ isActive }) => ({
                  backgroundColor: isActive ? 'var(--lavender-200)' : 'transparent',
                  color: isActive ? 'var(--lavender-600)' : 'var(--warm-600)',
                })}
              >
                <Icon className="w-5 h-5" />
                <span>{item.label}</span>
              </NavLink>
            );
          })}
        </nav>

        {/* Footer Info */}
        <div className="p-4 border-t text-xs space-y-1" style={{ 
          borderColor: 'var(--lavender-200)',
          color: 'var(--warm-500)'
        }}>
          <div>Build v2.3.1</div>
          <div>Last updated: Mar 1, 2026</div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col">
        {/* Top Bar */}
        <header className="border-b px-8 py-4 flex items-center justify-between" style={{ 
          borderColor: 'var(--lavender-200)',
          backgroundColor: 'white'
        }}>
          <div className="flex items-center gap-6">
            <div>
              <h2 className="text-lg" style={{ color: 'var(--warm-600)' }}>
                Maternal Health Research Institute
              </h2>
              <p className="text-sm" style={{ color: 'var(--warm-400)' }}>
                Research Administrator
              </p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            {/* Environment Badge */}
            <div className="px-4 py-2 rounded-full text-sm" style={{ 
              backgroundColor: 'var(--lavender-100)',
              color: 'var(--lavender-600)'
            }}>
              Production
            </div>

            {/* Build Version */}
            <div className="px-4 py-2 rounded-full text-sm" style={{ 
              backgroundColor: 'var(--warm-100)',
              color: 'var(--warm-600)'
            }}>
              v2.3.1
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
}