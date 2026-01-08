import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/recording_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/quick_record_card.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/success_dialog.dart';

/// Секция быстрой записи с встроенным RecordingCubit
///
/// Оборачивает [QuickRecordCard] в BlocProvider и обрабатывает
/// показ диалогов успеха/ошибки автоматически.
class QuickRecordSection extends StatelessWidget {
  const QuickRecordSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: BlocProvider(
        create: (_) => RecordingCubit(
          recordingService: getIt<AudioRecordingService>(),
          asrService: getIt<AsrService>(),
          noteRepository: getIt<NoteRepository>(),
        ),
        child: BlocListener<RecordingCubit, RecordingState>(
          listener: _handleStateChange,
          child: const QuickRecordCard(),
        ),
      ),
    );
  }

  void _handleStateChange(BuildContext context, RecordingState state) {
    switch (state) {
      case RecordingSuccessState(:final text):
        SuccessDialog.showClipboardSuccess(context, text: text);
      case RecordingErrorState(:final failure):
        ErrorDialog.showFromFailure(context, failure);
      default:
        break;
    }
  }
}
