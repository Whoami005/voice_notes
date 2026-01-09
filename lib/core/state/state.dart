// ═══════════════════════════════════════════════════════════════════════
// Core — базовая инфраструктура
// ═══════════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════
// Async — sealed state паттерн (Initial/Loading/Success/Error)
// ═══════════════════════════════════════════════════════════════════════
export 'async/async_cubit.dart';
export 'async/async_state.dart';
export 'async/async_state_widgets.dart';
export 'async/initializable_async_cubits.dart';
export 'core/base_cubit.dart';
export 'core/cubit_mixin.dart';

// ═══════════════════════════════════════════════════════════════════════
// Editable — редактируемые состояния
// ═══════════════════════════════════════════════════════════════════════
export 'editable/editable.dart';
export 'editable/editable_with_history.dart';
export 'editable/validated_editable.dart';

// ═══════════════════════════════════════════════════════════════════════
// Effect — эффекты для UI-событий
// ═══════════════════════════════════════════════════════════════════════
export 'effect/effect.dart';

// ═══════════════════════════════════════════════════════════════════════
// Mutations
// ═══════════════════════════════════════════════════════════════════════
export 'mutation_notifier.dart';

// ═══════════════════════════════════════════════════════════════════════
// Searchable — поиск
// ═══════════════════════════════════════════════════════════════════════
export 'searchable/local_search_mixin.dart';
export 'searchable/local_searchable.dart';
export 'searchable/search_highlighter.dart';
export 'searchable/search_matchers.dart';
export 'searchable/searchable.dart';

// ═══════════════════════════════════════════════════════════════════════
// Shared — общие интерфейсы и виджеты
// ═══════════════════════════════════════════════════════════════════════
export 'shared/initializable.dart';
export 'shared/state_views.dart';

// ═══════════════════════════════════════════════════════════════════════
// Status — enum-based state паттерн
// ═══════════════════════════════════════════════════════════════════════
export 'status/initializable_status_cubits.dart';
export 'status/status_cubit.dart';
export 'status/status_state.dart';
export 'status/status_state_widgets.dart';
