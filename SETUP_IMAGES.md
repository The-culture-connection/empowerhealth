# How to Set Up Your Images

## Images to Copy

Please copy the following images from your local folder to `/workspace/assets/images/`:

### Required Images:
1. **Authscreen.jpeg** → Use for Auth Screen
2. **Homeimage.jpeg** → Use for Dashboard/Home Screen  
3. **babyfamily.jpeg** → Use for Community Screen
4. **family.jpeg** → Use for Feedback Screen
5. **helpingheadj...** (full filename) → Use for Appointments Screen
6. **braidinghair.png** → Use for Transcription Screen
7. **blackfathersup...** (full filename) → Alternative background
8. **calmom_logo...** → Can be used for logo in assets/logos/
9. **runner.png** → Additional background option
10. **UI basis.png** → Reference/design file

## Quick Copy Commands

If your images are in a local folder, copy them using:

```bash
# Copy all images to assets/images/
cp /path/to/your/images/*.jpeg /workspace/assets/images/
cp /path/to/your/images/*.png /workspace/assets/images/
```

Or manually:
1. Open your file explorer
2. Navigate to the folder with these images
3. Copy the images
4. Paste them into `/workspace/assets/images/`

## Image Mapping for Screens

After copying, the app will use:
- `Authscreen.jpeg` - Auth/Login/Signup screens
- `Homeimage.jpeg` - Dashboard screen
- `babyfamily.jpeg` - Community screen
- `family.jpeg` - Feedback screen
- `helpingheadj...` - Appointments screen
- `braidinghair.png` - Transcription screen

## What I'll Update

Once you place the images in the folder, I'll:
1. Update each screen to use its specific background image
2. Remove the random background picker
3. Ensure proper image sizing and positioning
4. Update the pubspec.yaml assets section if needed

## Next Steps

1. Copy your images to `/workspace/assets/images/`
2. Let me know when done
3. I'll update all the screens to use the correct images
