import { UserPlus, Edit, Trash2, Shield, Eye, MessageSquare } from "lucide-react";
import { useState } from "react";

type Role = "admin" | "research" | "community";

interface User {
  id: string;
  name: string;
  email: string;
  role: Role;
  addedDate: string;
}

export function UsersAndRoles() {
  const [users, setUsers] = useState<User[]>([
    {
      id: "1",
      name: "Dr. Sarah Chen",
      email: "sarah.chen@research.org",
      role: "admin",
      addedDate: "Jan 15, 2026",
    },
    {
      id: "2",
      name: "Dr. Michael Roberts",
      email: "m.roberts@university.edu",
      role: "research",
      addedDate: "Feb 1, 2026",
    },
    {
      id: "3",
      name: "Emma Thompson",
      email: "emma.t@empowerhealth.org",
      role: "community",
      addedDate: "Feb 20, 2026",
    },
  ]);

  const [showAddUser, setShowAddUser] = useState(false);

  const roles = [
    {
      id: "admin" as Role,
      name: "Admin",
      description: "Full system control",
      icon: Shield,
      color: 'var(--lavender-600)',
      bgColor: 'var(--lavender-100)',
    },
    {
      id: "research" as Role,
      name: "Research Partner",
      description: "View anonymized data only",
      icon: Eye,
      color: 'var(--warm-600)',
      bgColor: 'var(--warm-100)',
    },
    {
      id: "community" as Role,
      name: "Community Manager",
      description: "Manage content + messages",
      icon: MessageSquare,
      color: '#4ade80',
      bgColor: 'var(--success-light)',
    },
  ];

  const getRoleInfo = (roleId: Role) => {
    return roles.find((r) => r.id === roleId) || roles[0];
  };

  return (
    <div className="p-8">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-3xl mb-2" style={{ color: 'var(--warm-600)' }}>
              Users & Roles
            </h1>
            <p style={{ color: 'var(--warm-400)' }}>
              Role-based access control and user management
            </p>
          </div>
          <button
            onClick={() => setShowAddUser(!showAddUser)}
            className="flex items-center gap-2 px-6 py-3 rounded-xl shadow-sm hover:shadow-md transition-all"
            style={{
              backgroundColor: 'var(--lavender-500)',
              color: 'white',
            }}
          >
            <UserPlus className="w-5 h-5" />
            Add User
          </button>
        </div>

        {/* Role Definitions */}
        <section className="mb-8">
          <h2 className="mb-4" style={{ color: 'var(--warm-600)' }}>
            Role Definitions
          </h2>
          <div className="grid gap-4 md:grid-cols-3">
            {roles.map((role) => {
              const Icon = role.icon;
              return (
                <div
                  key={role.id}
                  className="p-6 rounded-2xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: 'var(--lavender-200)',
                  }}
                >
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center mb-4"
                    style={{ backgroundColor: role.bgColor }}
                  >
                    <Icon className="w-6 h-6" style={{ color: role.color }} />
                  </div>
                  <h3 className="mb-2" style={{ color: 'var(--warm-600)' }}>
                    {role.name}
                  </h3>
                  <p className="text-sm" style={{ color: 'var(--warm-500)' }}>
                    {role.description}
                  </p>
                </div>
              );
            })}
          </div>
        </section>

        {/* Add User Panel */}
        {showAddUser && (
          <div
            className="mb-8 p-6 rounded-2xl border"
            style={{
              backgroundColor: 'var(--lavender-50)',
              borderColor: 'var(--lavender-200)',
            }}
          >
            <h3 className="mb-4" style={{ color: 'var(--lavender-600)' }}>
              User Onboarding
            </h3>
            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
                  Full Name
                </label>
                <input
                  type="text"
                  placeholder="Enter full name"
                  className="w-full px-4 py-3 rounded-xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: 'var(--lavender-200)',
                  }}
                />
              </div>
              <div>
                <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
                  Email Address
                </label>
                <input
                  type="email"
                  placeholder="email@example.com"
                  className="w-full px-4 py-3 rounded-xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: 'var(--lavender-200)',
                  }}
                />
              </div>
              <div>
                <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
                  Assign Role
                </label>
                <select
                  className="w-full px-4 py-3 rounded-xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: 'var(--lavender-200)',
                  }}
                >
                  {roles.map((role) => (
                    <option key={role.id} value={role.id}>
                      {role.name} - {role.description}
                    </option>
                  ))}
                </select>
              </div>
            </div>
            <div className="flex gap-3 mt-4">
              <button
                className="px-6 py-3 rounded-xl shadow-sm hover:shadow-md transition-all"
                style={{
                  backgroundColor: 'var(--lavender-500)',
                  color: 'white',
                }}
              >
                Send Invitation
              </button>
              <button
                onClick={() => setShowAddUser(false)}
                className="px-6 py-3 rounded-xl transition-all"
                style={{
                  backgroundColor: 'var(--warm-100)',
                  color: 'var(--warm-600)',
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {/* Current Users */}
        <section>
          <h2 className="mb-4" style={{ color: 'var(--warm-600)' }}>
            Current Users
          </h2>
          <div
            className="rounded-2xl border overflow-hidden"
            style={{
              backgroundColor: 'white',
              borderColor: 'var(--lavender-200)',
            }}
          >
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr style={{ backgroundColor: 'var(--lavender-50)' }}>
                    <th
                      className="text-left px-6 py-4 text-sm"
                      style={{ color: 'var(--warm-600)' }}
                    >
                      User
                    </th>
                    <th
                      className="text-left px-6 py-4 text-sm"
                      style={{ color: 'var(--warm-600)' }}
                    >
                      Role
                    </th>
                    <th
                      className="text-left px-6 py-4 text-sm"
                      style={{ color: 'var(--warm-600)' }}
                    >
                      Added Date
                    </th>
                    <th
                      className="text-left px-6 py-4 text-sm"
                      style={{ color: 'var(--warm-600)' }}
                    >
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user, index) => {
                    const roleInfo = getRoleInfo(user.role);
                    return (
                      <tr
                        key={user.id}
                        className={index !== users.length - 1 ? "border-b" : ""}
                        style={{ borderColor: 'var(--lavender-100)' }}
                      >
                        <td className="px-6 py-4">
                          <div>
                            <div style={{ color: 'var(--warm-600)' }}>{user.name}</div>
                            <div className="text-sm" style={{ color: 'var(--warm-400)' }}>
                              {user.email}
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div
                            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-sm"
                            style={{
                              backgroundColor: roleInfo.bgColor,
                              color: roleInfo.color,
                            }}
                          >
                            <roleInfo.icon className="w-4 h-4" />
                            {roleInfo.name}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <span className="text-sm" style={{ color: 'var(--warm-500)' }}>
                            {user.addedDate}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex gap-2">
                            <button
                              className="p-2 rounded-lg hover:bg-opacity-10 transition-colors"
                              style={{ color: 'var(--lavender-500)' }}
                            >
                              <Edit className="w-4 h-4" />
                            </button>
                            <button
                              className="p-2 rounded-lg hover:bg-opacity-10 transition-colors"
                              style={{ color: 'var(--destructive)' }}
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
