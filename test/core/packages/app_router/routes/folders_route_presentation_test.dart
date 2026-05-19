import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/adaptive/window/app_window_class.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_route_names.dart';
import 'package:voice_notes/core/packages/app_router/routes/folders_route_presentation.dart';

void main() {
  group('FoldersRoutePresentation', () {
    test('keeps root compact routes on single pane', () {
      final presentation = FoldersRoutePresentation.resolve(
        routeName: AppRouteNames.folders.root,
        pathParameters: const {},
        windowClass: AppWindowClass.fromSize(
          const Size(AppSizes.workspaceMinWidth - 1, 900),
        ),
      );

      expect(presentation.isWorkspaceActive, isFalse);
      expect(presentation.showDetailPane, isFalse);
      expect(presentation.showAutomaticBack, isTrue);
      expect(presentation.localBackLocation, isNull);
    });

    test('treats folder detail as workspace pane root', () {
      final presentation = FoldersRoutePresentation.resolve(
        routeName: AppRouteNames.folders.detail,
        pathParameters: const {'id': 'folder-1'},
        windowClass: AppWindowClass.fromSize(
          const Size(AppSizes.workspaceMinWidth, 900),
        ),
      );

      expect(presentation.isWorkspaceActive, isTrue);
      expect(presentation.showDetailPane, isTrue);
      expect(presentation.showAutomaticBack, isFalse);
      expect(presentation.localBackLocation, isNull);
    });

    test('uses local pane back for note detail in workspace', () {
      final presentation = FoldersRoutePresentation.resolve(
        routeName: AppRouteNames.folders.noteDetail,
        pathParameters: const {'id': 'folder-1', 'noteId': 'note-1'},
        windowClass: AppWindowClass.fromSize(
          const Size(AppSizes.workspaceMinWidth, 900),
        ),
      );

      expect(presentation.isWorkspaceActive, isTrue);
      expect(presentation.showDetailPane, isTrue);
      expect(presentation.showAutomaticBack, isFalse);
      expect(presentation.localBackLocation, '/folders/folder-1');
    });
  });
}
