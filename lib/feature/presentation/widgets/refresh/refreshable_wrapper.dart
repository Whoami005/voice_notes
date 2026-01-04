import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/state/initializable.dart';

/// Гибкий wrapper для RefreshIndicator с поддержкой Cubit
///
/// Поддерживает два режима:
/// 1. Явный callback через [onRefresh]
/// 2. Автоматический через generic [C] — если кубит реализует [Refreshable]
///
/// Примеры:
/// ```dart
/// // Явный callback
/// RefreshableWrapper(
///   onRefresh: () async { await myRefresh(); },
///   child: ListView(...),
/// )
///
/// // Через Cubit (автоматически вызовет refresh())
/// RefreshableWrapper<FoldersCubit>(
///   child: ListView(...),
/// )
/// ```
class RefreshableWrapper<C extends Cubit<dynamic>> extends StatelessWidget {
  final Widget child;
  final RefreshCallback? onRefresh;

  const RefreshableWrapper({required this.child, super.key, this.onRefresh});

  RefreshCallback? _resolveRefreshCallback(BuildContext context)  {
    if (onRefresh != null) return onRefresh;

    // Проверяем что generic был указан (не дефолтный Cubit)
    if (C != dynamic && C != Cubit) {
      final cubit = context.read<C>();

      if (cubit is Refreshable) return (cubit as Refreshable).refresh;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final refreshCallback = _resolveRefreshCallback(context);

    if (refreshCallback == null) return child;

    return RefreshIndicator.adaptive(onRefresh: refreshCallback, child: child);
  }
}
