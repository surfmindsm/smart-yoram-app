import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 검색바 위젯
class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;
  final bool autofocus;
  final EdgeInsetsGeometry? margin;

  const SearchBarWidget({
    super.key,
    this.hintText = '검색어를 입력하세요',
    this.controller,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.autofocus = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(LucideIcons.search, color: Colors.blue[700]),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    controller?.clear();
                    if (onClear != null) onClear!();
                    if (onChanged != null) onChanged!('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }
}

/// 필터가 포함된 검색바
class SearchBarWithFilter extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final List<String> filterOptions;
  final String selectedFilter;
  final ValueChanged<String>? onFilterChanged;
  final EdgeInsetsGeometry? margin;

  const SearchBarWithFilter({
    super.key,
    this.hintText = '검색어를 입력하세요',
    this.controller,
    this.onChanged,
    this.onClear,
    required this.filterOptions,
    required this.selectedFilter,
    this.onFilterChanged,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: Column(
        children: [
          SearchBarWidget(
            hintText: hintText,
            controller: controller,
            onChanged: onChanged,
            onClear: onClear,
            margin: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterOptions.map((filter) {
                final isSelected = filter == selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => onFilterChanged?.call(filter),
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue[700],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
