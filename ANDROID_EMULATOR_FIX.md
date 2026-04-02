# Fix Android Emulator Issues

## Issues You're Experiencing

1. **Network Connectivity**: "Unable to resolve host firestore.googleapis.com"
2. **File Picker**: File picker cancels or doesn't work properly

## Fix Network Connectivity

The Android emulator needs internet access. Here's how to fix it:

### Option 1: Check Emulator Network Settings

1. Open Android Studio
2. Go to **Tools > Device Manager** (or **AVD Manager**)
3. Click the **pencil icon** (edit) next to your emulator
4. Click **Show Advanced Settings**
5. Under **Network**, make sure:
   - **Cellular**: Enabled
   - **Wi-Fi**: Enabled
   - **Network Speed**: Full
   - **Network Latency**: None

### Option 2: Restart Emulator with Network

1. Close the emulator completely
2. In Android Studio, go to **Tools > Device Manager**
3. Click the **dropdown arrow** next to your emulator
4. Select **Cold Boot Now**
5. Wait for emulator to fully start
6. Check internet by opening Chrome browser in emulator

### Option 3: Use Different Emulator Image

Some emulator images have network issues. Try:
- **Pixel 5** with **API 33** or **API 34**
- Make sure to use **Google Play** images (not just Google APIs)

### Option 4: Check Your Computer's Network

The emulator uses your computer's network. Make sure:
- Your computer has internet access
- No VPN is blocking connections
- Firewall isn't blocking Android emulator

### Option 5: Use Physical Device (Recommended for Testing)

Physical devices are more reliable:
1. Enable **Developer Options** on your Android phone
2. Enable **USB Debugging**
3. Connect phone via USB
4. Run: `flutter devices` to see your phone
5. Run: `flutter run` to deploy to phone

## Fix File Picker Issues

### For Android Emulator:

1. **Add Test Files to Emulator**:
   - Drag and drop a PDF file onto the emulator screen
   - Or use Android Studio's **Device File Explorer**:
     - Go to **View > Tool Windows > Device File Explorer**
     - Navigate to `/sdcard/Download/`
     - Right-click and **Upload** a PDF file

2. **Use Physical Device** (Best Option):
   - File picker works better on real devices
   - You can select files from Downloads, Drive, etc.

3. **Check Permissions**:
   - The app should request storage permissions automatically
   - If not, go to **Settings > Apps > EmpowerHealth > Permissions**
   - Enable **Storage** or **Files and media**

## Quick Test

To test if network is working:

1. Open Chrome browser in emulator
2. Go to: `https://www.google.com`
3. If it loads, network is working
4. If not, follow network fix steps above

## Alternative: Test on Physical Device

Physical devices are more reliable for testing:

```bash
# Connect your Android phone via USB
# Enable USB debugging on phone
flutter devices  # Should show your phone
flutter run      # Deploy to phone
```

## After Fixing

Once network is working:
1. Restart the app
2. Try uploading a PDF file again
3. The file picker should work and network calls should succeed

