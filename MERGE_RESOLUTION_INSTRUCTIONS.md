# Merge Conflict Resolution Instructions

If you're experiencing merge conflicts when pulling, follow these steps:

## Option 1: Complete the merge (if merge is in progress)

```bash
# Check if there's a merge in progress
git status

# If you see "All conflicts fixed but you are still merging", complete it:
git commit --no-edit

# Or if you want to edit the message:
git commit
```

## Option 2: Abort and redo the merge

```bash
# Abort the current merge
git merge --abort

# Pull again with a strategy that avoids editor
git pull origin cursor/new-ui-implementation-15b6 --no-edit
```

## Option 3: Reset and pull fresh

```bash
# Save any local changes first (if needed)
git stash

# Reset to match remote exactly
git fetch origin cursor/new-ui-implementation-15b6
git reset --hard origin/cursor/new-ui-implementation-15b6

# Restore stashed changes (if you had any)
git stash pop
```

## Option 4: If conflicts persist, resolve manually

The file `lib/Home/Learning Modules/learning_modules_screen_v2.dart` should have:
- FirebaseAuth import
- Helper methods: `_getModuleIcon`, `_getModuleColors`, `_normalizeTrimester`
- StreamBuilder fetching from Firestore
- No hardcoded `_bankedModules` list
