import 'package:flutter/material.dart';
import '../resource/color_style.dart';

class AppSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool animate;

  const AppSkeleton({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.animate = true,
  }) : super(key: key);

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.ease,
      ),
    );

    if (widget.animate) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _buildSkeleton(0.3);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _buildSkeleton(0.3 + (_animation.value * 0.4));
      },
    );
  }

  Widget _buildSkeleton(double opacity) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColor.secondary04.withOpacity(opacity),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

// Text Skeleton
class AppTextSkeleton extends StatelessWidget {
  final double? width;
  final int lines;
  final double height;
  final double spacing;
  final bool animate;

  const AppTextSkeleton({
    Key? key,
    this.width,
    this.lines = 1,
    this.height = 14,
    this.spacing = 8,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLastLine = index == lines - 1;
        final lineWidth = isLastLine && lines > 1 
            ? (width ?? double.infinity) * 0.7 
            : width;
            
        return Container(
          margin: EdgeInsets.only(
            bottom: isLastLine ? 0 : spacing,
          ),
          child: AppSkeleton(
            width: lineWidth,
            height: height,
            borderRadius: BorderRadius.circular(4),
            animate: animate,
          ),
        );
      }),
    );
  }
}

// Circle Skeleton (for avatars)
class AppCircleSkeleton extends StatelessWidget {
  final double size;
  final bool animate;

  const AppCircleSkeleton({
    Key? key,
    required this.size,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      animate: animate,
    );
  }
}

// Card Skeleton
class AppCardSkeleton extends StatelessWidget {
  final bool showAvatar;
  final int titleLines;
  final int bodyLines;
  final bool showActions;
  final bool animate;

  const AppCardSkeleton({
    Key? key,
    this.showAvatar = true,
    this.titleLines = 1,
    this.bodyLines = 3,
    this.showActions = true,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and title
          if (showAvatar) ...[
            Row(
              children: [
                AppCircleSkeleton(
                  size: 40,
                  animate: animate,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextSkeleton(
                    lines: titleLines,
                    height: 16,
                    animate: animate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            AppTextSkeleton(
              lines: titleLines,
              height: 18,
              animate: animate,
            ),
            const SizedBox(height: 12),
          ],

          // Body content
          AppTextSkeleton(
            lines: bodyLines,
            height: 14,
            spacing: 6,
            animate: animate,
          ),

          // Actions
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                AppSkeleton(
                  width: 80,
                  height: 32,
                  borderRadius: BorderRadius.circular(6),
                  animate: animate,
                ),
                const SizedBox(width: 8),
                AppSkeleton(
                  width: 60,
                  height: 32,
                  borderRadius: BorderRadius.circular(6),
                  animate: animate,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// List Item Skeleton
class AppListItemSkeleton extends StatelessWidget {
  final bool showLeading;
  final bool showTrailing;
  final int titleLines;
  final int subtitleLines;
  final bool animate;

  const AppListItemSkeleton({
    Key? key,
    this.showLeading = true,
    this.showTrailing = false,
    this.titleLines = 1,
    this.subtitleLines = 1,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          // Leading (avatar or icon)
          if (showLeading) ...[
            AppCircleSkeleton(
              size: 48,
              animate: animate,
            ),
            const SizedBox(width: 16),
          ],

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextSkeleton(
                  lines: titleLines,
                  height: 16,
                  animate: animate,
                ),
                if (subtitleLines > 0) ...[
                  const SizedBox(height: 6),
                  AppTextSkeleton(
                    lines: subtitleLines,
                    height: 14,
                    width: double.infinity * 0.8,
                    animate: animate,
                  ),
                ],
              ],
            ),
          ),

          // Trailing
          if (showTrailing) ...[
            const SizedBox(width: 16),
            AppSkeleton(
              width: 24,
              height: 24,
              borderRadius: BorderRadius.circular(4),
              animate: animate,
            ),
          ],
        ],
      ),
    );
  }
}

// Table Skeleton
class AppTableSkeleton extends StatelessWidget {
  final int rows;
  final int columns;
  final bool showHeader;
  final bool animate;

  const AppTableSkeleton({
    Key? key,
    this.rows = 5,
    this.columns = 4,
    this.showHeader = true,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.border1),
      ),
      child: Column(
        children: [
          // Header
          if (showHeader)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColor.border1),
                ),
              ),
              child: Row(
                children: List.generate(columns, (index) => 
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < columns - 1 ? 16 : 0,
                      ),
                      child: AppSkeleton(
                        height: 16,
                        animate: animate,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Rows
          ...List.generate(rows, (rowIndex) =>
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: rowIndex < rows - 1 
                    ? Border(bottom: BorderSide(color: AppColor.border1))
                    : null,
              ),
              child: Row(
                children: List.generate(columns, (colIndex) => 
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: colIndex < columns - 1 ? 16 : 0,
                      ),
                      child: AppSkeleton(
                        height: 14,
                        animate: animate,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
