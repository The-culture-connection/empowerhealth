import { Send, Calendar, Users, Sparkles, Loader2 } from "lucide-react";
import { useState, useEffect } from "react";
import {
  sendNotification,
  subscribeNotificationLogs,
  type NotificationLogRow,
  type NotificationSegment,
} from "../../lib/notifications";
import { format } from "date-fns";

export function Notifications() {
  const [messageType, setMessageType] = useState("");
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [deepLink, setDeepLink] = useState("");
  const [scheduledDate, setScheduledDate] = useState("");
  const [audience, setAudience] = useState<NotificationSegment>("all");
  const [sending, setSending] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [recentNotifications, setRecentNotifications] = useState<NotificationLogRow[]>([]);
  const [loadingLogs, setLoadingLogs] = useState(true);

  useEffect(() => {
    const unsub = subscribeNotificationLogs(
      25,
      (rows) => {
        setRecentNotifications(rows);
        setLoadingLogs(false);
      },
      () => setLoadingLogs(false),
    );
    return () => unsub();
  }, []);

  useEffect(() => {
    if (messageType === "affirmation") setMessageType("");
  }, [messageType]);

  async function handleSend() {
    if (!title || !body) {
      setError("Please fill in title and body");
      return;
    }

    setError("");
    setSuccess("");
    setSending(true);

    try {
      await sendNotification({
        title,
        body,
        deepLink: deepLink || undefined,
        segment: audience,
        scheduledFor: scheduledDate ? new Date(scheduledDate) : undefined,
      });

      setSuccess("Notification sent successfully!");
      setTitle("");
      setBody("");
      setDeepLink("");
      setScheduledDate("");
      setMessageType("");
    } catch (err: any) {
      setError(err.message || "Failed to send notification");
    } finally {
      setSending(false);
    }
  }

  const notificationTypes = [
    {
      id: "learning",
      title: "New Learning Module Alert",
      description: "Notify users when new educational content is available",
      icon: "📚",
      color: 'var(--lavender-500)',
    },
    {
      id: "todo",
      title: "To-Do Reminders",
      description: "Gentle reminders for upcoming tasks or appointments",
      icon: "✓",
      color: 'var(--warning)',
    },
    {
      id: "trimester",
      title: "Trimester Transitions",
      description: "Milestone messages as users enter new pregnancy phases",
      icon: "🌱",
      color: 'var(--success)',
    },
    {
      id: "community",
      title: "Community Replies",
      description: "Notifications when someone responds to user posts",
      icon: "💬",
      color: '#06b6d4',
    },
  ];

  const audienceOptions: { value: NotificationSegment; label: string }[] = [
    { value: "all", label: "All Active Users" },
    { value: "first_trimester", label: "First Trimester" },
    { value: "second_trimester", label: "Second Trimester" },
    { value: "third_trimester", label: "Third Trimester" },
    { value: "postpartum", label: "Postpartum (0-12 weeks)" },
    { value: "navigator", label: "Navigator-Assisted Users" },
    { value: "self_directed", label: "Self-Directed Users" },
  ];

  return (
    <div className="p-8">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl mb-2" style={{ color: 'var(--warm-600)' }}>
            Push Notifications
          </h1>
          <p style={{ color: 'var(--warm-400)' }}>
            Gentle, supportive messaging to keep users engaged and informed
          </p>
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

        <div className="grid gap-8 lg:grid-cols-3">
          {/* Notification Composer - 2 columns */}
          <div className="lg:col-span-2 space-y-6">
            {/* Message Type Selection */}
            <div
              className="p-6 rounded-2xl border"
              style={{
                backgroundColor: 'white',
                borderColor: 'var(--lavender-200)',
              }}
            >
              <h2 className="mb-4" style={{ color: 'var(--warm-600)' }}>
                Notification Type
              </h2>
              <div className="grid gap-3 md:grid-cols-2">
                {notificationTypes.map((type) => (
                  <button
                    key={type.id}
                    onClick={() => setMessageType(type.id)}
                    className={`p-4 rounded-xl border text-left transition-all hover:shadow-md ${
                      messageType === type.id ? "shadow-md" : ""
                    }`}
                    style={{
                      backgroundColor: messageType === type.id ? type.color + '15' : 'white',
                      borderColor:
                        messageType === type.id ? type.color : 'var(--lavender-200)',
                    }}
                  >
                    <div className="text-2xl mb-2">{type.icon}</div>
                    <h4
                      className="text-sm mb-1"
                      style={{ color: messageType === type.id ? type.color : 'var(--warm-600)' }}
                    >
                      {type.title}
                    </h4>
                    <p className="text-xs" style={{ color: 'var(--warm-500)' }}>
                      {type.description}
                    </p>
                  </button>
                ))}
              </div>
            </div>

            {/* Message Composer */}
            <div
              className="p-6 rounded-2xl border"
              style={{
                backgroundColor: 'white',
                borderColor: 'var(--lavender-200)',
              }}
            >
              <h2 className="mb-4" style={{ color: 'var(--warm-600)' }}>
                Compose Message
              </h2>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
                    Message Title *
                  </label>
                  <input
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder="Enter notification title..."
                    className="w-full px-4 py-3 rounded-xl border"
                    style={{
                      backgroundColor: 'var(--warm-50)',
                      borderColor: 'var(--lavender-200)',
                    }}
                  />
                </div>

                <div>
                  <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
                    Message Body *
                  </label>
                  <textarea
                    value={body}
                    onChange={(e) => setBody(e.target.value)}
                    placeholder="Write your message here..."
                    rows={4}
                    className="w-full px-4 py-3 rounded-xl border resize-none"
                    style={{
                      backgroundColor: 'var(--warm-50)',
                      borderColor: 'var(--lavender-200)',
                    }}
                  />
                  <p className="text-xs mt-1" style={{ color: 'var(--warm-400)' }}>
                    Keep messages warm, supportive, and action-oriented
                  </p>
                </div>

                <div>
                  <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
                    Deep Link (Optional)
                  </label>
                  <input
                    type="text"
                    value={deepLink}
                    onChange={(e) => setDeepLink(e.target.value)}
                    placeholder="empowerhealth://feature/page"
                    className="w-full px-4 py-3 rounded-xl border"
                    style={{
                      backgroundColor: 'var(--warm-50)',
                      borderColor: 'var(--lavender-200)',
                    }}
                  />
                </div>

                <div className="grid gap-4 md:grid-cols-2">
                  <div>
                    <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
                      <Calendar className="w-4 h-4 inline mr-1" />
                      Schedule Date & Time (Optional)
                    </label>
                    <input
                      type="datetime-local"
                      value={scheduledDate}
                      onChange={(e) => setScheduledDate(e.target.value)}
                      className="w-full px-4 py-3 rounded-xl border"
                      style={{
                        backgroundColor: 'var(--warm-50)',
                        borderColor: 'var(--lavender-200)',
                      }}
                    />
                  </div>

                  <div>
                    <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
                      <Users className="w-4 h-4 inline mr-1" />
                      Target Audience
                    </label>
                    <select
                      value={audience}
                      onChange={(e) => setAudience(e.target.value as NotificationSegment)}
                      className="w-full px-4 py-3 rounded-xl border"
                      style={{
                        backgroundColor: 'var(--warm-50)',
                        borderColor: 'var(--lavender-200)',
                      }}
                    >
                      {audienceOptions.map((option) => (
                        <option key={option.value} value={option.value}>
                          {option.label}
                        </option>
                      ))}
                    </select>
                    <p className="text-xs mt-1" style={{ color: 'var(--warm-400)' }}>
                      Each option maps to an FCM topic. The mobile app subscribes users who allow
                      notifications to <strong>general</strong> (all active), one <strong>trimester or postpartum</strong>{' '}
                      topic (updated when their profile changes), and one <strong>cohort</strong> topic—so only
                      matching devices receive the push.
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex gap-3">
              <button
                onClick={handleSend}
                disabled={sending || !title || !body}
                className="flex-1 flex items-center justify-center gap-2 px-6 py-3 rounded-xl shadow-sm hover:shadow-md transition-all disabled:opacity-50"
                style={{
                  backgroundColor: 'var(--success)',
                  color: 'white',
                }}
              >
                {sending ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    Sending...
                  </>
                ) : scheduledDate ? (
                  <>
                    <Send className="w-5 h-5" />
                    Schedule Notification
                  </>
                ) : (
                  <>
                    <Send className="w-5 h-5" />
                    Send Now
                  </>
                )}
              </button>
            </div>
          </div>

          {/* Recent Activity Sidebar - 1 column */}
          <div className="space-y-6">
            {/* Best Practices */}
            <div
              className="p-6 rounded-2xl border"
              style={{
                backgroundColor: 'var(--lavender-50)',
                borderColor: 'var(--lavender-200)',
              }}
            >
              <div className="flex items-center gap-2 mb-3">
                <Sparkles className="w-5 h-5" style={{ color: 'var(--lavender-600)' }} />
                <h3 style={{ color: 'var(--lavender-600)' }}>Best Practices</h3>
              </div>
              <ul className="space-y-2 text-sm" style={{ color: 'var(--warm-600)' }}>
                <li>• Use warm, encouraging language</li>
                <li>• Avoid medical jargon</li>
                <li>• Keep messages under 120 characters</li>
                <li>• Send between 9am-7pm local time</li>
                <li>• Limit to 2-3 notifications per week</li>
              </ul>
            </div>

            {/* Recent Notifications */}
            <div
              className="p-6 rounded-2xl border"
              style={{
                backgroundColor: 'white',
                borderColor: 'var(--lavender-200)',
              }}
            >
              <h3 className="mb-4" style={{ color: 'var(--warm-600)' }}>
                Recent Notifications
              </h3>
              {loadingLogs ? (
                <div className="flex items-center justify-center py-8">
                  <Loader2 className="w-6 h-6 animate-spin" style={{ color: 'var(--lavender-500)' }} />
                </div>
              ) : recentNotifications.length === 0 ? (
                <div className="text-center py-8 text-sm" style={{ color: 'var(--warm-500)' }}>
                  No recent notifications
                </div>
              ) : (
                <div className="space-y-4">
                  {recentNotifications.map((notif) => (
                    <div
                      key={notif.id}
                      className="pb-4 border-b last:border-b-0"
                      style={{ borderColor: 'var(--lavender-100)' }}
                    >
                      <div className="flex items-center justify-between gap-2 mb-1">
                        <span className="text-xs" style={{ color: 'var(--warm-400)' }}>
                          {notif.sentAt ? format(notif.sentAt, 'MMM d, yyyy · h:mm a') : 'Unknown time'}
                        </span>
                        <span
                          className="text-[10px] uppercase tracking-wide px-2 py-0.5 rounded"
                          style={{
                            backgroundColor:
                              notif.source === 'admin' ? 'var(--lavender-100)' : 'var(--warm-100)',
                            color: 'var(--warm-600)',
                          }}
                        >
                          {notif.source === 'admin' ? 'Admin' : notif.source === 'system' ? 'System' : '—'}
                        </span>
                      </div>
                      <div className="text-sm font-medium mb-1" style={{ color: 'var(--warm-600)' }}>
                        {notif.title || 'No title'}
                      </div>
                      {notif.channel && (
                        <div className="text-[11px] mb-1" style={{ color: 'var(--warm-400)' }}>
                          {notif.channel.replace(/_/g, ' ')}
                          {notif.topic ? ` · ${notif.topic}` : ''}
                        </div>
                      )}
                      <div className="text-xs leading-snug mb-2" style={{ color: 'var(--warm-500)' }}>
                        <span className="font-medium" style={{ color: 'var(--warm-600)' }}>To: </span>
                        {notif.sentToSummary ||
                          (notif.segment ? `Segment: ${notif.segment}` : '—')}
                      </div>
                      <div className="flex items-center justify-between text-xs flex-wrap gap-1">
                        {notif.segment && (
                          <span style={{ color: 'var(--warm-500)' }}>Audience: {notif.segment}</span>
                        )}
                        <span style={{ color: 'var(--lavender-600)' }}>
                          {notif.topic
                            ? 'FCM topic (no per-device count)'
                            : typeof notif.deliveredCount === 'number'
                              ? `${notif.deliveredCount} delivered`
                              : '—'}
                          {!notif.topic &&
                          typeof notif.failureCount === 'number' &&
                          notif.failureCount > 0
                            ? ` · ${notif.failureCount} failed`
                            : ''}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
