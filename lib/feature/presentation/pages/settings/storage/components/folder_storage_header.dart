import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/common/utils/format_bytes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/logic/folder_storage_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';

typedef _HeaderVm = ({String? folderName, int totalBytes, int notesCount});

/// Header детального экрана хранилища: имя папки, размер/счётчик и кнопка
/// очистки всех записей внутри папки.
class FolderStorageHeader extends StatelessWidget {
  const FolderStorageHeader({super.key});

  Future<void> _onClearFolderTap(BuildContext context, _HeaderVm vm) async {
    final cubit = context.read<FolderStorageCubit>();
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.storageClearFolderConfirmTitle,
      message: l10n.storageClearFolderConfirmMessage(
        vm.notesCount,
        BytesFormatter.format(vm.totalBytes),
      ),
      confirmText: l10n.dialogClear,
      confirmColor: themeColors.error,
    );

    if ((confirmed ?? false) && context.mounted) {
      await cubit.deleteAllInFolder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return BlocSelector<FolderStorageCubit, FolderStorageState, _HeaderVm>(
      selector: (state) => (
        folderName: state.folder?.name,
        totalBytes: state.totalBytes,
        notesCount: state.notes.length,
      ),
      builder: (context, vm) {
        final folderName = vm.folderName ?? l10n.storageWithoutFolder;
        final bytesLabel = BytesFormatter.format(vm.totalBytes);
        final countLabel = l10n.storageRecordingsCount(vm.notesCount);
        final hasNotes = vm.notesCount > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              folderName,
              style: textTheme.titleLarge?.copyWith(
                color: themeColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacer.p4,
            Text(
              '$bytesLabel · $countLabel',
              style: textTheme.bodyMedium?.copyWith(
                color: themeColors.textSecondary,
              ),
            ),
            if (hasNotes) ...[
              AppSpacer.p16,
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _onClearFolderTap(context, vm),
                  icon: Icon(
                    Icons.delete_sweep_outlined,
                    color: themeColors.error,
                  ),
                  label: Text(
                    l10n.storageClearFolderButton,
                    style: textTheme.labelLarge?.copyWith(
                      color: themeColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
