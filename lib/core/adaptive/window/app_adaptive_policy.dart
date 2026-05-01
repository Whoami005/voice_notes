import 'package:voice_notes/core/adaptive/window/app_window_size_enum.dart';

final class AppAdaptivePolicy {
  static bool useBottomNavigation(AppWindowSizeEnum size) => size.isCompact;

  static bool useNavigationRail(AppWindowSizeEnum size) =>
      size.isMediumOrLarger;

  static bool useCenteredContent(AppWindowSizeEnum size) =>
      size.isExpandedOrLarger;

  static bool useSplitView(AppWindowSizeEnum size) => size.isExpandedOrLarger;
}
