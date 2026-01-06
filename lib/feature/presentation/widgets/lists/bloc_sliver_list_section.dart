import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/feature/presentation/widgets/conditional/conditional_child.dart';

/// Reusable sliver list section with BlocBuilder and header.
///
/// Wraps header and list inside [SliverMainAxisGroup] for proper grouping.
/// The header and list items are rebuilt reactively based on bloc
/// state changes.
///
/// Example:
/// ```dart
/// BlocSliverListSection<FoldersCubit, FoldersState, FolderEntity>(
///   selector: (state) => state.folders,
///   headerBuilder: (context, count) => SectionHeader(count: count),
///   itemBuilder: (context, folder, index) => FolderCard(folder: folder),
///   separatorBuilder: (context, index) => AppSpacer.p12,
/// )
/// ```
class BlocSliverListSection<B extends BlocBase<S>, S, T>
    extends StatelessWidget {
  /// Selector to extract list items from state.
  final List<T> Function(S state) selector;

  /// Builder for section header. Receives the count of items.
  final Widget Function(BuildContext context, List<T> items)? headerBuilder;

  /// Builder for list items.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Optional separator builder between items.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Condition for rebuilding the widget.
  /// Defaults to comparing selector results.
  final bool Function(S previous, S current)? buildWhen;

  /// Padding for the list section.
  final EdgeInsetsGeometry padding;

  const BlocSliverListSection({
    required this.selector,
    required this.headerBuilder,
    required this.itemBuilder,
    this.separatorBuilder,
    this.buildWhen,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      buildWhen:
          buildWhen ??
          (previous, current) => selector(previous) != selector(current),
      builder: (context, state) {
        final items = selector(state);

        return SliverPadding(
          padding: padding,
          sliver: SliverMainAxisGroup(
            slivers: [
              // Header section
              SliverToBoxAdapter(child: headerBuilder?.call(context, items)),

              // List section
              ConditionalChild(
                condition: separatorBuilder != null,
                onTrue: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: separatorBuilder!,
                  itemBuilder: (context, index) {
                    return itemBuilder(context, items[index], index);
                  },
                ),
                onFalse: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return itemBuilder(context, items[index], index);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
