import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/adaptive/window/app_window_class.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_route_names.dart';
import 'package:voice_notes/core/packages/app_router/routes/settings_route_presentation.dart';

void main() {
  group('SettingsRoutePresentation', () {
    test('maps general route to models workspace selection', () {
      final presentation = SettingsRoutePresentation.resolve(
        routeName: AppRouteNames.settings.general,
        windowClass: AppWindowClass.fromSize(
          const Size(AppSizes.workspaceMinWidth, 900),
        ),
      );

      expect(presentation.isWorkspaceActive, isTrue);
      expect(presentation.paneBranchIndex, 1);
      expect(presentation.selectedSidebarItem, SettingsSidebarSelection.models);
      expect(presentation.paneBranch, SettingsPaneBranch.models);
      expect(presentation.showFullscreenChild, isFalse);
      expect(presentation.showAutomaticBack, isFalse);
    });

    test('shows queue and storage routes fullscreen on compact surfaces', () {
      final queuePresentation = SettingsRoutePresentation.resolve(
        routeName: AppRouteNames.settings.queue,
        windowClass: AppWindowClass.fromSize(
          const Size(AppSizes.workspaceMinWidth - 1, 900),
        ),
      );
      final storagePresentation = SettingsRoutePresentation.resolve(
        routeName: AppRouteNames.settings.storage,
        windowClass: AppWindowClass.fromSize(
          const Size(AppSizes.workspaceMinWidth - 1, 900),
        ),
      );

      expect(queuePresentation.showFullscreenChild, isTrue);
      expect(storagePresentation.showFullscreenChild, isTrue);
      expect(queuePresentation.showAutomaticBack, isTrue);
      expect(storagePresentation.showAutomaticBack, isTrue);
    });

    test('uses local pane back for storage detail in workspace', () {
      final presentation = SettingsRoutePresentation.resolve(
        routeName: AppRouteNames.settings.storageDetail,
        windowClass: AppWindowClass.fromSize(
          const Size(AppSizes.workspaceMinWidth, 900),
        ),
      );

      expect(presentation.paneBranchIndex, 0);
      expect(
        presentation.selectedSidebarItem,
        SettingsSidebarSelection.storage,
      );
      expect(presentation.paneBranch, SettingsPaneBranch.general);
      expect(presentation.showFullscreenChild, isFalse);
      expect(presentation.showAutomaticBack, isFalse);
      expect(presentation.localBackLocation, '/settings/general/storage');
    });
  });
}
