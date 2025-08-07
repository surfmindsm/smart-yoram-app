import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum AvatarSize {
  xs,
  sm,
  md,
  lg,
  xl,
}

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final AvatarSize size;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final Widget? fallback;

  const AppAvatar({
    Key? key,
    this.imageUrl,
    this.initials,
    this.size = AvatarSize.md,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sizeConfig = _getSizeConfig(size);
    
    Widget avatarWidget = Container(
      width: sizeConfig.size,
      height: sizeConfig.size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColor.primary100,
        borderRadius: BorderRadius.circular(sizeConfig.size / 2),
        border: Border.all(
          color: AppColor.border1,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(sizeConfig.size / 2),
        child: _buildContent(sizeConfig),
      ),
    );

    if (onTap != null) {
      avatarWidget = GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildContent(_SizeConfig sizeConfig) {
    // Try to show image first
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackContent(sizeConfig);
        },
      );
    }
    
    return _buildFallbackContent(sizeConfig);
  }

  Widget _buildFallbackContent(_SizeConfig sizeConfig) {
    // Show custom fallback if provided
    if (fallback != null) {
      return fallback!;
    }
    
    // Show initials if provided
    if (initials != null && initials!.isNotEmpty) {
      return Center(
        child: Text(
          initials!.toUpperCase(),
          style: TextStyle(
            fontSize: sizeConfig.fontSize,
            fontWeight: FontWeight.w600,
            color: textColor ?? AppColor.primary7,
          ),
        ),
      );
    }
    
    // Show default user icon
    return Icon(
      Icons.person,
      size: sizeConfig.iconSize,
      color: textColor ?? AppColor.primary7,
    );
  }

  _SizeConfig _getSizeConfig(AvatarSize size) {
    switch (size) {
      case AvatarSize.xs:
        return _SizeConfig(
          size: 24,
          fontSize: 10,
          iconSize: 14,
        );
      case AvatarSize.sm:
        return _SizeConfig(
          size: 32,
          fontSize: 12,
          iconSize: 18,
        );
      case AvatarSize.md:
        return _SizeConfig(
          size: 40,
          fontSize: 14,
          iconSize: 22,
        );
      case AvatarSize.lg:
        return _SizeConfig(
          size: 56,
          fontSize: 18,
          iconSize: 32,
        );
      case AvatarSize.xl:
        return _SizeConfig(
          size: 80,
          fontSize: 24,
          iconSize: 44,
        );
    }
  }
}

class _SizeConfig {
  final double size;
  final double fontSize;
  final double iconSize;

  const _SizeConfig({
    required this.size,
    required this.fontSize,
    required this.iconSize,
  });
}

// Avatar Group for showing multiple avatars
class AppAvatarGroup extends StatelessWidget {
  final List<AppAvatar> avatars;
  final int maxVisible;
  final AvatarSize size;
  final double spacing;

  const AppAvatarGroup({
    Key? key,
    required this.avatars,
    this.maxVisible = 3,
    this.size = AvatarSize.md,
    this.spacing = -8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visibleAvatars = avatars.take(maxVisible).toList();
    final remainingCount = avatars.length - maxVisible;
    
    return Stack(
      children: [
        // Visible avatars
        ...visibleAvatars.asMap().entries.map((entry) {
          final index = entry.key;
          final avatar = entry.value;
          
          return Positioned(
            left: index * (_getSizeForEnum(size) + spacing),
            child: AppAvatar(
              imageUrl: avatar.imageUrl,
              initials: avatar.initials,
              size: size,
              backgroundColor: avatar.backgroundColor,
              textColor: avatar.textColor,
              onTap: avatar.onTap,
              fallback: avatar.fallback,
            ),
          );
        }).toList(),
        
        // Show remaining count if there are more
        if (remainingCount > 0)
          Positioned(
            left: maxVisible * (_getSizeForEnum(size) + spacing),
            child: AppAvatar(
              initials: '+$remainingCount',
              size: size,
              backgroundColor: AppColor.secondary00,
              textColor: AppColor.secondary06,
            ),
          ),
      ],
    );
  }

  double _getSizeForEnum(AvatarSize size) {
    switch (size) {
      case AvatarSize.xs: return 24;
      case AvatarSize.sm: return 32;
      case AvatarSize.md: return 40;
      case AvatarSize.lg: return 56;
      case AvatarSize.xl: return 80;
    }
  }
}

// Profile Avatar with status indicator
class AppProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final AvatarSize size;
  final bool showOnlineStatus;
  final bool isOnline;
  final VoidCallback? onTap;

  const AppProfileAvatar({
    Key? key,
    this.imageUrl,
    this.initials,
    this.size = AvatarSize.md,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sizeConfig = _getSizeForEnum(size);
    final statusSize = sizeConfig * 0.25;
    
    return Stack(
      children: [
        AppAvatar(
          imageUrl: imageUrl,
          initials: initials,
          size: size,
          onTap: onTap,
        ),
        
        // Online status indicator
        if (showOnlineStatus)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: statusSize,
              height: statusSize,
              decoration: BoxDecoration(
                color: isOnline 
                    ? const Color(0xff22C55E) 
                    : AppColor.secondary04,
                borderRadius: BorderRadius.circular(statusSize / 2),
                border: Border.all(
                  color: AppColor.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _getSizeForEnum(AvatarSize size) {
    switch (size) {
      case AvatarSize.xs: return 24;
      case AvatarSize.sm: return 32;
      case AvatarSize.md: return 40;
      case AvatarSize.lg: return 56;
      case AvatarSize.xl: return 80;
    }
  }
}
