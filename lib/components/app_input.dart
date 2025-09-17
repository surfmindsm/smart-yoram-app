import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import '../resource/color_style.dart';

enum InputSize {
  sm,
  md,
  lg,
}

class AppInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final bool obscureText;
  final bool disabled;
  final bool readOnly;
  final bool required;
  final InputSize size;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const AppInput({
    Key? key,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.obscureText = false,
    this.disabled = false,
    this.readOnly = false,
    this.required = false,
    this.size = InputSize.md,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
  }) : super(key: key);

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizeTheme = _getSizeTheme(widget.size);
    final hasError = widget.errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColor.secondary07,
                ),
              ),
              if (widget.required)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColor.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        // Input Field
        Container(
          height: sizeTheme.height * (widget.maxLines ?? 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError 
                  ? AppColor.error
                  : _isFocused 
                      ? AppColor.primary7
                      : AppColor.border1,
              width: _isFocused ? 2 : 1,
            ),
            color: widget.disabled 
                ? AppColor.secondary00
                : AppColor.white,
          ),
          child: TextFormField(
            controller: widget.controller,
            initialValue: widget.initialValue,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            enabled: !widget.disabled,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            style: TextStyle(
              fontSize: sizeTheme.fontSize,
              color: widget.disabled 
                  ? AppColor.secondary04
                  : AppColor.secondary07,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                fontSize: sizeTheme.fontSize,
                color: AppColor.secondary04,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused 
                          ? AppColor.primary7
                          : AppColor.secondary04,
                      size: sizeTheme.iconSize,
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixIconTap,
                      child: Icon(
                        widget.suffixIcon,
                        color: _isFocused 
                            ? AppColor.primary7
                            : AppColor.secondary04,
                        size: sizeTheme.iconSize,
                      ),
                    )
                  : null,
              contentPadding: sizeTheme.padding,
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
        
        // Helper/Error Text
        if (widget.helperText != null || widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText ?? widget.helperText!,
            style: TextStyle(
              fontSize: 12,
              color: hasError 
                  ? AppColor.error
                  : AppColor.secondary04,
            ),
          ),
        ],
      ],
    );
  }

  _SizeTheme _getSizeTheme(InputSize size) {
    switch (size) {
      case InputSize.sm:
        return _SizeTheme(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fontSize: 12,
          iconSize: 16,
        );
      case InputSize.md:
        return _SizeTheme(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          fontSize: 14,
          iconSize: 18,
        );
      case InputSize.lg:
        return _SizeTheme(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          fontSize: 16,
          iconSize: 20,
        );
    }
  }
}

class _SizeTheme {
  final double height;
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;

  const _SizeTheme({
    required this.height,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
  });
}

// Search Input with built-in search functionality
class AppSearchInput extends StatelessWidget {
  final String? placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final InputSize size;

  const AppSearchInput({
    Key? key,
    this.placeholder = '검색...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.size = InputSize.md,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppInput(
      placeholder: placeholder,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      size: size,
      prefixIcon: Icons.search,
      suffixIcon: controller?.text.isNotEmpty == true 
          ? Icons.close
          : null,
      onSuffixIconTap: () {
        controller?.clear();
        onClear?.call();
      },
      keyboardType: TextInputType.text,
    );
  }
}

// Password Input with toggle visibility
class AppPasswordInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final bool required;
  final InputSize size;
  final ValueChanged<String>? onChanged;

  const AppPasswordInput({
    Key? key,
    this.label,
    this.placeholder = '비밀번호를 입력하세요',
    this.helperText,
    this.errorText,
    this.controller,
    this.required = false,
    this.size = InputSize.md,
    this.onChanged,
  }) : super(key: key);

  @override
  State<AppPasswordInput> createState() => _AppPasswordInputState();
}

class _AppPasswordInputState extends State<AppPasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: widget.label,
      placeholder: widget.placeholder,
      helperText: widget.helperText,
      errorText: widget.errorText,
      controller: widget.controller,
      required: widget.required,
      size: widget.size,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      prefixIcon: Icons.lock,
      suffixIcon: _obscureText 
          ? Icons.visibility_off
          : Icons.visibility,
      onSuffixIconTap: () {
        setState(() {
          _obscureText = !_obscureText;
        });
      },
      keyboardType: TextInputType.visiblePassword,
    );
  }
}
