import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';

class AppSelectOption<T> {
  final T value;
  final String label;
  final Widget? leading;
  final Widget? trailing;
  final bool disabled;

  const AppSelectOption({
    required this.value,
    required this.label,
    this.leading,
    this.trailing,
    this.disabled = false,
  });
}

class AppSelect<T> extends StatefulWidget {
  final T? value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? placeholder;
  final String? label;
  final String? errorText;
  final bool disabled;
  final Widget? prefixIcon;
  final bool searchable;
  final double? width;
  final double? height;

  const AppSelect({
    Key? key,
    this.value,
    required this.options,
    this.onChanged,
    this.placeholder,
    this.label,
    this.errorText,
    this.disabled = false,
    this.prefixIcon,
    this.searchable = false,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<AppSelect<T>> createState() => _AppSelectState<T>();
}

class _AppSelectState<T> extends State<AppSelect<T>> {
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late TextEditingController _searchController;
  List<AppSelectOption<T>> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredOptions = widget.options;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _closeDropdown();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
    _searchController.clear();
    _filteredOptions = widget.options;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredOptions = widget.options
          .where((option) => 
              option.label.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: NewAppColor.borderHair),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.searchable) ...[
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(LucideIcons.search, size: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredOptions.length,
                      itemBuilder: (context, index) {
                        final option = _filteredOptions[index];
                        final isSelected = option.value == widget.value;
                        
                        return InkWell(
                          onTap: option.disabled ? null : () {
                            widget.onChanged?.call(option.value);
                            _closeDropdown();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected 
                                ? NewAppColor.skyTint 
                                : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                if (option.leading != null) ...[
                                  option.leading!,
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: option.disabled
                                        ? NewAppColor.textTertiary
                                        : isSelected
                                          ? NewAppColor.skyPrimary
                                          : NewAppColor.textStrong,
                                    ),
                                  ),
                                ),
                                if (option.trailing != null) option.trailing!,
                                if (isSelected)
                                  const Icon(
                                    LucideIcons.check,
                                    size: 16,
                                    color: NewAppColor.skyPrimary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _displayText {
    if (widget.value == null) {
      return widget.placeholder ?? 'Select an option';
    }
    
    final selectedOption = widget.options.firstWhere(
      (option) => option.value == widget.value,
      orElse: () => AppSelectOption(
        value: widget.value!,
        label: widget.value.toString(),
      ),
    );
    
    return selectedOption.label;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NewAppColor.textStrong,
            ),
          ),
          const SizedBox(height: 6),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: widget.disabled ? null : _toggleDropdown,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height ?? 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.errorText != null 
                    ? NewAppColor.danger700
                    : _isOpen
                      ? NewAppColor.skyPrimary
                      : widget.disabled 
                        ? NewAppColor.borderStrong
                        : NewAppColor.borderHair,
                  width: _isOpen ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: widget.disabled ? NewAppColor.canvasAlt : Colors.white,
              ),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    widget.prefixIcon!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      _displayText,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.value == null
                          ? NewAppColor.textTertiary
                          : widget.disabled
                            ? NewAppColor.textTertiary
                            : NewAppColor.textStrong,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    color: widget.disabled ? NewAppColor.textTertiary : NewAppColor.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: NewAppColor.danger700,
            ),
          ),
        ],
      ],
    );
  }

  // Named constructors for common use cases
  static AppSelect<String> text({
    Key? key,
    String? value,
    required List<String> options,
    ValueChanged<String?>? onChanged,
    String? placeholder,
    String? label,
    String? errorText,
    bool disabled = false,
    Widget? prefixIcon,
    bool searchable = false,
    double? width,
    double? height,
  }) {
    return AppSelect<String>(
      key: key,
      value: value,
      options: options.map((option) => AppSelectOption(
        value: option,
        label: option,
      )).toList(),
      onChanged: onChanged,
      placeholder: placeholder,
      label: label,
      errorText: errorText,
      disabled: disabled,
      prefixIcon: prefixIcon,
      searchable: searchable,
      width: width,
      height: height,
    );
  }
}
