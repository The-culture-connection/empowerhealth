import { Outlet, NavLink } from "react-router";

export function TechnologyLayout() {
  const tabs = [
    { to: "/technology", label: "Platform Overview", end: true },
    { to: "/technology/instructions", label: "Instructions", end: false },
  ];

  return (
    <div className="p-8">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl mb-2" style={{ color: '#424242' }}>
            Technology Overview
          </h1>
          <p style={{ color: '#616161' }}>
            Platform releases, feature catalog, and implementation details
          </p>
        </div>

        {/* Sub-navigation tabs */}
        <div className="flex gap-2 mb-8 border-b" style={{ borderColor: '#e0e0e0' }}>
          {tabs.map((tab) => (
            <NavLink
              key={tab.to}
              to={tab.to}
              end={tab.end}
              className={({ isActive }) =>
                `px-6 py-3 transition-all border-b-2 ${
                  isActive ? "border-b-2" : "border-transparent"
                }`
              }
              style={({ isActive }) => ({
                color: isActive ? '#9575cd' : '#757575',
                borderBottomColor: isActive ? '#9575cd' : 'transparent',
              })}
            >
              {tab.label}
            </NavLink>
          ))}
        </div>

        <Outlet />
      </div>
    </div>
  );
}
