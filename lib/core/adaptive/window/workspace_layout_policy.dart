import 'package:voice_notes/core/adaptive/window/app_window_class.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';

final class WorkspaceLayoutPolicy {
  const WorkspaceLayoutPolicy._();

  static bool canUseWorkspace(AppWindowClass windowClass) {
    return _allowsByWidth(windowClass) && _allowsByHeight(windowClass);
  }

  static bool _allowsByWidth(AppWindowClass windowClass) {
    return windowClass.size.width >= AppSizes.workspaceMinWidth;
  }

  static bool _allowsByHeight(AppWindowClass windowClass) {
    return windowClass.heightSize.isMediumOrLarger;
  }
}
