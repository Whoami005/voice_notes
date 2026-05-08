import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/adaptive/window/adaptive_content_width.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/queue/components/queue_cancelled_section.dart';
import 'package:voice_notes/feature/presentation/pages/queue/components/queue_failed_section.dart';
import 'package:voice_notes/feature/presentation/pages/queue/components/queue_processing_section.dart';
import 'package:voice_notes/feature/presentation/pages/queue/components/queue_queued_section.dart';
import 'package:voice_notes/feature/presentation/pages/queue/components/queue_status_card.dart';
import 'package:voice_notes/feature/presentation/pages/queue/components/queue_warning_banner.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/queue_management_cubit.dart';

class QueueManagementScreen extends StatelessWidget implements AppRouteWrapper {
  const QueueManagementScreen({super.key});

  static void go(BuildContext context) {
    context.router.go(AppRoutes.settings.queue);
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => QueueManagementCubit(
        noteRepository: getIt<NoteRepository>(),
        queueController: getIt<TranscriptionQueueController>(),
      ),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Scaffold(
      backgroundColor: themeColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: themeColors.bgPrimary,
        title: Text(context.l10n.queueScreenTitle),
      ),
      body: AdaptiveContentWidth(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.p16,
            horizontal: AppSizes.screenPadding,
          ),
          children: const [
            QueueStatusCard(),
            QueueWarningBanner(),
            QueueProcessingSection(),
            QueueQueuedSection(),
            QueueFailedSection(),
            QueueCancelledSection(),
            AppSpacer.p40,
          ],
        ),
      ),
    );
  }
}
