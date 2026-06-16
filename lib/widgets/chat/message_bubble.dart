import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/chat_models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 메시지 말풍선 위젯
///
/// 내 메시지: 오른쪽 정렬, 파란색 배경
/// 상대방 메시지: 왼쪽 정렬, 회색 배경
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String? otherUserPhotoUrl;
  final bool showProfile; // 프로필 표시 여부 (연속 메시지일 때 false)
  final VoidCallback? onProfileTap; // 프로필 클릭 콜백

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.otherUserPhotoUrl,
    this.showProfile = true,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message.messageType == 'system') {
      return _buildSystemMessage();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 상대방 메시지: 프로필 + 말풍선 + 시간
          if (!isMe) ...[
            _buildProfileImage(),
            SizedBox(width: 8.w),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showProfile) _buildSenderName(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(child: _buildMessageBubble()),
                      SizedBox(width: 4.w),
                      _buildTimeText(),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // 내 메시지: 읽음 표시 + 시간 + 말풍선
          if (isMe) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (message.isRead)
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(
                      '읽음',
                      style: FigmaTextStyles().caption2.copyWith(
                            color: NewAppColor.neutral500,
                            fontSize: 10.sp,
                          ),
                    ),
                  ),
                _buildTimeText(),
              ],
            ),
            SizedBox(width: 4.w),
            Flexible(child: _buildMessageBubble()),
          ],
        ],
      ),
    );
  }

  /// 1.2.0 C 방향: 32px 라운드 이니셜 아바타 (skyTint + skyDeep)
  Widget _buildProfileImage() {
    if (!showProfile) {
      return SizedBox(width: 32.w); // 빈 공간 유지
    }

    final initial = message.senderName.isNotEmpty ? message.senderName[0] : '?';
    final profileWidget = Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: NewAppColor.skyTint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: otherUserPhotoUrl != null && otherUserPhotoUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: otherUserPhotoUrl!,
                width: 32.w,
                height: 32.w,
                fit: BoxFit.cover,
                placeholder: (_, __) => _initialText(initial),
                errorWidget: (_, __, ___) => _initialText(initial),
              ),
            )
          : _initialText(initial),
    );

    if (onProfileTap != null) {
      return GestureDetector(onTap: onProfileTap, child: profileWidget);
    }
    return profileWidget;
  }

  Widget _initialText(String initial) {
    return Text(
      initial,
      style: TextStyle(
        color: NewAppColor.skyDeep,
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        fontFamily: 'Pretendard',
      ),
    );
  }

  /// 발신자 이름
  Widget _buildSenderName() {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 3.h),
      child: Text(
        message.senderName,
        style: FigmaTextStyles().caption3.copyWith(
              color: NewAppColor.textTertiary,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  /// 1.2.0 C 방향: 비대칭 라운드 말풍선
  /// - 상대: 흰 배경 + 1px #EAEFF4 + 라운드 4/16/16/16
  /// - 나: skyPrimary 채움 + 흰 글자 + 라운드 16/16/4/16
  Widget _buildMessageBubble() {
    if (message.messageType == 'image') {
      return _buildImageMessage();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isMe ? NewAppColor.skyPrimary : Colors.white,
        border: isMe
            ? null
            : Border.all(color: const Color(0xFFEAEFF4), width: 1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMe ? 16.r : 4.r),
          topRight: Radius.circular(isMe ? 16.r : 16.r),
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(isMe ? 4.r : 16.r),
        ),
      ),
      child: Text(
        message.message,
        style: TextStyle(
          color: isMe ? Colors.white : NewAppColor.textBody,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          height: 1.5,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  /// 이미지 메시지
  Widget _buildImageMessage() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 220.w,
        maxHeight: 220.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMe ? 16.r : 4.r),
          topRight: Radius.circular(16.r),
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(isMe ? 4.r : 16.r),
        ),
        border: Border.all(
          color: isMe ? NewAppColor.skyPrimary : const Color(0xFFEAEFF4),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMe ? 16.r : 4.r),
          topRight: Radius.circular(16.r),
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(isMe ? 4.r : 16.r),
        ),
        child: CachedNetworkImage(
          imageUrl: message.imageUrl ?? '',
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 220.w,
            height: 220.h,
            color: NewAppColor.borderSoft,
            child: Center(
              child: CircularProgressIndicator(
                color: NewAppColor.skyPrimary,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 220.w,
            height: 220.h,
            color: NewAppColor.borderSoft,
            child: Icon(
              LucideIcons.imageOff,
              color: NewAppColor.iconFaint,
              size: 40.sp,
            ),
          ),
        ),
      ),
    );
  }

  /// 시간 텍스트 — 10.5sp #B6C0CC
  Widget _buildTimeText() {
    return Text(
      message.formattedTime,
      style: TextStyle(
        color: const Color(0xFFB6C0CC),
        fontSize: 10.5.sp,
        fontWeight: FontWeight.w500,
        fontFamily: 'Pretendard',
      ),
    );
  }

  /// 시스템 메시지 (날짜 칩 등): borderStrong + textMuted 라운드 999
  Widget _buildSystemMessage() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: NewAppColor.borderStrong,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          message.message,
          style: FigmaTextStyles().caption3.copyWith(
                color: NewAppColor.textMuted,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
