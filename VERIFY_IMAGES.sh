#!/bin/bash
# Quick verification script to check if all required images are in place

echo "🔍 Checking for required images in /workspace/assets/images/..."
echo ""

IMAGES_DIR="/workspace/assets/images"
REQUIRED_IMAGES=(
  "Authscreen.jpeg"
  "Homeimage.jpeg"
  "babyfamily.jpeg"
  "family.jpeg"
  "helpingheadjpg.jpeg"
  "braidinghair.png"
)

FOUND=0
MISSING=0

for img in "${REQUIRED_IMAGES[@]}"; do
  if [ -f "$IMAGES_DIR/$img" ]; then
    SIZE=$(du -h "$IMAGES_DIR/$img" | cut -f1)
    echo "✅ $img ($SIZE)"
    ((FOUND++))
  else
    echo "❌ $img - NOT FOUND"
    ((MISSING++))
  fi
done

echo ""
echo "📊 Summary:"
echo "   Found: $FOUND/$((FOUND + MISSING))"
echo "   Missing: $MISSING/$((FOUND + MISSING))"
echo ""

if [ $MISSING -eq 0 ]; then
  echo "🎉 All images are in place! Ready to run:"
  echo "   flutter run"
else
  echo "⚠️  Please copy the missing images to $IMAGES_DIR"
  echo "   See COPY_YOUR_IMAGES_HERE.md for instructions"
fi

echo ""
echo "💡 To make this script executable, run:"
echo "   chmod +x VERIFY_IMAGES.sh"
