/**
 * Technology Instructions Page
 * Provides instructions for submitting production builds, pushing versions, and updating features
 */

import { useAuth } from '../../contexts/AuthContext';

export function TechnologyInstructions() {
  const { isAdmin } = useAuth();

  return (
    <div className="min-h-screen p-8" style={{ backgroundColor: '#f9fafb' }}>
      <div className="max-w-4xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2" style={{ color: 'var(--warm-600)' }}>
            Technology Management Instructions
          </h1>
          <p className="text-lg" style={{ color: 'var(--warm-500)' }}>
            Guide for managing releases, versions, and feature documentation
          </p>
        </div>

        {/* Submit Production Build */}
        <section className="mb-8 p-6 rounded-lg border" style={{ backgroundColor: 'white', borderColor: 'var(--lavender-200)' }}>
          <h2 className="text-2xl font-semibold mb-4" style={{ color: 'var(--warm-600)' }}>
            1. Submit Production Build
          </h2>
          
          <div className="space-y-4">
            <div>
              <h3 className="text-lg font-medium mb-2" style={{ color: 'var(--warm-600)' }}>
                Windows (PowerShell)
              </h3>
              <div className="bg-gray-50 p-4 rounded border font-mono text-sm overflow-x-auto">
                <code className="text-gray-800">
                  cd admindash<br />
                  .\scripts\publish-production-release.ps1
                </code>
              </div>
            </div>

            <div>
              <h3 className="text-lg font-medium mb-2" style={{ color: 'var(--warm-600)' }}>
                Mac/Linux (Bash)
              </h3>
              <div className="bg-gray-50 p-4 rounded border font-mono text-sm overflow-x-auto">
                <code className="text-gray-800">
                  cd admindash<br />
                  chmod +x scripts/publish-production-release.sh<br />
                  ./scripts/publish-production-release.sh
                </code>
              </div>
            </div>

            <div className="mt-4 p-4 rounded" style={{ backgroundColor: 'var(--lavender-50)' }}>
              <p className="text-sm" style={{ color: 'var(--warm-600)' }}>
                <strong>What this does:</strong>
              </p>
              <ul className="list-disc list-inside mt-2 text-sm space-y-1" style={{ color: 'var(--warm-500)' }}>
                <li>Extracts commit information (SHA, message, date, author)</li>
                <li>Reads version from <code className="bg-white px-1 rounded">pubspec.yaml</code></li>
                <li>Processes feature changes from <code className="bg-white px-1 rounded">FEATURES.md</code></li>
                <li>Publishes release to production channel in Firestore</li>
                <li>Updates deployment history with commit metadata</li>
              </ul>
            </div>
          </div>
        </section>

        {/* Push New Version */}
        <section className="mb-8 p-6 rounded-lg border" style={{ backgroundColor: 'white', borderColor: 'var(--lavender-200)' }}>
          <h2 className="text-2xl font-semibold mb-4" style={{ color: 'var(--warm-600)' }}>
            2. Push a New Version
          </h2>
          
          <div className="space-y-4">
            <div>
              <h3 className="text-lg font-medium mb-2" style={{ color: 'var(--warm-600)' }}>
                Automatic (GitHub Push)
              </h3>
              <p className="text-sm mb-3" style={{ color: 'var(--warm-500)' }}>
                When you push to the <code className="bg-gray-100 px-1 rounded">main</code> branch, the system automatically:
              </p>
              <div className="bg-gray-50 p-4 rounded border font-mono text-sm overflow-x-auto">
                <code className="text-gray-800">
                  git add .<br />
                  git commit -m "Your commit message"<br />
                  git push origin main
                </code>
              </div>
              <ul className="list-disc list-inside mt-3 text-sm space-y-1" style={{ color: 'var(--warm-500)' }}>
                <li>GitHub Actions workflow triggers automatically</li>
                <li>Feature changes from <code className="bg-gray-100 px-1 rounded">FEATURES.md</code> are processed</li>
                <li>Release is published to <strong>pilot</strong> channel</li>
                <li>Deployment history is updated with commit info</li>
              </ul>
            </div>

            <div className="mt-4">
              <h3 className="text-lg font-medium mb-2" style={{ color: 'var(--warm-600)' }}>
                Production Release (Git Tag)
              </h3>
              <p className="text-sm mb-3" style={{ color: 'var(--warm-500)' }}>
                To publish a production release, create a tag starting with <code className="bg-gray-100 px-1 rounded">prod-v</code>:
              </p>
              <div className="bg-gray-50 p-4 rounded border font-mono text-sm overflow-x-auto">
                <code className="text-gray-800">
                  git tag prod-v1.2.3<br />
                  git push origin prod-v1.2.3
                </code>
              </div>
              <ul className="list-disc list-inside mt-3 text-sm space-y-1" style={{ color: 'var(--warm-500)' }}>
                <li>GitHub Actions workflow triggers on tag push</li>
                <li>Release is published to <strong>production</strong> channel</li>
                <li>All feature changes are included</li>
              </ul>
            </div>
          </div>
        </section>

        {/* Update Feature Summaries and Changes */}
        <section className="mb-8 p-6 rounded-lg border" style={{ backgroundColor: 'white', borderColor: 'var(--lavender-200)' }}>
          <h2 className="text-2xl font-semibold mb-4" style={{ color: 'var(--warm-600)' }}>
            3. Update Feature Summaries and Changes
          </h2>
          
          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-medium mb-2" style={{ color: 'var(--warm-600)' }}>
                Method 1: Edit FEATURES.md (Recommended)
              </h3>
              <p className="text-sm mb-3" style={{ color: 'var(--warm-500)' }}>
                Edit <code className="bg-gray-100 px-1 rounded">admindash/FEATURES.md</code> to update feature descriptions and add change history.
              </p>
              
              <div className="bg-gray-50 p-4 rounded border">
                <p className="text-sm font-medium mb-2" style={{ color: 'var(--warm-600)' }}>
                  To update a feature description:
                </p>
                <div className="bg-white p-3 rounded border font-mono text-xs overflow-x-auto mb-3">
                  <code className="text-gray-800">
                    ## 1. Provider Search<br />
                    <br />
                    ### Current Functionality<br />
                    [Update this section with new description]<br />
                    <br />
                    ### Change History<br />
                    - **2024-01-15** - **abc123def** - **Enhanced search**: Added new filters
                  </code>
                </div>

                <p className="text-sm font-medium mb-2 mt-4" style={{ color: 'var(--warm-600)' }}>
                  To add a change entry:
                </p>
                <div className="bg-white p-3 rounded border font-mono text-xs overflow-x-auto">
                  <code className="text-gray-800">
                    - **[YYYY-MM-DD]** - **[commit-sha]** - **[Title]**: [Description]
                  </code>
                </div>
              </div>

              <div className="mt-4 p-4 rounded" style={{ backgroundColor: 'var(--lavender-50)' }}>
                <p className="text-sm" style={{ color: 'var(--warm-600)' }}>
                  <strong>After editing FEATURES.md:</strong>
                </p>
                <div className="bg-white p-3 rounded border font-mono text-xs overflow-x-auto mt-2">
                  <code className="text-gray-800">
                    git add admindash/FEATURES.md<br />
                    git commit -m "Updated feature descriptions"<br />
                    git push
                  </code>
                </div>
                <p className="text-sm mt-2" style={{ color: 'var(--warm-500)' }}>
                  Changes are automatically processed on push and appear in the dashboard.
                </p>
              </div>
            </div>

            <div>
              <h3 className="text-lg font-medium mb-2" style={{ color: 'var(--warm-600)' }}>
                Method 2: Edit via Admin Dashboard
              </h3>
              <p className="text-sm mb-3" style={{ color: 'var(--warm-500)' }}>
                {isAdmin() ? (
                  <>
                    As an admin, you can edit feature descriptions directly in the dashboard:
                  </>
                ) : (
                  <>
                    <em>Admin access required</em> - Only admins can edit features via the dashboard.
                  </>
                )}
              </p>
              
              {isAdmin() && (
                <ol className="list-decimal list-inside space-y-2 text-sm" style={{ color: 'var(--warm-500)' }}>
                  <li>Go to Technology Overview page</li>
                  <li>Click on any feature in the Platform Features Catalog</li>
                  <li>Click the "Edit" button in the feature detail modal</li>
                  <li>Update the description, highlights, or other fields</li>
                  <li>Click "Save" to update the feature</li>
                </ol>
              )}

              <div className="mt-4 p-4 rounded" style={{ backgroundColor: 'var(--lavender-50)' }}>
                <p className="text-sm" style={{ color: 'var(--warm-600)' }}>
                  <strong>Note:</strong> Manual edits via dashboard will be overwritten by FEATURES.md on the next GitHub push.
                </p>
              </div>
            </div>

            <div>
              <h3 className="text-lg font-medium mb-2" style={{ color: 'var(--warm-600)' }}>
                Feature IDs Reference
              </h3>
              <div className="bg-gray-50 p-4 rounded border">
                <table className="w-full text-sm">
                  <thead>
                    <tr style={{ borderBottom: '1px solid var(--lavender-200)' }}>
                      <th className="text-left py-2 px-3 font-semibold" style={{ color: 'var(--warm-600)' }}>Feature Name</th>
                      <th className="text-left py-2 px-3 font-semibold" style={{ color: 'var(--warm-600)' }}>Section in FEATURES.md</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr style={{ borderBottom: '1px solid var(--lavender-200)' }}>
                      <td className="py-2 px-3">Provider Search</td>
                      <td className="py-2 px-3 font-mono text-xs">## 1. Provider Search</td>
                    </tr>
                    <tr style={{ borderBottom: '1px solid var(--lavender-200)' }}>
                      <td className="py-2 px-3">Authentication and Onboarding</td>
                      <td className="py-2 px-3 font-mono text-xs">## 2. Authentication and Onboarding</td>
                    </tr>
                    <tr style={{ borderBottom: '1px solid var(--lavender-200)' }}>
                      <td className="py-2 px-3">User Feedback</td>
                      <td className="py-2 px-3 font-mono text-xs">## 3. User Feedback</td>
                    </tr>
                    <tr style={{ borderBottom: '1px solid var(--lavender-200)' }}>
                      <td className="py-2 px-3">Appointment Summarizing</td>
                      <td className="py-2 px-3 font-mono text-xs">## 4. Appointment Summarizing</td>
                    </tr>
                    <tr style={{ borderBottom: '1px solid var(--lavender-200)' }}>
                      <td className="py-2 px-3">Journal</td>
                      <td className="py-2 px-3 font-mono text-xs">## 5. Journal</td>
                    </tr>
                    <tr style={{ borderBottom: '1px solid var(--lavender-200)' }}>
                      <td className="py-2 px-3">Learning Modules</td>
                      <td className="py-2 px-3 font-mono text-xs">## 6. Learning Modules</td>
                    </tr>
                    <tr style={{ borderBottom: '1px solid var(--lavender-200)' }}>
                      <td className="py-2 px-3">Birth Plan Generator</td>
                      <td className="py-2 px-3 font-mono text-xs">## 7. Birth Plan Generator</td>
                    </tr>
                    <tr style={{ borderBottom: '1px solid var(--lavender-200)' }}>
                      <td className="py-2 px-3">Community</td>
                      <td className="py-2 px-3 font-mono text-xs">## 8. Community</td>
                    </tr>
                    <tr>
                      <td className="py-2 px-3">Profile Editing</td>
                      <td className="py-2 px-3 font-mono text-xs">## 9. Profile Editing</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </section>

        {/* Quick Reference */}
        <section className="mb-8 p-6 rounded-lg border" style={{ backgroundColor: 'white', borderColor: 'var(--lavender-200)' }}>
          <h2 className="text-2xl font-semibold mb-4" style={{ color: 'var(--warm-600)' }}>
            Quick Reference
          </h2>
          
          <div className="grid md:grid-cols-2 gap-4">
            <div className="p-4 rounded" style={{ backgroundColor: 'var(--lavender-50)' }}>
              <h3 className="font-medium mb-2" style={{ color: 'var(--warm-600)' }}>File Locations</h3>
              <ul className="text-sm space-y-1 font-mono" style={{ color: 'var(--warm-500)' }}>
                <li>• admindash/FEATURES.md</li>
                <li>• admindash/scripts/</li>
                <li>• admindash/.github/workflows/</li>
              </ul>
            </div>

            <div className="p-4 rounded" style={{ backgroundColor: 'var(--lavender-50)' }}>
              <h3 className="font-medium mb-2" style={{ color: 'var(--warm-600)' }}>Important Notes</h3>
              <ul className="text-sm space-y-1" style={{ color: 'var(--warm-500)' }}>
                <li>• Changes in FEATURES.md auto-process on push</li>
                <li>• Production releases require manual script</li>
                <li>• Feature IDs must match exactly</li>
                <li>• Commit SHA format: first 7 characters</li>
              </ul>
            </div>
          </div>
        </section>

        {/* Help Section */}
        <section className="p-6 rounded-lg border" style={{ backgroundColor: 'white', borderColor: 'var(--lavender-200)' }}>
          <h2 className="text-2xl font-semibold mb-4" style={{ color: 'var(--warm-600)' }}>
            Need Help?
          </h2>
          
          <div className="space-y-2 text-sm" style={{ color: 'var(--warm-500)' }}>
            <p>
              For more detailed information, see:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-4">
              <li><code className="bg-gray-100 px-1 rounded">README_FEATURE_TRACKING.md</code> - Complete usage guide</li>
              <li><code className="bg-gray-100 px-1 rounded">FEATURE_SYSTEM_SUMMARY.md</code> - System overview</li>
              <li><code className="bg-gray-100 px-1 rounded">FEATURES.md</code> - Feature documentation template</li>
            </ul>
          </div>
        </section>
      </div>
    </div>
  );
}
