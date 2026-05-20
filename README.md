<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/cac1c323-4aa1-4ae3-8832-eedbfac71a67" width="250"/></td>
    <td><img src="https://github.com/user-attachments/assets/0efefa57-7322-4e17-bc89-905f6f401a07" width="250"/></td>
    <td><img src="https://github.com/user-attachments/assets/f053ebe9-8018-4c94-b890-74cc9f8f3dc4" width="250"/></td>
    <td><img src="https://github.com/user-attachments/assets/b191a680-2bd9-4654-af87-df046f6ae219" width="250"/></td>
  </tr>
</table>
<p align="center">
  <img src="https://github.com/user-attachments/assets/a2239e37-c648-4ca3-80bd-1b62453faf9f" width="250"/>
  <img src="https://github.com/user-attachments/assets/44c0eec0-3634-43f7-ae76-8c256952be47" width="250"/>
  <img src="https://github.com/user-attachments/assets/11f20e11-d84b-4e8d-a53c-6ab15aaea45b" width="250"/>
</p>


# Voice Notes

[![Latest release](https://img.shields.io/github/v/release/Whoami005/voice_notes?display_name=tag)](https://github.com/Whoami005/voice_notes/releases/latest)
[![Download latest APK](https://img.shields.io/badge/Download-latest%20APK-191919?logo=android&logoColor=white)](https://github.com/Whoami005/voice_notes/releases/latest/download/voice-notes-latest.apk)

[English](#english) | [Русский](#русский)

---

## English

A mobile application for recording and transcribing voice notes with on-device speech recognition. All transcription runs locally after the required ASR model is downloaded.

### Download

- [Latest release notes](https://github.com/Whoami005/voice_notes/releases/latest)
- [Download latest APK](https://github.com/Whoami005/voice_notes/releases/latest/download/voice-notes-latest.apk)

The direct APK link always points to the newest GitHub Release asset with the stable name `voice-notes-latest.apk`.

### Features

- **Offline voice recording with automatic transcription** — powered by six downloadable ASR models across Whisper, NeMo Parakeet, and Zipformer families
- **Quick Record mode** — tap once to record, transcribe, and copy text to the clipboard without creating a note
- **Background transcription queue** — queued, processing, failed, and cancelled states with progress, retry, cancel, and recovery after interrupted runs
- **Audio storage controls** — keep original WAV recordings for playback, or disable future originals to save space
- **Inline waveform player and global mini-player** — play, seek, and resume recordings directly inside notes and across app sections
- **Folder organization** — custom colors and icons for each folder
- **Text notes, tags, and live folder search**
- **Storage management** — inspect disk usage by folder and remove individual recordings, a whole folder, or all audio
- **Backup export and import** — create ZIP backups with optional audio attachments and restore them later
- **Dark and light themes**
- **Russian and English UI**

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
| Audio Playback | just_audio |
| Waveform | just_waveform |
| Model Downloads | background_downloader |
| Backup & Restore | archive, share_plus, file_picker |
| Storage Insights | disk_space_2 |
| Reactive Utilities | rxdart |

### Getting Started

**Prerequisites:** Flutter SDK 3.38+ and Dart 3.10+

```bash
git clone <repo-url>
cd voice_notes
flutter pub get
flutter run
```

### For Developers

#### CI/CD and releases

The repository includes GitHub Actions workflows for CI and Android releases. See [RELEASING.md](RELEASING.md) for the required GitHub secrets, repository settings, and the tag-based release flow.

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
Microphone → record (16kHz WAV) → queue or Quick Record → Isolate → sherpa-onnx → note or clipboard
```

Speech recognition runs in a **long-lived Dart isolate** — it is created once at app startup and reused for model loading, transcription, and streaming recognition. This avoids the overhead of repeatedly spawning isolates and keeps the UI thread free.

| Model | Engine | Size | Languages | Mode | Best for |
|---|---|---|---|---|---|
| Whisper Tiny | OpenAI Whisper | 117 MB | English | Offline | Fast English transcription on smaller devices |
| Whisper Small | OpenAI Whisper | 466 MB | 99 languages | Offline | Balanced multilingual transcription |
| Whisper Medium | OpenAI Whisper | 1.5 GB | 99 languages | Offline | Highest Whisper accuracy |
| Parakeet V3 | NVIDIA NeMo | 640 MB | 25 European languages including Russian | Offline | Non-Whisper multilingual offline transcription |
| Streaming Zipformer EN | k2-fsa Zipformer | 85 MB | English | Streaming | Low-latency English recognition |
| Streaming Zipformer EN 20M | k2-fsa Zipformer | 44 MB | English | Streaming | Lightweight English model for weaker devices |

Whisper and Parakeet cover broader offline transcription scenarios, while Zipformer models target low-latency English recognition. Models are downloaded on demand and stored locally.

#### Model Downloads

Model downloads run through `background_downloader` with progress tracking, pause/resume/cancel support, retries, and system notifications. The downloader uses a bounded background queue so large model archives do not overwhelm the device.

#### Transcription Queue

Folder recordings become queued notes and are processed by a background FIFO transcription service backed by ObjectBox streams. The queue screen exposes processing, queued, failed, and cancelled sections, plus per-note retry and cancel actions.

The queue can pause itself when no ASR model is ready or when the previous run was interrupted and needs an explicit resume. `Quick Record` bypasses normal note creation and uses a priority transcription lane to return clipboard text immediately.

#### Audio Storage & Playback

When **Keep originals** is enabled, recordings are saved as 16 kHz mono WAV files inside the app documents directory. Users can disable this for future recordings to reduce storage usage; note metadata still remains in ObjectBox.

Playback goes through a **single shared `AudioPlaybackController`** built on `just_audio`. Switching between notes preserves each track's position without creating new players, and the app surfaces the active session through a global mini-player. Waveforms are generated once per file via `just_waveform` and drawn by a custom painter that supports tap and drag to seek.

#### Storage Management

The **Storage** screen shows overall audio usage and per-folder totals in real time. Users can drill into a folder, review individual recordings, and delete audio one by one, by folder, or all at once. Everything updates live via ObjectBox streams.

#### Data Portability

Backups are exported as ZIP archives that include a manifest, app data, and optional audio files. The export flow can share the generated archive through the system share sheet.

Imports first inspect the backup, show warnings such as missing audio files, and then replace the current local dataset and selected app settings. Import is intentionally blocked while the transcription queue is not empty.

#### State Management

BLoC/Cubit pattern with custom base classes:

- **AsyncCubit** — standardized `AsyncState<T>` loading/error/success flow
- **StatusCubit** — enum-based state flow for more complex screens
- **LocalSearchMixin** — debounced local search and filtering on any list state
- **EditableWithHistory** — undo/redo support for note editing
- **Effect system** — side effects (navigation, dialogs, toasts) separated from state

#### Reactive Data

ObjectBox streams provide real-time updates — any change in the database automatically reflects in the UI without manual refresh.

#### Development Workflow

Common local commands:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
```

---

## Русский

Мобильное приложение для записи и транскрибации голосовых заметок с распознаванием речи на устройстве. Вся транскрибация выполняется локально после загрузки нужной ASR-модели.

### Скачать

- [Последний релиз](https://github.com/Whoami005/voice_notes/releases/latest)
- [Скачать последний APK](https://github.com/Whoami005/voice_notes/releases/latest/download/voice-notes-latest.apk)

Прямая ссылка на APK всегда ведет на asset `voice-notes-latest.apk` из самого свежего GitHub Release.

### Возможности

- **Офлайн-запись голоса с автоматической транскрипцией** — на базе шести загружаемых ASR-моделей из семейств Whisper, NeMo Parakeet и Zipformer
- **Режим Quick Record** — записать, транскрибировать и сразу скопировать текст в буфер обмена без создания заметки
- **Фоновая очередь транскрибации** — состояния queued, processing, failed и cancelled, прогресс, retry, cancel и восстановление после прерванного запуска
- **Управление хранением аудио** — можно сохранять исходные WAV-файлы для прослушивания или отключить будущие оригиналы ради экономии места
- **Waveform-плеер в заметке и глобальный mini-player** — воспроизведение, перемотка и возврат к активной записи из разных разделов приложения
- **Организация по папкам** — настраиваемые цвета и иконки
- **Текстовые заметки, теги и живой поиск по папкам**
- **Управление хранилищем** — просмотр занятого места по папкам и удаление отдельных записей, папки целиком или всего аудио
- **Экспорт и импорт backup-файлов** — ZIP-архивы с опциональным включением аудио
- **Темная и светлая тема**
- **Русский и английский интерфейс**

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
| Воспроизведение аудио | just_audio |
| Волна | just_waveform |
| Загрузка моделей | background_downloader |
| Backup и перенос данных | archive, share_plus, file_picker |
| Аналитика хранилища | disk_space_2 |
| Реактивные утилиты | rxdart |

### Быстрый старт

**Требования:** Flutter SDK 3.38+ и Dart 3.10+

```bash
git clone <repo-url>
cd voice_notes
flutter pub get
flutter run
```

### Для разработчиков

#### CI/CD и релизы

В репозитории уже предусмотрены GitHub Actions workflow для CI и Android-релизов. Про обязательные GitHub secrets, настройки репозитория и процесс релиза по тегу написано в [RELEASING.md](RELEASING.md).

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
Микрофон → record (16kHz WAV) → очередь или Quick Record → Isolate → sherpa-onnx → заметка или буфер обмена
```

Распознавание речи выполняется в **долгоживущем Dart-изоляте** — он создается один раз при запуске приложения и переиспользуется для загрузки моделей, транскрипции и потокового распознавания. Это убирает накладные расходы на повторное создание изолятов и не блокирует UI-поток.

| Модель | Движок | Размер | Языки | Режим | Лучший сценарий |
|---|---|---|---|---|---|
| Whisper Tiny | OpenAI Whisper | 117 МБ | Английский | Offline | Быстрая английская транскрибация на слабых устройствах |
| Whisper Small | OpenAI Whisper | 466 МБ | 99 языков | Offline | Сбалансированная мультиязычная транскрибация |
| Whisper Medium | OpenAI Whisper | 1.5 ГБ | 99 языков | Offline | Максимальная точность среди Whisper |
| Parakeet V3 | NVIDIA NeMo | 640 МБ | 25 европейских языков, включая русский | Offline | Мультиязычная offline-транскрибация вне семейства Whisper |
| Streaming Zipformer EN | k2-fsa Zipformer | 85 МБ | Английский | Streaming | Низкая задержка при английском распознавании |
| Streaming Zipformer EN 20M | k2-fsa Zipformer | 44 МБ | Английский | Streaming | Лёгкая модель для слабых устройств |

Whisper и Parakeet покрывают сценарии полноценной offline-транскрибации, а Zipformer ориентирован на английское распознавание с низкой задержкой. Все модели загружаются по требованию и затем хранятся локально.

#### Загрузка моделей

Скачивание моделей работает через `background_downloader` с прогрессом, pause/resume/cancel, ретраями и системными уведомлениями. Для больших архивов используется ограниченная фоновая очередь, чтобы не перегружать устройство одновременными загрузками.

#### Очередь транскрибации

Записи из папок превращаются в queued-заметки и обрабатываются фоновым FIFO-сервисом очереди поверх потоков ObjectBox. На отдельном экране видны секции processing, queued, failed и cancelled, а также действия retry и cancel для конкретных заметок.

Очередь может поставить выполнение на паузу, если не выбрана или не загружена ASR-модель, либо если предыдущий запуск был прерван и требуется явное возобновление. `Quick Record` обходит обычное создание заметки и использует приоритетную дорожку транскрибации для немедленного результата в буфере обмена.

#### Хранение и воспроизведение аудио

Если включён параметр **Keep originals**, записи сохраняются как WAV-файлы 16 кГц mono в директории документов приложения. Для будущих записей это можно отключить, чтобы экономить место; метаданные заметок при этом всё равно остаются в ObjectBox.

Воспроизведение идёт через **единый общий `AudioPlaybackController`** поверх `just_audio`. При переключении между заметками позиция каждого трека сохраняется, новые плееры не создаются, а активная сессия доступна через глобальный mini-player. Волны генерируются один раз на файл через `just_waveform` и отрисовываются кастомным painter'ом с поддержкой перемотки тапом и свайпом.

#### Управление хранилищем

Экран **Хранилище** показывает общий объём аудио и статистику по папкам в реальном времени. Пользователь может провалиться в папку, посмотреть отдельные записи и удалить аудио — поштучно, по папке или всё сразу. Всё обновляется на лету через потоки ObjectBox.

#### Перенос данных

Backup-файлы экспортируются в ZIP-архивы с manifest, данными приложения и опциональными аудиофайлами. Готовый архив можно сразу отправить через системный share sheet.

Импорт сначала инспектирует backup, показывает предупреждения, например о недостающих аудиофайлах, а затем полностью заменяет текущие локальные данные и выбранные настройки приложения. Пока очередь транскрибации не пуста, импорт намеренно блокируется.

#### Управление состоянием

Паттерн BLoC/Cubit с кастомными базовыми классами:

- **AsyncCubit** — стандартизированный `AsyncState<T>` для loading/error/success сценариев
- **StatusCubit** — enum-based состояния для более сложных экранов
- **LocalSearchMixin** — debounce-поиск и локальная фильтрация в списковых состояниях
- **EditableWithHistory** — поддержка undo/redo при редактировании заметок
- **Effect system** — побочные эффекты (навигация, диалоги, тосты) отделены от состояния

#### Реактивные данные

ObjectBox streams обеспечивают обновления в реальном времени — любое изменение в базе данных автоматически отражается в UI без ручного обновления.

#### Рабочий цикл разработки

Часто используемые локальные команды:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
```
