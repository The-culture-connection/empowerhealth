# Responsive Text System for EmpowerHealth Watch

## Overview
To prevent text overflow and cutoff issues across different phone sizes, use the responsive text utilities provided in `lib/cors/ui_theme.dart`.

## Quick Reference

### 1. Responsive Text Styles

#### Title Text (Headlines, Screen Titles)
```dart
Text(
  'My Title',
  style: AppTheme.responsiveTitleStyle(context, baseSize: 20),
)
```

#### Subtitle Text (Section Headers)
```dart
Text(
  'My Subtitle',
  style: AppTheme.responsiveSubtitleStyle(context, baseSize: 16),
)
```

#### Body Text (Regular Content)
```dart
Text(
  'My body text content',
  style: AppTheme.responsiveBodyStyle(context, baseSize: 14),
)
```

#### Button Text
```dart
Text(
  'Button Label',
  style: AppTheme.responsiveButtonStyle(context, baseSize: 16),
)
```

#### Caption/Small Text
```dart
Text(
  'Small caption text',
  style: AppTheme.responsiveCaptionStyle(context, baseSize: 12),
)
```

### 2. Safe Text Widget (Prevents Overflow)

Instead of:
```dart
Text('Some potentially long text')
```

Use:
```dart
AppTheme.safeText('Some potentially long text')
```

Or with custom styling:
```dart
AppTheme.safeText(
  'Some potentially long text',
  style: AppTheme.responsiveBodyStyle(context),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

### 3. Responsive Padding

```dart
Padding(
  padding: AppTheme.responsivePadding(context, horizontal: 16, vertical: 8),
  child: MyWidget(),
)
```

### 4. Critical: Always Use Expanded/Flexible in Rows

When text is inside a Row, ALWAYS wrap it in Expanded or Flexible:

❌ **WRONG:**
```dart
Row(
  children: [
    Icon(Icons.info),
    Text('This long text will cause overflow'),
  ],
)
```

✅ **CORRECT:**
```dart
Row(
  children: [
    Icon(Icons.info),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        'This long text will wrap properly',
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
)
```

### 5. Dropdown Items

For dropdowns with long text, use `isExpanded: true` and `overflow: TextOverflow.ellipsis`:

```dart
DropdownButtonFormField<String>(
  isExpanded: true,
  items: [
    DropdownMenuItem(
      value: 'Long Option Name',
      child: Text('Long Option Name', overflow: TextOverflow.ellipsis),
    ),
  ],
)
```

## Screen Size Categories

The system automatically adjusts for:
- **Small phones** (< 360px width): 85% of base font size
- **Standard phones** (360-600px width): 100% of base font size
- **Large screens/tablets** (> 600px width): 115% of base font size

## Best Practices

1. **Always test on smallest supported device** (320px width if possible)
2. **Use responsive helpers for all user-facing text**
3. **Wrap text in Expanded/Flexible when inside Row or similar**
4. **Set maxLines and overflow behavior for long content**
5. **Use FittedBox for text that must fit in a fixed space**
6. **Prefer SingleChildScrollView for content that might be long**

## Common Issues and Solutions

### Issue: "Right overflow by X pixels"
**Solution:** Wrap the Text widget in Expanded or Flexible, or use `overflow: TextOverflow.ellipsis`

### Issue: Text too large on small screens
**Solution:** Use `AppTheme.responsiveXXXStyle(context)` instead of fixed font sizes

### Issue: Text cut off in dialogs
**Solution:** Wrap dialog content in SingleChildScrollView and use responsive styles

### Issue: Button text overflowing
**Solution:** Use responsive button style and consider shortening text or using an icon

## Migration Guide

When updating existing screens:
1. Replace fixed `fontSize` with responsive helpers
2. Add `Expanded` to Text widgets in Rows
3. Add `isExpanded: true` to all DropdownButtonFormField widgets
4. Add `overflow: TextOverflow.ellipsis` to dropdown items
5. Use `AppTheme.safeText()` for critical text that must display

## Examples

### Before:
```dart
Text(
  'Welcome to EmpowerHealth',
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
)
```

### After:
```dart
Text(
  'Welcome to EmpowerHealth',
  style: AppTheme.responsiveTitleStyle(context, baseSize: 24),
)
```

### Before:
```dart
Row(
  children: [
    Icon(Icons.info),
    Text('Long description text here'),
  ],
)
```

### After:
```dart
Row(
  children: [
    Icon(Icons.info),
    const SizedBox(width: 8),
    Expanded(
      child: AppTheme.safeText(
        'Long description text here',
        style: AppTheme.responsiveBodyStyle(context),
      ),
    ),
  ],
)
```
