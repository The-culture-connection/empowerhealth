import { Link } from "react-router";
import { Bell, Stethoscope, ChevronRight, Flag, FolderSearch, MessageSquare, Tags } from "lucide-react";
import { useAuth } from "../../contexts/AuthContext";

export function ModerationHub() {
  const { isAdmin } = useAuth();

  return (
    <div className="p-8 max-w-3xl">
      <h1 className="text-2xl font-semibold mb-2" style={{ color: "var(--warm-600)" }}>
        Moderation and Communication
      </h1>
      <p className="text-sm mb-8" style={{ color: "var(--warm-500)" }}>
        Push messaging and provider submissions (admin tools).
      </p>

      <ul className="space-y-3">
        <li>
          <Link
            to="/moderation/push"
            className="flex items-center gap-4 p-5 rounded-2xl border transition-shadow hover:shadow-md"
            style={{
              backgroundColor: "white",
              borderColor: "var(--lavender-200)",
              color: "var(--warm-600)",
            }}
          >
            <div
              className="flex h-12 w-12 items-center justify-center rounded-xl"
              style={{ backgroundColor: "var(--lavender-100)" }}
            >
              <Bell className="h-6 w-6" style={{ color: "var(--lavender-600)" }} />
            </div>
            <div className="flex-1 min-w-0">
              <div className="font-medium">Push notifications</div>
              <div className="text-sm mt-0.5" style={{ color: "var(--warm-500)" }}>
                Compose FCM topic broadcasts and view recent sends.
              </div>
            </div>
            <ChevronRight className="h-5 w-5 shrink-0 opacity-50" />
          </Link>
        </li>

        {isAdmin() && (
          <li>
            <Link
              to="/moderation/provider-directory"
              className="flex items-center gap-4 p-5 rounded-2xl border transition-shadow hover:shadow-md"
              style={{
                backgroundColor: "white",
                borderColor: "var(--lavender-200)",
                color: "var(--warm-600)",
              }}
            >
              <div
                className="flex h-12 w-12 items-center justify-center rounded-xl"
                style={{ backgroundColor: "var(--lavender-100)" }}
              >
                <FolderSearch className="h-6 w-6" style={{ color: "var(--lavender-600)" }} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-medium">Provider directory lookup</div>
                <div className="text-sm mt-0.5" style={{ color: "var(--warm-500)" }}>
                  Full Firestore metadata, claims, hide from app, or delete document.
                </div>
              </div>
              <ChevronRight className="h-5 w-5 shrink-0 opacity-50" />
            </Link>
          </li>
        )}
        {isAdmin() && (
          <li>
            <Link
              to="/moderation/providers"
              className="flex items-center gap-4 p-5 rounded-2xl border transition-shadow hover:shadow-md"
              style={{
                backgroundColor: "white",
                borderColor: "var(--lavender-200)",
                color: "var(--warm-600)",
              }}
            >
              <div
                className="flex h-12 w-12 items-center justify-center rounded-xl"
                style={{ backgroundColor: "var(--lavender-100)" }}
              >
                <Stethoscope className="h-6 w-6" style={{ color: "var(--lavender-600)" }} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-medium">Provider moderation</div>
                <div className="text-sm mt-0.5" style={{ color: "var(--warm-500)" }}>
                  Approve or reject user-submitted providers in UserProviders.
                </div>
              </div>
              <ChevronRight className="h-5 w-5 shrink-0 opacity-50" />
            </Link>
          </li>
        )}
        {isAdmin() && (
          <li>
            <Link
              to="/moderation/reports"
              className="flex items-center gap-4 p-5 rounded-2xl border transition-shadow hover:shadow-md"
              style={{
                backgroundColor: "white",
                borderColor: "var(--lavender-200)",
                color: "var(--warm-600)",
              }}
            >
              <div
                className="flex h-12 w-12 items-center justify-center rounded-xl"
                style={{ backgroundColor: "var(--lavender-100)" }}
              >
                <Flag className="h-6 w-6" style={{ color: "var(--lavender-600)" }} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-medium">Provider listing reports</div>
                <div className="text-sm mt-0.5" style={{ color: "var(--warm-500)" }}>
                  Inaccurate or harmful listing reports from the app.
                </div>
              </div>
              <ChevronRight className="h-5 w-5 shrink-0 opacity-50" />
            </Link>
          </li>
        )}
        {isAdmin() && (
          <li>
            <Link
              to="/moderation/reviews"
              className="flex items-center gap-4 p-5 rounded-2xl border transition-shadow hover:shadow-md"
              style={{
                backgroundColor: "white",
                borderColor: "var(--lavender-200)",
                color: "var(--warm-600)",
              }}
            >
              <div
                className="flex h-12 w-12 items-center justify-center rounded-xl"
                style={{ backgroundColor: "var(--lavender-100)" }}
              >
                <MessageSquare className="h-6 w-6" style={{ color: "var(--lavender-600)" }} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-medium">Provider reviews</div>
                <div className="text-sm mt-0.5" style={{ color: "var(--warm-500)" }}>
                  Recent community reviews (read-only inbox).
                </div>
              </div>
              <ChevronRight className="h-5 w-5 shrink-0 opacity-50" />
            </Link>
          </li>
        )}
        {isAdmin() && (
          <li>
            <Link
              to="/moderation/identity-claims"
              className="flex items-center gap-4 p-5 rounded-2xl border transition-shadow hover:shadow-md"
              style={{
                backgroundColor: "white",
                borderColor: "var(--lavender-200)",
                color: "var(--warm-600)",
              }}
            >
              <div
                className="flex h-12 w-12 items-center justify-center rounded-xl"
                style={{ backgroundColor: "var(--lavender-100)" }}
              >
                <Tags className="h-6 w-6" style={{ color: "var(--lavender-600)" }} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-medium">Identity claims</div>
                <div className="text-sm mt-0.5" style={{ color: "var(--warm-500)" }}>
                  Verify or reject provider_identity_claims.
                </div>
              </div>
              <ChevronRight className="h-5 w-5 shrink-0 opacity-50" />
            </Link>
          </li>
        )}
      </ul>
    </div>
  );
}
