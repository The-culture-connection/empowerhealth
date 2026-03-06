import { CheckCircle2, Clock } from "lucide-react";

interface ServiceStatus {
  name: string;
  status: "operational" | "monitoring";
  uptime: string;
  message: string;
}

export function SystemStatus() {
  const serviceStatus: ServiceStatus[] = [
    {
      name: "API Services",
      status: "operational",
      uptime: "99.98%",
      message: "All endpoints operating within expected parameters",
    },
    {
      name: "Data Storage",
      status: "operational",
      uptime: "99.99%",
      message: "Database systems maintaining consistent availability",
    },
    {
      name: "Analytics Pipeline",
      status: "operational",
      uptime: "99.95%",
      message: "Data processing jobs completing on schedule",
    },
    {
      name: "User Segmentation",
      status: "operational",
      uptime: "99.97%",
      message: "Cohort analysis systems functioning as expected",
    },
    {
      name: "Notification Delivery",
      status: "operational",
      uptime: "99.96%",
      message: "Message distribution proceeding normally",
    },
    {
      name: "Authentication Services",
      status: "operational",
      uptime: "99.99%",
      message: "User access systems maintaining security protocols",
    },
  ];

  return (
    <div>
      {/* Overall Status Header */}
      <div
        className="p-8 rounded-2xl border mb-8"
        style={{
          backgroundColor: 'white',
          borderColor: '#e0e0e0',
        }}
      >
        <div className="flex items-center gap-3 mb-4">
          <div
            className="w-4 h-4 rounded-full"
            style={{ backgroundColor: '#2e7d32' }}
          />
          <h2 className="text-2xl" style={{ color: '#424242' }}>
            All Systems Operational
          </h2>
        </div>
        <p className="text-base leading-relaxed" style={{ color: '#616161' }}>
          All core services are currently operating within expected parameters. System uptime remains consistent with operational targets across all monitored components.
        </p>
      </div>

      {/* Service Status Grid */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3 mb-8">
        {serviceStatus.map((service) => {
          return (
            <div
              key={service.name}
              className="p-6 rounded-2xl border"
              style={{
                backgroundColor: 'white',
                borderColor: '#e0e0e0',
              }}
            >
              <div className="flex items-start justify-between mb-4">
                <h3 className="text-base" style={{ color: '#424242' }}>
                  {service.name}
                </h3>
                <div className="flex items-center gap-2">
                  <div
                    className="w-3 h-3 rounded-full"
                    style={{
                      backgroundColor: service.status === 'operational' ? '#2e7d32' : '#d32f2f'
                    }}
                  />
                  <span className="text-xs" style={{ color: '#757575' }}>
                    {service.status === 'operational' ? 'Operational' : 'Issue Detected'}
                  </span>
                </div>
              </div>

              <div
                className="mb-4 p-4 rounded-lg"
                style={{
                  backgroundColor: '#fafafa',
                }}
              >
                <div className="text-xs mb-1" style={{ color: '#757575' }}>
                  Uptime (30 days)
                </div>
                <div className="text-2xl" style={{ color: '#424242' }}>
                  {service.uptime}
                </div>
              </div>

              <p className="text-sm leading-relaxed" style={{ color: '#757575' }}>
                {service.message}
              </p>
            </div>
          );
        })}
      </div>

      {/* Monitoring Information */}
      <div
        className="p-8 rounded-2xl border"
        style={{
          backgroundColor: '#fafafa',
          borderColor: '#e0e0e0',
        }}
      >
        <h2 className="text-xl mb-4" style={{ color: '#424242' }}>
          System Monitoring
        </h2>
        <div className="grid gap-6 md:grid-cols-2">
          <div>
            <h3 className="text-sm mb-2" style={{ color: '#757575' }}>
              Status Indicators
            </h3>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full" style={{ backgroundColor: '#2e7d32' }} />
                <span className="text-sm" style={{ color: '#616161' }}>
                  <strong>Operational:</strong> Service functioning normally within expected parameters
                </span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full" style={{ backgroundColor: '#d32f2f' }} />
                <span className="text-sm" style={{ color: '#616161' }}>
                  <strong>Issue Detected:</strong> Service experiencing degraded performance or outage
                </span>
              </div>
            </div>
          </div>
          <div>
            <h3 className="text-sm mb-2" style={{ color: '#757575' }}>
              Uptime Calculation
            </h3>
            <p className="text-sm leading-relaxed" style={{ color: '#616161' }}>
              Uptime percentages reflect the proportion of time services remain accessible and responsive to requests over a rolling 30-day period. Values above 99.9% indicate excellent reliability.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}