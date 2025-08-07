import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum ProgressSize {
  sm,
  md,
  lg,
}

enum ProgressVariant {
  primary,
  secondary,
  success,
  warning,
  error,
}

class AppProgress extends StatelessWidget {
  final double value;
  final ProgressSize size;
  final ProgressVariant variant;
  final String? label;
  final String? description;
  final bool showPercentage;
  final String Function(double)? valueFormatter;
  final double? width;

  const AppProgress({
    Key? key,
    required this.value,
    this.size = ProgressSize.md,
    this.variant = ProgressVariant.primary,
    this.label,
    this.description,
    this.showPercentage = false,
    this.valueFormatter,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sizeConfig = _getSizeConfig(size);
    final colorConfig = _getColorConfig(variant);
    final clampedValue = value.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: TextStyle(
                  fontSize: sizeConfig.fontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColor.secondary06,
                ),
              ),
              if (showPercentage)
                Text(
                  valueFormatter?.call(clampedValue) ?? 
                    '${(clampedValue * 100).round()}%',
                  style: TextStyle(
                    fontSize: sizeConfig.fontSize - 2,
                    color: AppColor.secondary04,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Container(
          width: width ?? double.infinity,
          height: sizeConfig.height,
          decoration: BoxDecoration(
            color: colorConfig.background,
            borderRadius: BorderRadius.circular(sizeConfig.height / 2),
          ),
          child: Stack(
            children: [
              Container(
                width: width != null 
                  ? (width! * clampedValue) 
                  : double.infinity,
                height: sizeConfig.height,
                decoration: BoxDecoration(
                  color: colorConfig.foreground,
                  borderRadius: BorderRadius.circular(sizeConfig.height / 2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clampedValue,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorConfig.foreground,
                      borderRadius: BorderRadius.circular(sizeConfig.height / 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              fontSize: sizeConfig.fontSize - 2,
              color: AppColor.secondary04,
            ),
          ),
        ],
      ],
    );
  }

  _ProgressSizeConfig _getSizeConfig(ProgressSize size) {
    switch (size) {
      case ProgressSize.sm:
        return const _ProgressSizeConfig(
          height: 6,
          fontSize: 12,
        );
      case ProgressSize.md:
        return const _ProgressSizeConfig(
          height: 8,
          fontSize: 14,
        );
      case ProgressSize.lg:
        return const _ProgressSizeConfig(
          height: 12,
          fontSize: 16,
        );
    }
  }

  _ProgressColorConfig _getColorConfig(ProgressVariant variant) {
    switch (variant) {
      case ProgressVariant.primary:
        return const _ProgressColorConfig(
          foreground: AppColor.primary600,
          background: AppColor.secondary01,
        );
      case ProgressVariant.secondary:
        return const _ProgressColorConfig(
          foreground: AppColor.secondary04,
          background: AppColor.secondary01,
        );
      case ProgressVariant.success:
        return const _ProgressColorConfig(
          foreground: Color(0xff10b981),
          background: AppColor.secondary01,
        );
      case ProgressVariant.warning:
        return const _ProgressColorConfig(
          foreground: AppColor.orange500,
          background: AppColor.secondary01,
        );
      case ProgressVariant.error:
        return const _ProgressColorConfig(
          foreground: AppColor.error,
          background: AppColor.secondary01,
        );
    }
  }

  // Named constructors for common use cases
  static AppProgress percentage({
    Key? key,
    required double percentage,
    ProgressSize size = ProgressSize.md,
    ProgressVariant variant = ProgressVariant.primary,
    String? label,
    String? description,
    bool showPercentage = true,
    double? width,
  }) {
    return AppProgress(
      key: key,
      value: percentage / 100,
      size: size,
      variant: variant,
      label: label,
      description: description,
      showPercentage: showPercentage,
      width: width,
    );
  }

  static AppProgress withSteps({
    Key? key,
    required int current,
    required int total,
    ProgressSize size = ProgressSize.md,
    ProgressVariant variant = ProgressVariant.primary,
    String? label,
    String? description,
    double? width,
  }) {
    return AppProgress(
      key: key,
      value: total > 0 ? current / total : 0,
      size: size,
      variant: variant,
      label: label,
      description: description,
      showPercentage: true,
      valueFormatter: (value) => '${(value * total).round()}/$total',
      width: width,
    );
  }
}

class AppCircularProgress extends StatelessWidget {
  final double value;
  final double size;
  final ProgressVariant variant;
  final String? label;
  final bool showPercentage;
  final String Function(double)? valueFormatter;
  final double strokeWidth;

  const AppCircularProgress({
    Key? key,
    required this.value,
    this.size = 64,
    this.variant = ProgressVariant.primary,
    this.label,
    this.showPercentage = false,
    this.valueFormatter,
    this.strokeWidth = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorConfig = _getColorConfig(variant);
    final clampedValue = value.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Background circle
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorConfig.background,
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: clampedValue,
                  strokeWidth: strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorConfig.foreground,
                  ),
                ),
              ),
              // Center text
              if (showPercentage)
                Center(
                  child: Text(
                    valueFormatter?.call(clampedValue) ?? 
                      '${(clampedValue * 100).round()}%',
                    style: TextStyle(
                      fontSize: size * 0.15,
                      fontWeight: FontWeight.w600,
                      color: AppColor.secondary06,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColor.secondary04,
            ),
          ),
        ],
      ],
    );
  }

  _ProgressColorConfig _getColorConfig(ProgressVariant variant) {
    switch (variant) {
      case ProgressVariant.primary:
        return const _ProgressColorConfig(
          foreground: AppColor.primary600,
          background: AppColor.secondary01,
        );
      case ProgressVariant.secondary:
        return const _ProgressColorConfig(
          foreground: AppColor.secondary04,
          background: AppColor.secondary01,
        );
      case ProgressVariant.success:
        return const _ProgressColorConfig(
          foreground: Color(0xff10b981),
          background: AppColor.secondary01,
        );
      case ProgressVariant.warning:
        return const _ProgressColorConfig(
          foreground: AppColor.orange500,
          background: AppColor.secondary01,
        );
      case ProgressVariant.error:
        return const _ProgressColorConfig(
          foreground: AppColor.error,
          background: AppColor.secondary01,
        );
    }
  }

  // Named constructors for common use cases
  static AppCircularProgress percentage({
    Key? key,
    required double percentage,
    double size = 64,
    ProgressVariant variant = ProgressVariant.primary,
    String? label,
    bool showPercentage = true,
    double strokeWidth = 6,
  }) {
    return AppCircularProgress(
      key: key,
      value: percentage / 100,
      size: size,
      variant: variant,
      label: label,
      showPercentage: showPercentage,
      strokeWidth: strokeWidth,
    );
  }
}

class _ProgressSizeConfig {
  final double height;
  final double fontSize;

  const _ProgressSizeConfig({
    required this.height,
    required this.fontSize,
  });
}

class _ProgressColorConfig {
  final Color foreground;
  final Color background;

  const _ProgressColorConfig({
    required this.foreground,
    required this.background,
  });
}
