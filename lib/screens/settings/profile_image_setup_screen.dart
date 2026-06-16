import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/member.dart';
import '../../services/member_service.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../components/app_toast.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 커뮤니티 프로필 이미지 설정 화면
class ProfileImageSetupScreen extends StatefulWidget {
  final Member member;
  final bool isFirstSetup; // 첫 로그인 여부

  const ProfileImageSetupScreen({
    super.key,
    required this.member,
    this.isFirstSetup = false,
  });

  @override
  State<ProfileImageSetupScreen> createState() => _ProfileImageSetupScreenState();
}

class _ProfileImageSetupScreenState extends State<ProfileImageSetupScreen> {
  final MemberService _memberService = MemberService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  File? _selectedImage;
  late String _selectedOption; // 'existing' or 'new'

  @override
  void initState() {
    super.initState();
    // 교회 이미지가 있으면 'existing', 없으면(커뮤니티 회원) 'new'를 기본값으로
    _selectedOption = widget.member.fullProfilePhotoUrl != null ? 'existing' : 'new';
  }

  @override
  // 1.2.0 C 방향: 큰 제목 + 안내문 + 가로 2분할 옵션(기존/새 사진) + 카메라/갤러리 분리
  Widget build(BuildContext context) {
    final hasExistingPhoto = widget.member.fullProfilePhotoUrl != null;

    return PopScope(
      canPop: !widget.isFirstSetup,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.isFirstSetup) {
          AppToast.show(context, '건너뛰기 또는 완료 버튼을 눌러주세요');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleSpacing: 0,
          leading: widget.isFirstSetup
              ? null
              : IconButton(
                  icon: Icon(LucideIcons.chevronLeft,
                      color: NewAppColor.textStrong, size: 24.sp),
                  onPressed: () => Navigator.pop(context),
                ),
          title: Text(
            '프로필 이미지',
            style: FigmaTextStyles().subtitle1.copyWith(
                  color: NewAppColor.textStrong,
                  fontSize: 17.sp,
                ),
          ),
          shape: Border(
            bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(26.w, 30.h, 26.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 큰 제목
                      Text(
                        '프로필 사진을 선택해주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: NewAppColor.textStrong,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Pretendard',
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // 안내문
                      Text(
                        hasExistingPhoto
                            ? '교회에 등록된 기존 사진을 쓰거나,\n새 사진을 등록할 수 있어요.'
                            : '새 사진을 등록해 커뮤니티에서\n사용할 프로필을 설정해보세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: NewAppColor.textMuted,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 28.h),

                      // 가로 2분할 옵션
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasExistingPhoto) ...[
                            _buildAvatarOption(
                              kind: _AvatarOptionKind.existing,
                              isSelected: _selectedOption == 'existing',
                              onTap: () {
                                setState(() {
                                  _selectedOption = 'existing';
                                  _selectedImage = null;
                                });
                              },
                            ),
                            SizedBox(width: 26.w),
                          ],
                          _buildAvatarOption(
                            kind: _AvatarOptionKind.newPhoto,
                            isSelected: _selectedOption == 'new',
                            onTap: () {
                              setState(() {
                                _selectedOption = 'new';
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 28.h),

                      // 새 사진 등록 — 카메라/갤러리 분리 (선택된 옵션이 새 사진일 때만 표시)
                      if (_selectedOption == 'new' || !hasExistingPhoto) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Container(height: 1, color: NewAppColor.borderSoft),
                            ),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 12.w),
                              child: Text(
                                '새 사진 등록',
                                style: TextStyle(
                                  color: NewAppColor.textTertiary,
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(height: 1, color: NewAppColor.borderSoft),
                            ),
                          ],
                        ),
                        SizedBox(height: 13.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSourceButton(
                                icon: LucideIcons.camera,
                                label: '카메라',
                                onTap: () => _pickImageFrom(ImageSource.camera),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildSourceButton(
                                icon: LucideIcons.image,
                                label: '갤러리',
                                onTap: () => _pickImageFrom(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 하단 버튼
              Padding(
                padding: EdgeInsets.fromLTRB(26.w, 0, 26.w, 22.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isFirstSetup) ...[
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isLoading ? null : _skipProfileSetup,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: Text(
                            '건너뛰기',
                            style: TextStyle(
                              color: NewAppColor.textTertiary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                    ],
                    // 저장 버튼 — skyPrimary + 섀도
                    Material(
                      color: NewAppColor.skyPrimary,
                      borderRadius: BorderRadius.circular(14.r),
                      child: InkWell(
                        onTap: _isLoading ? null : _saveProfileImage,
                        borderRadius: BorderRadius.circular(14.r),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14.r),
                            boxShadow: [
                              BoxShadow(
                                color: NewAppColor.skyPrimary.withOpacity(0.32),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.isFirstSetup ? '완료' : '저장',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Pretendard',
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1.2.0: 가로 2분할 아바타 옵션 (기존 사진 / 새 사진)
  Widget _buildAvatarOption({
    required _AvatarOptionKind kind,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isExisting = kind == _AvatarOptionKind.existing;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: 118.w,
            height: 118.w,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 메인 원형
                Container(
                  width: 118.w,
                  height: 118.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF8FAFC),
                    border: isExisting
                        ? Border.all(
                            color: isSelected
                                ? NewAppColor.skyPrimary
                                : NewAppColor.borderStrong,
                            width: isSelected ? 3 : 1.5,
                          )
                        : Border.all(
                            color: isSelected
                                ? NewAppColor.skyPrimary
                                : NewAppColor.iconFaint,
                            width: 2,
                            style: isSelected
                                ? BorderStyle.solid
                                : BorderStyle.solid,
                          ),
                    boxShadow: isExisting && isSelected
                        ? [
                            BoxShadow(
                              color: NewAppColor.skyPrimary.withOpacity(0.15),
                              blurRadius: 0,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildAvatarContent(kind),
                ),
                // 우측 하단 체크 배지 (기존 사진 선택 시)
                if (isExisting && isSelected)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NewAppColor.skyPrimary,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: NewAppColor.skyPrimary.withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child:
                          Icon(LucideIcons.check, color: Colors.white, size: 17.sp),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 13.h),
          Text(
            isExisting ? '기존 사진' : '새 사진',
            style: TextStyle(
              color: NewAppColor.textStrong,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            isExisting ? '교회 등록 사진' : '직접 등록',
            style: TextStyle(
              color: isExisting && isSelected
                  ? NewAppColor.skyDeep
                  : NewAppColor.textTertiary,
              fontSize: 11.5.sp,
              fontWeight:
                  isExisting && isSelected ? FontWeight.w600 : FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  // 아바타 안 콘텐츠 — 기존 사진은 네트워크 이미지, 새 사진은 선택한 파일 또는 plus
  Widget _buildAvatarContent(_AvatarOptionKind kind) {
    if (kind == _AvatarOptionKind.existing) {
      final url = widget.member.fullProfilePhotoUrl;
      if (url == null || url.isEmpty) {
        return Icon(LucideIcons.user, size: 52.sp, color: NewAppColor.iconFaint);
      }
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Center(
          child: SizedBox(
            width: 22.w,
            height: 22.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: NewAppColor.skyPrimary,
            ),
          ),
        ),
        errorWidget: (_, __, ___) =>
            Icon(LucideIcons.user, size: 52.sp, color: NewAppColor.iconFaint),
      );
    }
    // 새 사진
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.plus, size: 30.sp, color: NewAppColor.textTertiary),
        SizedBox(height: 4.h),
        Text(
          '추가',
          style: TextStyle(
            color: NewAppColor.textTertiary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  // 1.2.0: 카메라/갤러리 소스 선택 버튼 (라운드 16 + 라인 + skyDeep 아이콘)
  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: NewAppColor.borderStrong, width: 1),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: NewAppColor.skyDeep, size: 23.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                color: NewAppColor.textSecondary,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1.2.0: 카메라/갤러리 통합 — source 매개변수로 분기
  Future<void> _pickImageFrom(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedOption = 'new'; // 새 사진 옵션으로 자동 전환
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '이미지 선택 실패: ${e.toString()}');
      }
    }
  }

  /// 건너뛰기 처리 - 기본 이미지 사용
  Future<void> _skipProfileSetup() async {
    if (mounted) {
      AppToast.show(context, '기본 프로필 이미지를 사용합니다');
      Navigator.pop(context, true);
    }
  }

  Future<void> _saveProfileImage() async {
    setState(() => _isLoading = true);

    try {
      if (_selectedOption == 'existing') {
        if (widget.member.fullProfilePhotoUrl == null) {
          if (mounted) {
            AppToast.error(context, '교회에서 등록한 이미지가 없습니다');
            setState(() => _isLoading = false);
          }
          return;
        }

        final response = await _memberService
            .setMobileProfileImageToExisting(widget.member.id);

        if (mounted) {
          if (response.success) {
            AppToast.success(context, '기존 프로필 이미지를 사용합니다');
            Navigator.pop(context, true);
          } else {
            AppToast.error(context, response.message);
          }
        }
      } else if (_selectedOption == 'new') {
        if (_selectedImage == null) {
          if (mounted) {
            AppToast.warning(context, '이미지를 선택해주세요');
            setState(() => _isLoading = false);
          }
          return;
        }

        final response = await _memberService.uploadMobileProfileImage(
          memberId: widget.member.id,
          imageFile: _selectedImage!,
        );

        if (mounted) {
          if (response.success) {
            AppToast.success(context, '프로필 이미지가 업데이트되었습니다');
            Navigator.pop(context, true);
          } else {
            AppToast.error(context, response.message);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '오류가 발생했습니다: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// 1.2.0: 옵션 종류 식별자
enum _AvatarOptionKind { existing, newPhoto }
