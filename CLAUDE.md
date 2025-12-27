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

## Архитектура
- Большие виджеты → декомпозиция на отдельные StatelessWidget/StatefulWidget классы
- Методы, возвращающие Widget — антипаттерн (нет оптимизаций rebuild). Допустимы только когда: влияние на производительность минимально И повышают читаемость
- Каждый виджет — одна ответственность

## Качество кода
- Параметры через конструктор с именованными аргументами
- Значения по умолчанию где уместно
- const конструкторы везде где возможно
- Приватные виджеты с `_` префиксом в том же файле

## Тема
- Цвета, шрифты — только из темы. Старайся не использовать хардкод значений (только в редких случаях)
- Получать тему один раз в начале build:
```dart
@override
Widget build(BuildContext context) {
  final textTheme = context.textTheme;
  // или final theme = context.theme; если необходим доступ не только к textTheme
  final themeColors = context.themeColors;

  return Text(
    'Hello',
    style: textTheme.titleMedium?.copyWith(
      color: themeColors.primary,
    ),
  );
}
```
- Не вызывать context.theme / context.textTheme / Theme.of(context) многократно в одном build

## Комментарии
- Не документировать очевидное
- Комментарий нужен когда: неочевидная логика, workaround, важный контекст
- Формат: краткий, по существу
```dart
// Отступ компенсирует SafeArea на iOS
final bottomPadding = MediaQuery.of(context).padding.bottom;

// TODO: заменить на Stream когда API будет готов
```
- Без шаблонных /// для каждого поля/метода

## Адаптивность (базовая)
Цель: отсутствие overflow на малых экранах

- Row с текстом/динамикой → Expanded/Flexible
- Длинный текст → overflow: TextOverflow.ellipsis, maxLines
- Списки в Column → SingleChildScrollView или ListView
- Изображения/иконки фиксированного размера в ограниченном пространстве → FittedBox
- Избегать жёстких width/height для контейнеров с контентом

## Структура виджета
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