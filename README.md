# Voice Notes

[English](#english) | [Русский](#русский)

---

## English

A mobile application for recording and transcribing voice notes using on-device speech recognition. All processing happens locally — no internet connection or cloud services required.

### Features

- **Voice recording with automatic transcription** — offline, powered by Whisper and NeMo models
- **Multiple ASR models** — choose between speed and accuracy
- **Folder organization** — custom colors and icons for each folder
- **Text notes** — create and edit notes manually
- **Tags and search** — filter notes by text, tags, or date
- **Dark and light themes**

### Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter / Dart |
| State Management | BLoC (flutter_bloc) |
| Navigation | go_router |
| Local Database | ObjectBox |
| Speech Recognition | sherpa-onnx (offline) |
| DI | injectable + get_it |
| Audio Recording | record |
| Model Downloads | background_downloader |

### Getting Started

**Prerequisites:** Flutter SDK 3.x+

```bash
git clone <repo-url>
cd voice_notes
flutter pub get
flutter run
```

### For Developers

#### Architecture

Clean Architecture with three layers:

```
lib/
├── core/            # Theme, DI, routing, packages (ASR, audio, DB)
├── common/          # Shared utilities and extensions
└── feature/
    ├── domain/      # Entities, repository interfaces, enums
    ├── data/        # Repository implementations, data sources (local/remote/mock)
    └── presentation/
        ├── pages/   # Screens grouped by feature (folders, notes, settings)
        └── widgets/ # Shared UI components (dialogs, buttons, chips, sheets)
```

Each feature screen follows the pattern: `screens/` + `widgets/` + `logic/` (Cubit + State).

#### ASR Pipeline

```
Microphone → record (16kHz WAV) → Isolate → sherpa-onnx → Transcribed text
```

Speech recognition runs in a **long-lived Dart isolate** — it is created once at app startup and reused for all subsequent operations (model loading, transcription, streaming recognition). This avoids the overhead of repeatedly spawning isolates and keeps the UI thread completely free.

| Model | Engine | Size | Languages |
|---|---|---|---|
| Whisper Tiny.en | OpenAI Whisper | 117 MB | English |
| Whisper Small | OpenAI Whisper | 466 MB | 99 languages |
| Whisper Medium | OpenAI Whisper | 1.5 GB | 99 languages |

Models are downloaded on demand and stored locally. Downloads are managed through a **queue system** — models are downloaded sequentially, with progress tracking and the ability to cancel. This prevents concurrent large downloads from competing for bandwidth and ensures a predictable user experience.

#### State Management

BLoC/Cubit pattern with custom base classes:

- **AsyncStateCubit** — standardized loading/error/success states with `AsyncStateScaffold` widget
- **Searchable mixin** — local search and filtering on any list state
- **EditableWithHistory** — undo/redo support for note editing
- **Effect system** — side effects (navigation, dialogs, toasts) separated from state

#### Reactive Data

ObjectBox streams provide real-time updates — any change in the database automatically reflects in the UI without manual refresh.

---

## Русский

Мобильное приложение для записи и транскрибации голосовых заметок с использованием распознавания речи на устройстве. Вся обработка происходит локально — без интернета и облачных сервисов.

### Возможности

- **Запись голоса с автоматической транскрипцией** — офлайн, на базе моделей Whisper и NeMo
- **Несколько моделей распознавания** — выбор между скоростью и точностью
- **Организация по папкам** — настраиваемые цвета и иконки
- **Текстовые заметки** — создание и редактирование заметок вручную
- **Теги и поиск** — фильтрация по тексту, тегам, дате
- **Темная и светлая тема**

### Стек технологий

| Слой | Технология |
|---|---|
| Фреймворк | Flutter / Dart |
| Управление состоянием | BLoC (flutter_bloc) |
| Навигация | go_router |
| Локальная БД | ObjectBox |
| Распознавание речи | sherpa-onnx (офлайн) |
| DI | injectable + get_it |
| Запись аудио | record |
| Загрузка моделей | background_downloader |

### Быстрый старт

**Требования:** Flutter SDK 3.x+

```bash
git clone <repo-url>
cd voice_notes
flutter pub get
flutter run
```

### Для разработчиков

#### Архитектура

Clean Architecture с тремя слоями:

```
lib/
├── core/            # Тема, DI, роутинг, пакеты (ASR, аудио, БД)
├── common/          # Общие утилиты и расширения
└── feature/
    ├── domain/      # Сущности, интерфейсы репозиториев, перечисления
    ├── data/        # Реализации репозиториев, источники данных (local/remote/mock)
    └── presentation/
        ├── pages/   # Экраны по фичам (папки, заметки, настройки)
        └── widgets/ # Общие UI-компоненты (диалоги, кнопки, чипы, шиты)
```

Каждый экран следует паттерну: `screens/` + `widgets/` + `logic/` (Cubit + State).

#### ASR Pipeline

```
Микрофон → record (16kHz WAV) → Isolate → sherpa-onnx → Распознанный текст
```

Распознавание речи выполняется в **долгоживущем Dart-изоляте** — он создается один раз при запуске приложения и переиспользуется для всех последующих операций (загрузка модели, транскрипция, потоковое распознавание). Это исключает накладные расходы на повторное создание изолятов и полностью освобождает UI-поток.

| Модель | Движок | Размер | Языки |
|---|---|---|---|
| Whisper Tiny.en | OpenAI Whisper | 117 МБ | Английский |
| Whisper Small | OpenAI Whisper | 466 МБ | 99 языков |
| Whisper Medium | OpenAI Whisper | 1.5 ГБ | 99 языков |

Модели загружаются по требованию и хранятся локально. Загрузки управляются через **систему очередей** — модели скачиваются последовательно, с отслеживанием прогресса и возможностью отмены. Это предотвращает конкуренцию за пропускную способность при одновременной загрузке нескольких моделей.

#### Управление состоянием

Паттерн BLoC/Cubit с кастомными базовыми классами:

- **AsyncStateCubit** — стандартизированные состояния loading/error/success с виджетом `AsyncStateScaffold`
- **Searchable mixin** — локальный поиск и фильтрация по любому списковому состоянию
- **EditableWithHistory** — поддержка undo/redo при редактировании заметок
- **Effect system** — побочные эффекты (навигация, диалоги, тосты) отделены от состояния

#### Реактивные данные

ObjectBox streams обеспечивают обновления в реальном времени — любое изменение в базе данных автоматически отражается в UI без ручного обновления.
