# VoiceNotes — Flutter Design Specification

> Этот файл содержит полную спецификацию дизайна для Flutter-приложения голосовых заметок.
> Используй этот файл как референс при создании виджетов.

---

## Структура проекта

```
lib/
├── main.dart
├── core/
│   ├── theme/
│   │   ├── app_theme.dart          # ThemeData для light/dark
│   │   ├── app_colors.dart         # Цветовая палитра
│   │   └── app_typography.dart     # Текстовые стили
│   └── constants/
│       └── app_sizes.dart          # Размеры, отступы, радиусы
├── common/                         # Общие утилиты
└── feature/
    ├── data/                       # Слой данных (репозитории, источники данных)
    ├── domain/                     # Доменный слой (сущности, use cases)
    │   ├── folder.dart
    │   ├── note.dart
    │   └── asr_model.dart
    └── presentation/
        ├── pages/                  # Фичи приложения
        │   ├── folders/
        │   │   ├── screens/
        │   │   │   └── folders_screen.dart
        │   │   ├── widgets/
        │   │   │   ├── folder_card.dart
        │   │   │   └── quick_record_card.dart
        │   │   └── logic/          # BLoC/Cubit/Provider для фичи
        │   ├── notes/
        │   │   ├── screens/
        │   │   │   ├── folder_detail_screen.dart
        │   │   │   └── note_detail_screen.dart
        │   │   ├── widgets/
        │   │   │   ├── note_bubble.dart
        │   │   │   ├── recording_input.dart
        │   │   │   ├── search_bar_with_filters.dart
        │   │   │   └── date_separator.dart
        │   │   └── logic/
        │   └── settings/
        │       ├── screens/
        │       │   └── settings_screen.dart
        │       ├── widgets/
        │       │   ├── settings_section.dart
        │       │   ├── settings_row.dart
        │       │   └── model_card.dart
        │       └── logic/
        └── widgets/                # Общие переиспользуемые виджеты
            ├── dialogs/
            │   ├── confirm_dialog.dart
            │   └── language_dialog.dart
            ├── buttons/
            │   └── app_fab.dart
            ├── bottom_navigation_bar/
            │   └── app_bottom_nav.dart
            ├── bottom_sheet/
            │   └── app_bottom_sheet.dart
            ├── chips/
            │   └── tag_chip.dart
            └── menus/
                └── dropdown_menu.dart
```

---

## Цветовая палитра (app_colors.dart)

```dart
import 'package:flutter/material.dart';

class AppColors {
  // ============ DARK THEME ============
  static const dark = _DarkColors();
  
  // ============ LIGHT THEME ============
  static const light = _LightColors();
  
  // ============ SHARED ============
  static const folderColors = [
    Color(0xFFF59E0B), // amber
    Color(0xFF22C55E), // green
    Color(0xFF3B82F6), // blue
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // purple
    Color(0xFFEF4444), // red
    Color(0xFF06B6D4), // cyan
    Color(0xFF84CC16), // lime
  ];
}

class _DarkColors {
  const _DarkColors();
  
  // Backgrounds
  final Color bgPrimary = const Color(0xFF0A0A0B);
  final Color bgSecondary = const Color(0xFF141416);
  final Color bgTertiary = const Color(0xFF1C1C1F);
  final Color bgElevated = const Color(0xFF242428);
  
  // Text
  final Color textPrimary = const Color(0xFFFFFFFF);
  final Color textSecondary = const Color(0xFFA1A1AA);
  final Color textTertiary = const Color(0xFF71717A);
  final Color textInverse = const Color(0xFF0A0A0B);
  
  // Accent
  final Color accentPrimary = const Color(0xFFF59E0B);
  final Color accentSecondary = const Color(0xFFFBBF24);
  Color get accentMuted => const Color(0xFFF59E0B).withOpacity(0.15);
  Color get accentGlow => const Color(0xFFF59E0B).withOpacity(0.30);
  
  // Borders
  final Color borderPrimary = const Color(0xFF27272A);
  final Color borderSecondary = const Color(0xFF3F3F46);
  
  // Status
  final Color success = const Color(0xFF22C55E);
  final Color error = const Color(0xFFEF4444);
  final Color warning = const Color(0xFFF59E0B);
  final Color info = const Color(0xFF3B82F6);
  
  // Recording
  final Color recordingBg = const Color(0xFF7F1D1D);
  final Color recordingPulse = const Color(0xFFEF4444);
  
  // Overlay
  Color get overlay => Colors.black.withOpacity(0.6);
}

class _LightColors {
  const _LightColors();
  
  // Backgrounds
  final Color bgPrimary = const Color(0xFFFAFAF9);
  final Color bgSecondary = const Color(0xFFFFFFFF);
  final Color bgTertiary = const Color(0xFFF5F5F4);
  final Color bgElevated = const Color(0xFFFFFFFF);
  
  // Text
  final Color textPrimary = const Color(0xFF1C1917);
  final Color textSecondary = const Color(0xFF57534E);
  final Color textTertiary = const Color(0xFFA8A29E);
  final Color textInverse = const Color(0xFFFFFFFF);
  
  // Accent
  final Color accentPrimary = const Color(0xFFD97706);
  final Color accentSecondary = const Color(0xFFF59E0B);
  Color get accentMuted => const Color(0xFFD97706).withOpacity(0.10);
  Color get accentGlow => const Color(0xFFD97706).withOpacity(0.20);
  
  // Borders
  final Color borderPrimary = const Color(0xFFE7E5E4);
  final Color borderSecondary = const Color(0xFFD6D3D1);
  
  // Status
  final Color success = const Color(0xFF16A34A);
  final Color error = const Color(0xFFDC2626);
  final Color warning = const Color(0xFFD97706);
  final Color info = const Color(0xFF2563EB);
  
  // Recording
  final Color recordingBg = const Color(0xFFFEF2F2);
  final Color recordingPulse = const Color(0xFFEF4444);
  
  // Overlay
  Color get overlay => Colors.black.withOpacity(0.4);
}
```

---

## Размеры и константы (app_sizes.dart)

```dart
class AppSizes {
  // Spacing (base 8px)
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;
  static const double space8 = 40;
  static const double space9 = 48;
  static const double space10 = 64;
  
  // Screen
  static const double screenPadding = 20;
  static const double safeAreaBottom = 34;
  
  // Border Radius
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXL = 18;
  static const double radiusXXL = 20;
  static const double radiusRound = 24;
  static const double radiusFull = 999;
  
  // Components
  static const double cardRadius = 16;
  static const double cardPadding = 16;
  static const double inputRadius = 12;
  static const double buttonRadius = 10;
  static const double chipRadius = 20;
  static const double bubbleRadius = 18;
  
  // Icons
  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double iconLarge = 24;
  
  // Avatars / Icon containers
  static const double avatarSmall = 40;
  static const double avatarMedium = 44;
  static const double avatarLarge = 48;
  
  // Buttons
  static const double buttonHeight = 48;
  static const double buttonSmallHeight = 44;
  static const double fabSize = 56;
  static const double fabRadius = 16;
  static const double micButtonSize = 48;
  
  // Toggle
  static const double toggleWidth = 52;
  static const double toggleHeight = 32;
  static const double toggleThumb = 26;
  
  // Bottom Nav
  static const double bottomNavHeight = 84;
  
  // Bottom Sheet
  static const double bottomSheetRadius = 24;
  static const double handleWidth = 40;
  static const double handleHeight = 4;
}
```

---

## Типографика (app_typography.dart)

```dart
import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamily = 'SF Pro Display'; // или 'Roboto' для Android
  
  // Заголовки
  static const TextStyle h1Large = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.2,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  // Meta
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  static const TextStyle captionSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  static const TextStyle micro = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
  
  // Buttons
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}
```

---

## Компоненты

### 1. FolderCard

```dart
/// Карточка папки на главном экране
/// 
/// Параметры:
/// - name: String — название папки
/// - notesCount: int — количество заметок
/// - lastUpdated: String — "2 часа назад", "Вчера"
/// - color: Color — цвет папки из AppColors.folderColors
/// - icon: IconData — иконка папки
/// - description: String? — опциональное описание
/// - onTap: VoidCallback
/// 
/// Размеры:
/// - Padding: 16px
/// - Border radius: 16px
/// - Icon container: 48x48px, radius 14px
/// - Gap между icon и text: 14px
/// 
/// Стили:
/// - Background: bgSecondary
/// - Border: 1px borderPrimary
/// - Title: bodyLarge + w600 + textPrimary
/// - Subtitle: caption + textTertiary
/// - Chevron: 20px, textTertiary
```

### 2. NoteBubble

```dart
/// Пузырь заметки в чат-интерфейсе
/// 
/// Параметры:
/// - text: String — текст заметки
/// - timestamp: String — "14:32"
/// - duration: String — "0:45"
/// - language: String — "Русский", "English"
/// - tags: List<String> — ["работа", "презентация"]
/// - onTap: VoidCallback — переход в деталку
/// - onCopy: VoidCallback
/// - onShare: VoidCallback
/// 
/// Размеры:
/// - Max width: 85% от экрана
/// - Padding: 14px 16px
/// - Border radius: 18px
/// - Alignment: справа (CrossAxisAlignment.end)
/// 
/// Стили:
/// - Background: bgSecondary
/// - Border: 1px borderPrimary
/// - Text: body + textPrimary + lineHeight 1.5
/// - Tags: micro + accentPrimary + bg accentMuted + radius 20px + padding 4px 10px
/// - Meta: captionSmall + textTertiary
```

### 3. RecordingInput

```dart
/// Панель записи внизу экрана папки
/// 
/// Состояния:
/// 1. idle — кнопка загрузки + placeholder + кнопка микрофона
/// 2. recording — кнопка отмены + таймер + волна + кнопка отправки
/// 3. transcribing — показывается NoteBubble с анимацией печати
/// 
/// Параметры:
/// - state: RecordingState (idle, recording, transcribing)
/// - recordingDuration: Duration
/// - transcribingText: String
/// - onStartRecording: VoidCallback
/// - onStopRecording: VoidCallback
/// - onCancelRecording: VoidCallback
/// - onUploadFile: VoidCallback
/// 
/// Размеры idle:
/// - Upload button: 44x44px, bgTertiary, radius 50%
/// - Placeholder: flex 1, bgTertiary, radius 24px, padding 14px 20px
/// - Mic button: 48x48px, accentPrimary, radius 50%, shadow
/// 
/// Размеры recording:
/// - Cancel button: 48px, bgTertiary, radius 50%
/// - Recording bar: flex 1, recordingBg, radius 24px, padding 12px 16px
/// - Red dot: 10x10px, recordingPulse, с анимацией pulse
/// - Waveform: 24 бара, width 3px, height 4-28px (анимированные)
/// - Send button: 48x48px, accentPrimary, radius 50%
```

### 4. SearchBarWithFilters

```dart
/// Поле поиска с фильтрами
/// 
/// Параметры:
/// - query: String
/// - onQueryChanged: Function(String)
/// - activeFilter: SearchFilter (all, text, tags, date)
/// - onFilterChanged: Function(SearchFilter)
/// - placeholder: String
/// 
/// Размеры:
/// - Search field: bgTertiary, radius 12px, padding 10px 14px
/// - Filter chips: gap 8px, padding 6px 14px, radius 20px
/// 
/// Стили фильтров:
/// - Active: bg accentPrimary, text textInverse
/// - Inactive: bg bgTertiary, text textSecondary
```

### 5. SettingsRow

```dart
/// Строка настроек с toggle или chevron
/// 
/// Параметры:
/// - icon: IconData
/// - title: String
/// - subtitle: String?
/// - trailing: Widget? — Toggle, Chevron, или custom
/// - onTap: VoidCallback?
/// - showDivider: bool
/// 
/// Размеры:
/// - Padding: 16px
/// - Icon: 20px, textSecondary
/// - Gap: 14px
/// 
/// Стили:
/// - Title: body + textPrimary
/// - Subtitle: caption + textTertiary
```

### 6. ModelCard

```dart
/// Карточка модели ASR
/// 
/// Параметры:
/// - name: String — "Whisper Small"
/// - engine: String — "OpenAI Whisper" | "NVIDIA NeMo"
/// - size: String — "466 MB"
/// - languages: String — "99 языков"
/// - description: String
/// - isDownloaded: bool
/// - isSelected: bool
/// - downloadProgress: double? — 0.0-1.0 если качается
/// - onUse: VoidCallback
/// - onDownload: VoidCallback
/// - onDelete: VoidCallback
/// 
/// Размеры:
/// - Padding: 16px
/// - Border radius: 16px
/// - Icon container: 44x44px, radius 12px
/// 
/// Цвета иконки:
/// - Whisper: bg #22C55E20, icon #22C55E
/// - Parakeet: bg #3B82F620, icon #3B82F6
/// 
/// Badge "АКТИВНА":
/// - Font: micro (10px) + w600
/// - Bg: accentPrimary
/// - Color: textInverse
/// - Padding: 2px 8px
/// - Radius: 10px
```

### 7. AppBottomSheet

```dart
/// Универсальный bottom sheet
/// 
/// Параметры:
/// - title: String
/// - child: Widget
/// - onClose: VoidCallback
/// 
/// Размеры:
/// - Radius: 24px 24px 0 0
/// - Handle: 40x4px, borderSecondary, radius 2px
/// - Padding: 20px
/// - Padding bottom: 40px (safe area)
/// 
/// Анимация: slideUp 300ms
```

### 8. ConfirmDialog

```dart
/// Диалог подтверждения
/// 
/// Параметры:
/// - title: String — "Удалить папку?"
/// - message: String — "Все заметки будут удалены..."
/// - confirmText: String — "Удалить"
/// - confirmColor: Color? — по умолчанию error
/// - onConfirm: VoidCallback
/// - onCancel: VoidCallback
/// 
/// Размеры:
/// - Max width: 320px
/// - Padding: 24px
/// - Border radius: 20px
/// - Icon container: 40x40px, radius 50%
/// 
/// Анимация: scaleIn 200ms
```

### 9. LanguageDialog

```dart
/// Диалог выбора языка интерфейса
/// 
/// Параметры:
/// - currentLanguage: String — "ru" | "en"
/// - onSelect: Function(String)
/// - onCancel: VoidCallback
/// 
/// Языки:
/// - { code: "ru", name: "Русский", flag: "🇷🇺" }
/// - { code: "en", name: "English", flag: "🇺🇸" }
/// 
/// Стили выбранного:
/// - Border: 2px accentPrimary
/// - Background: accentMuted
/// - Checkmark справа
```

### 10. CreateFolderSheet

```dart
/// Bottom sheet создания папки
/// 
/// Поля:
/// - name: TextEditingController (обязательное)
/// - description: TextEditingController (опциональное)
/// - selectedColor: Color (из 8 вариантов)
/// - selectedIcon: IconData (из 8 вариантов)
/// 
/// Иконки папок:
/// - Icons.folder, Icons.work, Icons.book, Icons.star
/// - Icons.favorite, Icons.music_note, Icons.camera_alt, Icons.code
/// 
/// Размеры color picker:
/// - Item: 44x44px, radius 12px
/// - Gap: 12px
/// - Selected: border 3px white + shadow
/// 
/// Размеры icon picker:
/// - Item: 48x48px, radius 12px
/// - Gap: 10px
/// - Selected: border 2px accentPrimary, bg accentMuted
/// 
/// Preview card:
/// - Bg: bgTertiary
/// - Radius: 16px
/// - Padding: 16px
```

### 11. TagChip

```dart
/// Чип тега
/// 
/// Параметры:
/// - label: String — без #, добавляется автоматически
/// - onDelete: VoidCallback? — если есть, показать кнопку удаления
/// 
/// Размеры:
/// - Padding: 4px 10px (без delete) / 6px 12px (с delete)
/// - Radius: 20px
/// - Font: micro (11px)
/// 
/// Стили:
/// - Background: accentMuted
/// - Text: accentPrimary
/// - Delete icon: 14px, accentPrimary
```

### 12. DateSeparator

```dart
/// Разделитель даты в чате
/// 
/// Параметры:
/// - date: String — "Сегодня", "Вчера", "15 декабря"
/// 
/// Размеры:
/// - Padding: 6px 14px
/// - Radius: 20px
/// - Margin bottom: 16px
/// 
/// Стили:
/// - Background: bgTertiary
/// - Text: captionSmall + textTertiary
/// - Alignment: center
```

### 13. AppFab

```dart
/// Floating Action Button
/// 
/// Параметры:
/// - icon: IconData
/// - onPressed: VoidCallback
/// 
/// Размеры:
/// - Size: 56x56px
/// - Radius: 16px
/// - Icon: 24px
/// 
/// Стили:
/// - Background: accentPrimary
/// - Icon color: textInverse
/// - Shadow: 0 8px 24px accentGlow
/// 
/// Позиция:
/// - Bottom: 100px (над bottom nav)
/// - Right: 20px
```

### 14. AppBottomNav

```dart
/// Нижняя навигация
/// 
/// Пункты:
/// - { icon: Icons.folder, label: "Заметки", route: "/folders" }
/// - { icon: Icons.settings, label: "Настройки", route: "/settings" }
/// 
/// Размеры:
/// - Height: 84px (включая safe area)
/// - Padding top: 12px
/// - Icon: 24px
/// - Label: micro (11px)
/// 
/// Стили:
/// - Background: bgSecondary
/// - Border top: 1px borderPrimary
/// - Active: accentPrimary, opacity 1
/// - Inactive: textSecondary, opacity 0.5
```

### 15. DropdownMenu (для трёх точек)

```dart
/// Выпадающее меню
/// 
/// Параметры:
/// - items: List<DropdownMenuItem>
///   - icon: IconData
///   - label: String
///   - color: Color? — для destructive actions
///   - onTap: VoidCallback
/// 
/// Размеры:
/// - Min width: 200px
/// - Padding item: 14px 16px
/// - Radius: 14px
/// - Icon: 18px
/// 
/// Стили:
/// - Background: bgElevated
/// - Border: 1px borderPrimary
/// - Shadow: 0 10px 40px rgba(0,0,0,0.3)
/// - Divider: 1px borderPrimary
/// 
/// Позиция: top 100px, right 20px
/// Анимация: fadeIn 150ms
```

---

## Анимации

```dart
// Durations
const Duration durationFast = Duration(milliseconds: 150);
const Duration durationNormal = Duration(milliseconds: 200);
const Duration durationSlow = Duration(milliseconds: 300);

// Curves
const Curve curveDefault = Curves.easeOut;
const Curve curveSpring = Curves.elasticOut;

// Анимации для использования:

// 1. FadeInUp — появление элементов списка
// Использовать AnimatedList или staggered animations
// Delay между элементами: 50ms
// Duration: 300ms
// Transform: translateY(20px) -> translateY(0)
// Opacity: 0 -> 1

// 2. SlideDown — появление поиска
// Duration: 200ms
// Transform: translateY(-10px) -> translateY(0)
// Opacity: 0 -> 1

// 3. SlideUp — bottom sheet
// Duration: 300ms
// Transform: translateY(100%) -> translateY(0)

// 4. ScaleIn — модальные окна
// Duration: 200ms
// Transform: scale(0.9) -> scale(1)
// Opacity: 0 -> 1

// 5. Pulse — индикатор записи
// Duration: 1000ms, repeat
// Opacity: 1 -> 0.6 -> 1
// Scale: 1 -> 1.1 -> 1

// 6. Blink — курсор транскрипции
// Duration: 800ms, repeat
// Opacity: 1 -> 0 -> 1

// 7. Waveform — бары звуковой волны
// Duration: 100ms, repeat
// Height: random 4-28px
// Использовать Timer.periodic
```

---

## Экраны

### FoldersScreen
- AppBar: заголовок "Заметки" (h1Large), иконки поиска и настроек
- Опционально: SearchBar с анимацией slideDown
- QuickRecordCard — карточка быстрой записи
- Секция "Папки" с заголовком и счётчиком
- ListView.builder с FolderCard
- FAB для создания папки
- AppBottomNav

### FolderDetailScreen
- AppBar: back button, название папки, поиск, меню (три точки)
- Опционально: SearchBarWithFilters
- ListView с DateSeparator и NoteBubble
- RecordingInput внизу
- При нажатии на три точки — DropdownMenu

### NoteDetailScreen
- AppBar: back button, "Заметка", кнопка редактирования
- Секция "Текст" — Card или TextField в зависимости от режима
- Секция "Теги" — Wrap с TagChip + поле добавления
- Секция "Информация" — список с иконками
- Кнопки действий: Копировать, Поделиться, Удалить

### SettingsScreen
- AppBar: back button, "Настройки"
- TabBar: "Основные", "Модели"
- Tab "Основные": секции с SettingsRow
- Tab "Модели": карточка активной модели + ListView с ModelCard

---

## Модели данных

```dart
class Folder {
  final String id;
  final String name;
  final String? description;
  final Color color;
  final IconData icon;
  final int notesCount;
  final DateTime lastUpdated;
}

class Note {
  final String id;
  final String text;
  final DateTime createdAt;
  final Duration duration;
  final String modelName;
  final String language;
  final int wordCount;
  final List<String> tags;
  final bool hasAudio;
}

class AsrModel {
  final String id;
  final String name;
  final String engine; // "OpenAI Whisper" | "NVIDIA NeMo"
  final String size;
  final String languages;
  final String description;
  final bool isDownloaded;
  final bool isSelected;
}

enum RecordingState { idle, recording, transcribing }
enum SearchFilter { all, text, tags, date }
```

---

## Примечания

1. **Тема**: Использовать `Theme.of(context).extension<AppColorsExtension>()` для доступа к кастомным цветам
2. **Адаптивность**: Использовать `MediaQuery.of(context).padding.bottom` для safe area
3. **Состояние**: BLoC/Cubit для управления состоянием
4. **Навигация**: go_router для декларативной навигации
5. **Анимации**: flutter_animate для упрощения
6. **Иконки**: Lucide icons (lucide_icons package) или Feather icons
