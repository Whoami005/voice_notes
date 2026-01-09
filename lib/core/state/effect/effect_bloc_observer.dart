import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

/// Расширение BlocObserver с поддержкой эффектов
abstract class EffectBlocObserver extends BlocObserver {
  /// Вызывается при эмите эффекта
  @protected
  @mustCallSuper
  void onEffect(Closable bloc, Object effect) {}
}
