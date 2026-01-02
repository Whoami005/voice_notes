import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/state/base_cubit.dart';
import 'package:voice_notes/core/state/initializable.dart';

part 'folders_state.dart';

class FoldersCubit extends BaseCubit<FoldersState> implements Refreshable {
  // FoldersCubit();

  @override
  Future<void> init() async {
    await guard(() async {
      // await Future.delayed(const Duration(seconds: 2));

      return const FoldersState();
    });
  }

  @override
  Future<void> refresh() async {
    await updateSafe((_) async {
      // await Future.delayed(const Duration(seconds: 2));

      return const FoldersState();
    });
  }
}
