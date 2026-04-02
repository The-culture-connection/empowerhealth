Design a “Technology Dashboard” section for the EmpowerHealth Admin Web App.

STYLE:
Warm, calm, mission-driven (not clinical). Lavender accents, soft neutrals, rounded cards, generous whitespace. Avoid harsh blues/medical dashboard look.

LAYOUT:
Left sidebar navigation already exists. Create two pages under “Technology”:
1) Releases & Build Info
2) System Status

PAGE 1: Releases & Build Info
Top: “Current Release” hero card
- Full version: 1.2.3+13
- Environment badge (Pilot / Production)
- Deployed timestamp
- Git commit SHA with clickable GitHub link
- “View feature dossier” button

Below: Release History table (last 13)
Columns:
- Build (1.2.3+13)
- Deployed At
- Status (success/failed/in progress)
- Commit (short SHA)
- Notes (from dossier summary)
Row click opens release detail drawer.

Release Detail Drawer (right-side panel):
- Version + environment + commit link
- Feature dossier with:
  - Search bar
  - Category accordion sections:
    After Visit Summary, Learning Modules, Provider Search, Community, Journal, Birth Plan, Notifications, Admin
  - Each item shows name, short description, status badge (New / Improved / Fixed), tags

Include “Copy version” and “Copy commit” buttons.

PAGE 2: System Status
Top: Status overview tiles (grid)
Tiles:
- API / App Health (Railway)
- Firebase
- Analytics Jobs
- Segmentation Jobs
- Notification Sender
Each tile shows:
- Status pill: Operational / Degraded / Down
- Last checked time
- Latency (ms)
- Short message

Below: “Recent Incidents” list
- severity icon
- summary
- startedAt → resolvedAt
- related release version

Below: “Live Metrics” cards:
- Pending notifications queue
- Last successful job run times
- Error rate trend (simple line chart)
- Uptime last 24h (sparkline)

All components should feel quiet, safe, and easy to scan.