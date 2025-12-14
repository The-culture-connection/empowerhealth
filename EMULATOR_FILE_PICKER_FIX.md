# Fix File Picker on Android Emulator

## Issue
The file picker opens but times out because the DocumentsUI can't access storage providers on the emulator.

## Solution

### Option 1: Add Test Files to Emulator (Recommended)

1. **Using Android Studio Device File Explorer:**
   - Open Android Studio
   - Go to **View > Tool Windows > Device File Explorer**
   - Navigate to `/sdcard/Download/` or `/sdcard/Documents/`
   - Right-click and select **Upload**
   - Upload a test PDF file

2. **Using ADB:**
   ```bash
   adb push test_file.pdf /sdcard/Download/
   ```

3. **Drag and Drop:**
   - Simply drag a PDF file from your computer onto the emulator screen
   - It will be saved to Downloads

### Option 2: Use Physical Device (Best Option)

Physical devices work much better for file operations:

1. Enable **Developer Options** on your Android phone
2. Enable **USB Debugging**
3. Connect phone via USB
4. Run: `flutter devices` (should show your phone)
5. Run: `flutter run` to deploy to phone

### Option 3: Test Without File Picker

For now, you can test the upload functionality by:
1. Using the direct function call (without Storage upload)
2. The `summarizeAfterVisitPDF` function still works if you have PDF text

## What Changed in Code

I've updated the file picker to:
- Use `FileType.any` on Android (more reliable on emulator)
- Increased timeout to 60 seconds
- Better error messages with retry option
- More lenient PDF file detection

## Network Issues

The Firestore connection errors are separate from the file picker. They indicate:
- Emulator network connectivity issues
- DNS resolution problems

**To fix network:**
1. Restart emulator with cold boot
2. Check your computer's internet connection
3. Try a different emulator image (Pixel 5 with API 33/34)
4. Use a physical device (most reliable)

## Next Steps

1. **Add a test PDF to emulator** using one of the methods above
2. **Try the file picker again**
3. **Or test on a physical device** for best results

The file picker code is now more robust and should work better once you have files available in the emulator.

