#!/bin/bash
# Script to resolve merge conflict in learning_modules_screen_v2.dart

echo "Resolving merge conflict..."

# Backup the file first
cp "lib/Home/Learning Modules/learning_modules_screen_v2.dart" "lib/Home/Learning Modules/learning_modules_screen_v2.dart.backup"

# Remove conflict markers and keep the correct version (the one with StreamBuilder)
# This will remove lines between <<<<<<< HEAD and =======, and between ======= and >>>>>>>
sed -i '/^<<<<<<< HEAD$/,/^=======$/d' "lib/Home/Learning Modules/learning_modules_screen_v2.dart"
sed -i '/^=======$/,/^>>>>>>>.*$/d' "lib/Home/Learning Modules/learning_modules_screen_v2.dart"

echo "Conflict markers removed. Please review the file and commit if it looks correct."
