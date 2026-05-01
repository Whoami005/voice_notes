import 'package:flutter/widgets.dart';
import 'package:voice_notes/core/adaptive/constraint/constraint_size_enum.dart';

class ConstraintBreakpoints {
  final double smallMaxWidth;
  final double mediumMaxWidth;

  const ConstraintBreakpoints({
    required this.smallMaxWidth,
    required this.mediumMaxWidth,
  }) : assert(smallMaxWidth >= 0, 'smallMaxWidth must be non-negative'),
       assert(mediumMaxWidth >= 0, 'mediumMaxWidth must be non-negative'),
       assert(smallMaxWidth < double.infinity, 'smallMaxWidth must be finite'),
       assert(
         mediumMaxWidth < double.infinity,
         'mediumMaxWidth must be finite',
       ),
       assert(
         smallMaxWidth < mediumMaxWidth,
         'smallMaxWidth must be less than mediumMaxWidth',
       );

  ConstraintSizeEnum fromWidth(double width) {
    assert(width >= 0, 'width must be non-negative');

    if (width <= smallMaxWidth) return ConstraintSizeEnum.small;
    if (width <= mediumMaxWidth) return ConstraintSizeEnum.medium;

    return ConstraintSizeEnum.large;
  }

  ConstraintSizeEnum fromConstraints(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return ConstraintSizeEnum.large;

    return fromWidth(constraints.maxWidth);
  }
}
