import { UserPlus, Edit, Trash2, Shield, Eye, MessageSquare, Loader2 } from "lucide-react";
import { useState, useEffect } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { 
  assignRole, 
  revokeRole, 
  getUsersByRole, 
  findUserByEmail,
  UserRole as UserRoleType
} from "../../lib/userManagement";
import { format } from "date-fns";

interface User {
  uid: string;
  email: string;
  displayName?: string;
  role: UserRoleType;
  addedDate: Date;
}

const roleMap: Record<UserRoleType, { id: string; name: string; description: string; icon: typeof Shield; color: string; bgColor: string }> = {
  admin: {
    id: "admin",
    name: "Admin",
    description: "Full system control",
    icon: Shield,
    color: 'var(--lavender-600)',
    bgColor: 'var(--lavender-100)',
  },
  research_partner: {
    id: "research_partner",
    name: "Research Partner",
    description: "View anonymized data only",
    icon: Eye,
    color: 'var(--warm-600)',
    bgColor: 'var(--warm-100)',
  },
  community_manager: {
    id: "community_manager",
    name: "Community Manager",
    description: "Manage content + messages",
    icon: MessageSquare,
    color: '#4ade80',
    bgColor: 'var(--success-light)',
  },
};

export function UsersAndRoles() {
  const { userProfile } = useAuth();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddUser, setShowAddUser] = useState(false);
  const [newUserEmail, setNewUserEmail] = useState("");
  const [newUserName, setNewUserName] = useState("");
  const [newUserRole, setNewUserRole] = useState<UserRoleType>("research_partner");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  useEffect(() => {
    loadUsers();
  }, []);

  async function loadUsers() {
    setLoading(true);
    try {
      const allUsers: User[] = [];
      
      // Load users from all role collections
      for (const role of Object.keys(roleMap) as UserRoleType[]) {
        const roleUsers = await getUsersByRole(role);
        allUsers.push(...roleUsers.map(u => ({
          uid: u.uid,
          email: u.email,
          displayName: u.displayName,
          role: u.role,
          addedDate: u.createdAt || new Date(),
        })));
      }
      
      setUsers(allUsers);
    } catch (err: any) {
      setError(err.message || "Failed to load users");
    } finally {
      setLoading(false);
    }
  }

  async function handleAddUser() {
    if (!userProfile) return;
    
    setError("");
    setSuccess("");
    setSubmitting(true);

    try {
      // Try to find user by email
      let user = await findUserByEmail(newUserEmail);
      
      if (!user) {
        // User doesn't exist yet - we'll create the role doc anyway
        // The user will need to sign up first, then they'll get the role
        user = {
          uid: `pending_${Date.now()}`, // Temporary ID
          email: newUserEmail,
          displayName: newUserName || undefined,
        };
      }

      await assignRole(
        user.uid,
        user.email,
        user.displayName || newUserName || newUserEmail,
        newUserRole,
        userProfile.uid
      );

      setSuccess(`Role assigned successfully. ${!user.uid.startsWith('pending_') ? 'User can now access the dashboard.' : 'User will need to sign up first.'}`);
      setNewUserEmail("");
      setNewUserName("");
      setNewUserRole("research_partner");
      setShowAddUser(false);
      await loadUsers();
    } catch (err: any) {
      setError(err.message || "Failed to assign role");
    } finally {
      setSubmitting(false);
    }
  }

  async function handleRevokeRole(uid: string, role: UserRoleType) {
    if (!userProfile || !confirm("Are you sure you want to revoke this role?")) return;

    try {
      await revokeRole(uid, role, userProfile.uid);
      setSuccess("Role revoked successfully");
      await loadUsers();
    } catch (err: any) {
      setError(err.message || "Failed to revoke role");
    }
  }

  const roles = Object.values(roleMap);

  const getRoleInfo = (roleId: UserRoleType) => {
    return roleMap[roleId] || roles[0];
  };

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin" style={{ color: 'var(--lavender-500)' }} />
      </div>
    );
  }

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

        {error && (
          <div className="mb-4 p-4 rounded-xl" style={{ 
            backgroundColor: '#fee2e2',
            color: '#dc2626',
          }}>
            {error}
          </div>
        )}

        {success && (
          <div className="mb-4 p-4 rounded-xl" style={{ 
            backgroundColor: '#d1fae5',
            color: '#065f46',
          }}>
            {success}
          </div>
        )}

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
                  Full Name (Optional)
                </label>
                <input
                  type="text"
                  value={newUserName}
                  onChange={(e) => setNewUserName(e.target.value)}
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
                  Email Address *
                </label>
                <input
                  type="email"
                  value={newUserEmail}
                  onChange={(e) => setNewUserEmail(e.target.value)}
                  placeholder="email@example.com"
                  required
                  className="w-full px-4 py-3 rounded-xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: 'var(--lavender-200)',
                  }}
                />
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
                  Assign Role
                </label>
                <select
                  value={newUserRole}
                  onChange={(e) => setNewUserRole(e.target.value as UserRoleType)}
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
                onClick={handleAddUser}
                disabled={!newUserEmail || submitting}
                className="px-6 py-3 rounded-xl shadow-sm hover:shadow-md transition-all disabled:opacity-50"
                style={{
                  backgroundColor: 'var(--lavender-500)',
                  color: 'white',
                }}
              >
                {submitting ? "Assigning..." : "Assign Role"}
              </button>
              <button
                onClick={() => {
                  setShowAddUser(false);
                  setError("");
                  setSuccess("");
                }}
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
                  {users.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="px-6 py-8 text-center" style={{ color: 'var(--warm-500)' }}>
                        No users found
                      </td>
                    </tr>
                  ) : (
                    users.map((user, index) => {
                      const roleInfo = getRoleInfo(user.role);
                      return (
                        <tr
                          key={user.uid}
                          className={index !== users.length - 1 ? "border-b" : ""}
                          style={{ borderColor: 'var(--lavender-100)' }}
                        >
                          <td className="px-6 py-4">
                            <div>
                              <div style={{ color: 'var(--warm-600)' }}>
                                {user.displayName || 'No name'}
                              </div>
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
                              {format(user.addedDate, 'MMM d, yyyy')}
                            </span>
                          </td>
                          <td className="px-6 py-4">
                            <div className="flex gap-2">
                              <button
                                onClick={() => handleRevokeRole(user.uid, user.role)}
                                className="p-2 rounded-lg hover:bg-opacity-10 transition-colors"
                                style={{ color: 'var(--destructive)' }}
                                title="Revoke Role"
                              >
                                <Trash2 className="w-4 h-4" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
