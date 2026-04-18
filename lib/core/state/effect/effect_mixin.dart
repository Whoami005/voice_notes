import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/state/effect/effect_bloc_observer.dart';

/// One-shot эффекты для Cubit/Bloc — события, которые не влияют на состояние,
/// но требуют реакции UI (диалоги, snackbar, навигация).
///
/// ```dart
/// class MyCubit extends Cubit<MyState> with EffectMixin<MyEffect> {
///   void doSomething() {
///     emitEffect(ShowErrorEffect(failure));
///   }
/// }
/// ```
mixin EffectMixin<E> on Closable {
  final _effectController = StreamController<E>.broadcast();

  EffectBlocObserver? get _effectsBlocObserver {
    final observer = Bloc.observer;
    return observer is EffectBlocObserver ? observer : null;
  }

  Stream<E> get effects => _effectController.stream;

  bool get isEffectsClosed => _effectController.isClosed;

  @protected
  void emitEffect(E effect) {
    if (isClosed || isEffectsClosed) {
      throw StateError('emitEffect called after close');
    }

    // ignore: invalid_use_of_protected_member
    _effectsBlocObserver?.onEffect(this, effect as Object);
    _effectController.add(effect);
  }

  void safeEmitEffect(E effect) {
    if (isClosed || isEffectsClosed) return;

    // Called from mixin, not a subclass — intentional cross-boundary call.
    // ignore: invalid_use_of_protected_member
    _effectsBlocObserver?.onEffect(this, effect as Object);
    _effectController.add(effect);
  }

  @protected
  @mustCallSuper
  Future<void> closeEffects() async {
    await _effectController.close();
  }

  @override
  @mustCallSuper
  Future<void> close() async {
    if (!isEffectsClosed) await closeEffects();
    return super.close();
  }
}
