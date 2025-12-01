import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/chat_models.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 메시지 말풍선 위젯
///
/// 내 메시지: 오른쪽 정렬, 파란색 배경
/// 상대방 메시지: 왼쪽 정렬, 회색 배경
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String? otherUserPhotoUrl;
  final bool showProfile; // 프로필 표시 여부 (연속 메시지일 때 false)

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.otherUserPhotoUrl,
    this.showProfile = true,
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

  /// 프로필 이미지
  Widget _buildProfileImage() {
    if (!showProfile) {
      return SizedBox(width: 40.w); // 빈 공간 유지
    }

    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: NewAppColor.neutral200,
        shape: BoxShape.circle,
      ),
      child: otherUserPhotoUrl != null && otherUserPhotoUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: otherUserPhotoUrl!,
                width: 40.w,
                height: 40.w,
                fit: BoxFit.cover,
                placeholder: (context, url) => Icon(
                  Icons.person,
                  color: NewAppColor.neutral500,
                  size: 20.sp,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  color: NewAppColor.neutral500,
                  size: 20.sp,
                ),
              ),
            )
          : Icon(
              Icons.person,
              color: NewAppColor.neutral500,
              size: 20.sp,
            ),
    );
  }

  /// 발신자 이름
  Widget _buildSenderName() {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
      child: Text(
        message.senderName,
        style: FigmaTextStyles().caption1.copyWith(
              color: NewAppColor.neutral600,
              fontSize: 12.sp,
            ),
      ),
    );
  }

  /// 메시지 말풍선
  Widget _buildMessageBubble() {
    if (message.messageType == 'image') {
      return _buildImageMessage();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isMe ? NewAppColor.primary600 : NewAppColor.neutral100,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMe ? 16.r : 4.r),
          topRight: Radius.circular(isMe ? 4.r : 16.r),
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Text(
        message.message,
        style: FigmaTextStyles().body2.copyWith(
              color: isMe ? Colors.white : NewAppColor.neutral900,
              fontSize: 15.sp,
              height: 1.4,
            ),
      ),
    );
  }

  /// 이미지 메시지
  Widget _buildImageMessage() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 200.w,
        maxHeight: 200.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isMe ? NewAppColor.primary600 : NewAppColor.neutral200,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: CachedNetworkImage(
          imageUrl: message.imageUrl ?? '',
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 200.w,
            height: 200.h,
            color: NewAppColor.neutral100,
            child: Center(
              child: CircularProgressIndicator(
                color: isMe ? NewAppColor.primary600 : NewAppColor.neutral400,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200.w,
            height: 200.h,
            color: NewAppColor.neutral100,
            child: Icon(
              Icons.broken_image,
              color: NewAppColor.neutral400,
              size: 48.sp,
            ),
          ),
        ),
      ),
    );
  }

  /// 시간 텍스트
  Widget _buildTimeText() {
    return Text(
      message.formattedTime,
      style: FigmaTextStyles().caption2.copyWith(
            color: NewAppColor.neutral500,
            fontSize: 11.sp,
          ),
    );
  }

  /// 시스템 메시지 (예: "채팅방이 생성되었습니다")
  Widget _buildSystemMessage() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: NewAppColor.neutral200,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          message.message,
          style: FigmaTextStyles().caption2.copyWith(
                color: NewAppColor.neutral600,
                fontSize: 12.sp,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
