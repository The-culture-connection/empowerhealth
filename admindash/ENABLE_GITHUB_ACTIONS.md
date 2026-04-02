# Enable GitHub Actions - Step by Step

## The Problem

Your workflow file is committed, but GitHub Actions isn't showing up. This usually means **GitHub Actions is disabled** for your repository.

## Solution: Enable GitHub Actions

### Step 1: Go to Repository Settings

1. Go to your repository: https://github.com/The-culture-connection/empowerhealth
2. Click the **Settings** tab (at the top of the repository)
3. Scroll down to **Actions** in the left sidebar
4. Click **Actions** → **General**

### Step 2: Enable Actions

Under **"Actions permissions"**, you should see:
- **"Allow all actions and reusable workflows"** (recommended)
- **"Allow local actions and reusable workflows"**
- **"Disable Actions"**

**Select: "Allow all actions and reusable workflows"**

### Step 3: Enable Workflow Permissions

Scroll down to **"Workflow permissions"**:
- Select **"Read and write permissions"** (needed for Firebase deployment)
- Check **"Allow GitHub Actions to create and approve pull requests"** (optional)

### Step 4: Save Changes

Click **Save** at the bottom of the page.

### Step 5: Trigger the Workflow

After enabling Actions, you need to trigger it:

**Option A: Make a new commit**
```bash
git commit --allow-empty -m "Trigger GitHub Actions workflow"
git push origin main
```

**Option B: Wait for the next push**
The workflow will automatically run on your next push to `main`.

## Verify It's Working

1. Go to **Actions** tab in your repository
2. You should see "Publish Release" workflow appear
3. Click on it to see the workflow runs

## If Actions Still Don't Show

### Check Repository Visibility

If your repository is **private**, make sure:
- You have Actions enabled (see above)
- You have the right permissions (owner/admin)

### Check Workflow File Syntax

The workflow file should be valid YAML. Common issues:
- Missing `name:` at the top
- Incorrect indentation
- Invalid YAML syntax

### Check Branch Protection

If you have branch protection rules:
- Make sure Actions can run on `main` branch
- Check if status checks are blocking Actions

## Quick Test

After enabling Actions, make a test commit:

```bash
git commit --allow-empty -m "Test: Enable GitHub Actions"
git push origin main
```

Then check the Actions tab - you should see the workflow running!

## Still Not Working?

If Actions still don't appear after:
1. ✅ Enabling Actions in Settings
2. ✅ Making a new commit/push
3. ✅ Waiting a few minutes

Then check:
- Repository permissions (you need admin/owner access)
- Organization settings (if it's an org repo, Actions might be disabled at org level)
- GitHub status page (https://www.githubstatus.com/)
