/// Editable pattern for tracking changes to Equatable objects.
///
/// Provides:
/// - [Editable] - basic change tracking
/// - [EditableWithHistory] - with undo/redo support
/// - [ValidatedEditable] - with validation support
library;

import 'package:voice_notes/core/state/editable/editable.dart';
import 'package:voice_notes/core/state/editable/editable_with_history.dart';
import 'package:voice_notes/core/state/editable/validated_editable.dart';

export 'editable.dart';
export 'editable_with_history.dart';
export 'validated_editable.dart';
