import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/member.dart';
import '../../services/member_service.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';

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
  String _selectedOption = 'existing'; // 'existing' or 'new'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.isFirstSetup
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back, color: NewAppColor.neutral900),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          '커뮤니티 프로필 이미지',
          style: FigmaTextStyles().header2.copyWith(
                color: NewAppColor.neutral900,
              ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 안내 메시지
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: NewAppColor.primary100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '커뮤니티에서 사용할 프로필 이미지를 선택해주세요',
                            style: FigmaTextStyles().body1.copyWith(
                                  color: NewAppColor.neutral900,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '주소록에서는 교회에서 등록한 이미지를 사용합니다.\n언제든 설정 > 프로필 이미지에서 변경할 수 있습니다.',
                            style: FigmaTextStyles().body2.copyWith(
                                  color: NewAppColor.neutral600,
                                ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // 옵션 1: 기존 교회 이미지 사용
                    _buildOptionCard(
                      title: '기존 교회 이미지 사용',
                      description: '교회에서 등록한 프로필 이미지를 사용합니다',
                      isSelected: _selectedOption == 'existing',
                      onTap: () {
                        setState(() {
                          _selectedOption = 'existing';
                          _selectedImage = null;
                        });
                      },
                      child: widget.member.fullProfilePhotoUrl != null
                          ? Center(
                              child: Container(
                                width: 120.w,
                                height: 120.w,
                                margin: EdgeInsets.only(top: 16.h),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: NewAppColor.neutral200,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: widget.member.fullProfilePhotoUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.person,
                                      size: 60.w,
                                      color: NewAppColor.neutral400,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: Text(
                                  '등록된 교회 이미지가 없습니다',
                                  style: FigmaTextStyles().body2.copyWith(
                                        color: NewAppColor.neutral400,
                                      ),
                                ),
                              ),
                            ),
                    ),

                    SizedBox(height: 16.h),

                    // 옵션 2: 새 이미지 업로드
                    _buildOptionCard(
                      title: '새 이미지 업로드',
                      description: '커뮤니티 전용 프로필 이미지를 업로드합니다',
                      isSelected: _selectedOption == 'new',
                      onTap: () {
                        setState(() {
                          _selectedOption = 'new';
                        });
                      },
                      child: Column(
                        children: [
                          SizedBox(height: 16.h),
                          if (_selectedImage != null)
                            Container(
                              width: 120.w,
                              height: 120.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: NewAppColor.primary500,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 120.w,
                              height: 120.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: NewAppColor.neutral100,
                                border: Border.all(
                                  color: NewAppColor.neutral300,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.add_a_photo,
                                size: 40.w,
                                color: NewAppColor.neutral400,
                              ),
                            ),
                          SizedBox(height: 16.h),
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('이미지 선택'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: NewAppColor.primary500,
                              side: BorderSide(color: NewAppColor.primary500),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
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

            // 하단 버튼
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfileImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NewAppColor.primary500,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
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
                            style: FigmaTextStyles().button1.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.primary100 : Colors.white,
          border: Border.all(
            color: isSelected ? NewAppColor.primary500 : NewAppColor.neutral200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? NewAppColor.primary500
                      : NewAppColor.neutral400,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: FigmaTextStyles().body1.copyWith(
                              color: NewAppColor.neutral900,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        style: FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveProfileImage() async {
    setState(() => _isLoading = true);

    try {
      if (_selectedOption == 'existing') {
        // 기존 교회 이미지 사용
        final response = await _memberService.setMobileProfileImageToExisting(
          widget.member.id,
        );

        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('기존 프로필 이미지를 사용합니다')),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message)),
            );
          }
        }
      } else if (_selectedOption == 'new') {
        // 새 이미지 업로드
        if (_selectedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지를 선택해주세요')),
          );
          return;
        }

        final response = await _memberService.uploadMobileProfileImage(
          memberId: widget.member.id,
          imageFile: _selectedImage!,
        );

        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('프로필 이미지가 업데이트되었습니다')),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message)),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
