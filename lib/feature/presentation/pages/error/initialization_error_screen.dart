import 'package:flutter/material.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class InitializationErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const InitializationErrorScreen({
    required this.error,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Ошибка инициализации',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomSheet: Padding(
          padding: EdgeInsetsGeometry.only(
            bottom: context.bottomKeyboardInsets + context.bottomInset,
          ),
          child: ElevatedButton(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ),
      ),
    );
  }
}
