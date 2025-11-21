# Fix: Increase Windows Virtual Memory (Paging File)

Your system has plenty of RAM (15GB) but the Windows paging file is too small. Here's how to increase it:

## Steps to Increase Virtual Memory

1. **Open System Properties:**
   - Press `Windows Key + Pause/Break` OR
   - Right-click "This PC" → Properties → Advanced system settings

2. **Access Virtual Memory Settings:**
   - Click "Advanced" tab
   - Under "Performance", click "Settings"
   - Click "Advanced" tab again
   - Under "Virtual memory", click "Change..."

3. **Increase the Paging File:**
   - Uncheck "Automatically manage paging file size for all drives"
   - Select your C: drive
   - Select "Custom size"
   - Set:
     - **Initial size (MB):** 8192 (8GB)
     - **Maximum size (MB):** 16384 (16GB)
   - Click "Set"
   - Click "OK" on all dialogs

4. **Restart Your Computer**
   - This is REQUIRED for changes to take effect

5. **After Restart, Try:**
   ```bash
   flutter clean
   flutter run
   ```

## Why This Fixes It

- Gradle and Flutter need virtual memory even when you have RAM
- Windows uses the paging file for thread creation and memory allocation
- Your current paging file is too small for development tools
- Increasing it to 8-16GB solves the issue

## Alternative: Quick Restart Solution

If you don't want to change virtual memory right now:

1. **Close ALL applications** (Chrome, VS Code, etc.)
2. **Restart your computer** to free memory
3. **Only open:**
   - Android Studio/Emulator
   - One terminal window
4. Try `flutter run` again


