import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/enums/recording_state.dart';

class SearchBarWithFilters extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final SearchFilter activeFilter;
  final ValueChanged<SearchFilter> onFilterChanged;
  final String placeholder;
  final EdgeInsetsGeometry padding;

  const SearchBarWithFilters({
    required this.query,
    required this.onQueryChanged,
    required this.activeFilter,
    required this.onFilterChanged,
    this.padding = const EdgeInsets.only(
      left: AppSizes.screenPadding,
      right: AppSizes.screenPadding,
    ),
    this.placeholder = 'Поиск...',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: query,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: placeholder,
              prefixIcon: Icon(Icons.search, color: themeColors.textTertiary),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: themeColors.textTertiary),
                      onPressed: () => onQueryChanged(''),
                    )
                  : null,
            ),
          ),
          AppSpacer.p12,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(SearchFilter.values.length, (index) {
                final filter = SearchFilter.values[index];
                final isActive = filter == activeFilter;

                return Padding(
                  padding: const EdgeInsets.only(right: AppSizes.p8),
                  child: _FilterChip(
                    label: filter.title,
                    isActive: isActive,
                    onTap: () => onFilterChanged(filter),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p14,
          vertical: AppSizes.p6,
        ),
        decoration: BoxDecoration(
          color: isActive ? themeColors.accentPrimary : themeColors.bgTertiary,
          borderRadius: BorderRadius.circular(AppSizes.chipRadius),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isActive
                ? themeColors.textInverse
                : themeColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
