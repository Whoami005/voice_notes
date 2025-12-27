# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

```bash
# Run the app
flutter run

# Run on specific device
flutter run -d <device_id>

# Build for release
flutter build apk          # Android
flutter build ios          # iOS

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code (linting)
flutter analyze

# Get dependencies
flutter pub get
```

## Architecture Overview

This is a Flutter voice notes application with speech-to-text (ASR) capabilities. The design specification is in `FLUTTER_DESIGN_SPEC.md` (Russian language).

### Project Structure

```
lib/
├── main.dart
├── core/                              # Theme, colors, typography, constants
├── common/                            # Common utilities
└── feature/
    ├── data/                          # Data layer (repositories, data sources)
    ├── domain/                        # Domain layer (entities, use cases)
    └── presentation/
        ├── pages/                     # Feature screens
        │   ├── folders/
        │   │   ├── screens/
        │   │   ├── widgets/           # Folder-specific widgets
        │   │   └── logic/             # BLoC/Cubit for feature
        │   ├── notes/
        │   │   ├── screens/
        │   │   ├── widgets/
        │   │   └── logic/
        │   └── settings/
        │       ├── screens/
        │       ├── widgets/
        │       └── logic/
        └── widgets/                   # Shared widgets (organized by type)
            ├── dialogs/
            ├── buttons/
            ├── bottom_navigation_bar/
            ├── bottom_sheet/
            ├── chips/
            └── menus/
```

### Key Design Patterns

- **Clean Architecture**: data/domain/presentation layers
- **Theme system**: Separate light/dark themes via `AppColors.dark` / `AppColors.light`
- **Spacing system**: 8px base grid defined in `AppSizes`
- **State management**: Riverpod or BLoC recommended
- **Navigation**: go_router for declarative routing

### Core Data Models

- **Folder**: Contains notes, has color and icon from predefined palette
- **Note**: Voice transcription with tags, duration, language, word count
- **AsrModel**: Whisper/NeMo speech recognition models with download state

### UI Components (from design spec)

Key components: FolderCard, NoteBubble (chat-style), RecordingInput (idle/recording/transcribing states), SearchBarWithFilters, SettingsRow, ModelCard, AppBottomSheet, ConfirmDialog, TagChip, DateSeparator, AppFab, AppBottomNav

### Color Palette

8 folder colors: amber, green, blue, pink, purple, red, cyan, lime (defined in `AppColors.folderColors`)

# Flutter Widgets

## Architecture
- Large widgets → decompose into separate StatelessWidget/StatefulWidget classes
- Methods returning Widget — anti-pattern (no rebuild optimizations). Allowed only when: minimal performance impact AND improves readability
- Each widget — single responsibility

## Code Quality
- Parameters via constructor with named arguments
- Default values where appropriate
- const constructors wherever possible
- Private widgets with `_` prefix in the same file

## Theme
- Colors, fonts, sizes — only from theme. Avoid hardcoded values (only in rare cases)
- Get theme once at the start of build:
```dart
@override
Widget build(BuildContext context) {
  // or final theme = context.theme; if access beyond textTheme is needed
  final textTheme = context.textTheme;
  final themeColors = context.themeColors;

  return Text(
    'Hello',
    style: textTheme.titleMedium?.copyWith(
      color: themeColors.primary,
    ),
  );
}
```
- Do not call context.theme / context.textTheme / Theme.of(context) multiple times in one build

## Loops & Iterations
- Avoid .map() — slower, often less readable, requires .toList()
- Use only when it clearly improves readability over alternatives
- In logic: prefer for-in
```dart
// ✗ Avoid
final names = users.map((u) => u.name).toList();

// ✓ Prefer
final names = [for (final user in users) user];
```
- In UI: prefer collection-for or List.generate
```dart
// ✗ Avoid
Column(children: items.map((item) => ItemTile(item)).toList())

// ✓ Prefer: collection-for (simple cases, default choice)
Column(children: [for (final item in items) ItemTile(item)])

// ✓ Prefer: List.generate (In UI: use List.generate when index needed, extra logic involved, or improves readability)
Column(
  children: List.generate(
    items.length,
    (index) => ItemTile(items[index], index: index),
  ),
)
```

## Comments
- Do not document the obvious
- Comment needed when: non-obvious logic, workaround, important context
- Format: brief, to the point
```dart
// Padding compensates SafeArea on iOS
final bottomPadding = MediaQuery.of(context).padding.bottom;

// TODO: replace with Stream when API is ready
```
- No boilerplate /// for every field/method

## Responsiveness (basic)
Goal: no overflow on small screens

- Row with text/dynamic content → Expanded/Flexible
- Long text → overflow: TextOverflow.ellipsis, maxLines
- Lists in Column → SingleChildScrollView or ListView
- Fixed-size images/icons in constrained space → FittedBox
- Avoid hardcoded width/height for containers with content

## Widget Structure
```dart
class MyWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const MyWidget({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return /* ... */;
  }
}
```