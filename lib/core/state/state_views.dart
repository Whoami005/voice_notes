import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

/// Индикатор загрузки
class StateLoadingView extends StatelessWidget {
  const StateLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Виджет пустого состояния
class StateEmptyView extends StatelessWidget {
  final String message;

  const StateEmptyView({super.key, this.message = 'Пусто'});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.themeColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Text(
          message,
          style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Виджет ошибки
class StateErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const StateErrorView({
    required this.message,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.themeColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: textTheme.bodyLarge?.copyWith(color: colors.error),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.p16),
              TextButton(
                onPressed: onRetry,
                child: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
