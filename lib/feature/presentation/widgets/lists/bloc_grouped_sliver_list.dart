import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/common/utils/date_grouper.dart';
import 'package:voice_notes/feature/presentation/widgets/conditional/conditional_child.dart';

/// Reusable sliver list with BlocBuilder integration for grouped data.
///
/// Features:
/// - Lazy construction via SliverList.builder
/// - Configurable buildWhen for selective rebuilds
/// - Built-in support for DateGroup structure with headers
///
/// Example:
/// ```dart
/// BlocGroupedSliverList<MyCubit, BaseState<MyData>, Note>(
///   selector: (state) => state.dataOrNull?.groupedNotes ?? [],
///   buildWhen: (prev, curr) =>
///     prev.dataOrNull?.groupedNotes != curr.dataOrNull?.groupedNotes,
///   headerBuilder: (context, label) => DateSeparator(date: label),
///   itemBuilder: (context, note, index) => NoteBubble(note: note),
/// )
/// ```
class BlocGroupedSliverList<B extends BlocBase<S>, S, T>
    extends StatelessWidget {
  /// Selector to extract grouped items from state
  final List<DateGroup<T>> Function(S state) selector;

  /// Builder for group headers (receives label like "Сегодня", "Вчера", etc.)
  final Widget Function(BuildContext context, String label) headerBuilder;

  /// Builder for items within each group
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Condition for rebuilding the widget.
  /// Defaults to comparing selector results using listEquals.
  final bool Function(S previous, S current)? buildWhen;
  final Widget Function(BuildContext, int)? separatorBuilder;
  final EdgeInsetsGeometry padding;

  const BlocGroupedSliverList({
    required this.selector,
    required this.headerBuilder,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding = EdgeInsets.zero,
    super.key,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      buildWhen:
          buildWhen ??
          (previous, current) => selector(previous) != selector(current),
      builder: (context, state) {
        final groups = selector(state);

        if (groups.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Пусто')),
          );
        }

        // Calculate total item count: sum of (1 header + items) for each group
        final totalCount = groups.fold<int>(
          0,
          (sum, group) => sum + 1 + group.items.length,
        );

        return SliverPadding(
          padding: padding,
          sliver: ConditionalChild.builder(
            isSliver: true,
            condition: separatorBuilder != null,
            onTrue: (context) {
              return SliverList.separated(
                itemCount: totalCount,
                separatorBuilder: separatorBuilder!,
                itemBuilder: (context, index) =>
                    _buildItem(context, groups, index),
              );
            },
            onFalse: (context) {
              return SliverList.builder(
                itemCount: totalCount,
                itemBuilder: (context, index) =>
                    _buildItem(context, groups, index),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildItem(
    BuildContext context,
    List<DateGroup<T>> groups,
    int index,
  ) {
    var currentIndex = 0;

    for (final group in groups) {
      // Header position
      if (index == currentIndex) return headerBuilder(context, group.label);
      currentIndex++;

      // Items in this group
      final itemsCount = group.items.length;
      if (index < currentIndex + itemsCount) {
        final itemIndex = index - currentIndex;
        return itemBuilder(context, group.items[itemIndex], itemIndex);
      }

      currentIndex += itemsCount;
    }

    // Should not reach here if totalCount is calculated correctly
    return const SizedBox.shrink();
  }
}
