import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/community_models.dart';
import 'package:smart_yoram_app/services/community_service.dart';
import 'package:smart_yoram_app/screens/community/community_list_screen.dart';
import 'package:image_picker/image_picker.dart';

/// 커뮤니티 게시글 작성/수정 화면 (공통)
class CommunityCreateScreen extends StatefulWidget {
  final CommunityListType type;
  final String categoryTitle;
  final dynamic existingPost; // 수정 시 기존 게시글

  const CommunityCreateScreen({
    super.key,
    required this.type,
    required this.categoryTitle,
    this.existingPost,
  });

  @override
  State<CommunityCreateScreen> createState() => _CommunityCreateScreenState();
}

class _CommunityCreateScreenState extends State<CommunityCreateScreen> {
  final CommunityService _communityService = CommunityService();
  final _formKey = GlobalKey<FormState>();

  // 공통 필드
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();

  // 타입별 필드
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _priceRangeController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  bool _isLoading = false;
  List<XFile> _selectedImages = [];
  String _selectedStatus = 'active';
  bool _isFree = false; // 무료나눔 여부

  @override
  void initState() {
    super.initState();
    if (widget.existingPost != null) {
      _loadExistingPost();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _priceController.dispose();
    _priceRangeController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _loadExistingPost() {
    // TODO: 기존 게시글 데이터 로드
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingPost == null ? '글쓰기' : '수정하기',
          style: FigmaTextStyles().headline4.copyWith(
                color: NewAppColor.neutral900,
              ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: Text(
              '완료',
              style: FigmaTextStyles().button2.copyWith(
                    color: _isLoading
                        ? NewAppColor.neutral400
                        : NewAppColor.primary600,
                  ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: NewAppColor.neutral200,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildCommonFields(),
                    _buildTypeSpecificFields(),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCommonFields() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: '제목을 입력하세요',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.primary600),
              ),
            ),
            style: FigmaTextStyles().body2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '제목을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          // 내용
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: '내용을 입력하세요',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.primary600),
              ),
            ),
            style: FigmaTextStyles().body2,
            maxLines: 8,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '내용을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          // 이미지 선택
          if (_shouldShowImagePicker()) ...[
            _buildImagePicker(),
            SizedBox(height: 16.h),
          ],
          // 지역
          if (_shouldShowLocation()) ...[
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: '지역',
                hintText: '지역을 입력하세요',
                hintStyle: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral400,
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: NewAppColor.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: NewAppColor.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: NewAppColor.primary600),
                ),
              ),
              style: FigmaTextStyles().body2,
            ),
            SizedBox(height: 16.h),
          ],
          // 연락처
          TextFormField(
            controller: _contactPhoneController,
            decoration: InputDecoration(
              labelText: '연락처',
              hintText: '연락처를 입력하세요',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.primary600),
              ),
            ),
            style: FigmaTextStyles().body2,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '연락처를 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          // 이메일 (선택)
          TextFormField(
            controller: _contactEmailController,
            decoration: InputDecoration(
              labelText: '이메일 (선택)',
              hintText: '이메일을 입력하세요',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.primary600),
              ),
            ),
            style: FigmaTextStyles().body2,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (widget.type) {
      case CommunityListType.freeSharing:
        return _buildSharingFields(isFree: true);
      case CommunityListType.itemSale:
        return _buildSharingFields(isFree: false);
      case CommunityListType.itemRequest:
        return _buildRequestFields();
      case CommunityListType.jobPosting:
        return _buildJobPostingFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSharingFields({required bool isFree}) {
    _isFree = isFree;
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFree ? '무료 나눔 정보' : '판매 정보',
            style: FigmaTextStyles().subtitle2.copyWith(
                  color: NewAppColor.neutral900,
                ),
          ),
          SizedBox(height: 16.h),
          if (!isFree) ...[
            // 가격
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: '가격',
                hintText: '가격을 입력하세요 (0: 가격협의)',
                hintStyle: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral400,
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: NewAppColor.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: NewAppColor.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: NewAppColor.primary600),
                ),
                suffixText: '원',
              ),
              style: FigmaTextStyles().body2,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.h),
          ],
          // 배송 방법
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: '거래 방법',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.primary600),
              ),
            ),
            items: const [
              DropdownMenuItem(value: '직거래', child: Text('직거래')),
              DropdownMenuItem(value: '택배', child: Text('택배')),
              DropdownMenuItem(value: '직거래/택배', child: Text('직거래/택배')),
            ],
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildRequestFields() {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '요청 정보',
            style: FigmaTextStyles().subtitle2.copyWith(
                  color: NewAppColor.neutral900,
                ),
          ),
          SizedBox(height: 16.h),
          // 희망 가격대
          TextFormField(
            controller: _priceRangeController,
            decoration: InputDecoration(
              labelText: '희망 가격대 (선택)',
              hintText: '예: 10,000원 ~ 20,000원',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.primary600),
              ),
            ),
            style: FigmaTextStyles().body2,
          ),
          SizedBox(height: 16.h),
          // 긴급도
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: '긴급도',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.primary600),
              ),
            ),
            value: 'normal',
            items: const [
              DropdownMenuItem(value: 'low', child: Text('낮음')),
              DropdownMenuItem(value: 'normal', child: Text('보통')),
              DropdownMenuItem(value: 'high', child: Text('높음')),
              DropdownMenuItem(value: 'urgent', child: Text('긴급')),
            ],
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildJobPostingFields() {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '구인 정보',
            style: FigmaTextStyles().subtitle2.copyWith(
                  color: NewAppColor.neutral900,
                ),
          ),
          SizedBox(height: 16.h),
          // 급여
          TextFormField(
            controller: _salaryController,
            decoration: InputDecoration(
              labelText: '급여 (선택)',
              hintText: '예: 월 250만원',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.primary600),
              ),
            ),
            style: FigmaTextStyles().body2,
          ),
          SizedBox(height: 16.h),
          // 직무 유형
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: '직무 유형',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.primary600),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'pastor', child: Text('목회자')),
              DropdownMenuItem(value: 'worship', child: Text('예배 사역')),
              DropdownMenuItem(value: 'education', child: Text('교육 사역')),
              DropdownMenuItem(value: 'admin', child: Text('행정')),
              DropdownMenuItem(value: 'other', child: Text('기타')),
            ],
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '사진',
              style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral700,
                  ),
            ),
            SizedBox(width: 4.w),
            Text(
              '(최대 5장)',
              style: FigmaTextStyles().caption3.copyWith(
                    color: NewAppColor.neutral400,
                  ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 80.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 사진 추가 버튼
              InkWell(
                onTap: _pickImages,
                child: Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: NewAppColor.neutral100,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: NewAppColor.neutral200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 24.sp,
                        color: NewAppColor.neutral500,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${_selectedImages.length}/5',
                        style: FigmaTextStyles().caption3.copyWith(
                              color: NewAppColor.neutral500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              // 선택된 이미지들
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return Container(
                  margin: EdgeInsets.only(left: 8.w),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(
                          image.path,
                          width: 80.w,
                          height: 80.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80.w,
                              height: 80.h,
                              color: NewAppColor.neutral200,
                              child: const Icon(Icons.error),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4.h,
                        right: 4.w,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  bool _shouldShowImagePicker() {
    return widget.type == CommunityListType.freeSharing ||
        widget.type == CommunityListType.itemSale ||
        widget.type == CommunityListType.churchNews;
  }

  bool _shouldShowLocation() {
    return widget.type != CommunityListType.myPosts;
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 5장까지 선택할 수 있습니다')),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          final remaining = 5 - _selectedImages.length;
          _selectedImages.addAll(images.take(remaining));
        });
      }
    } catch (e) {
      print('❌ COMMUNITY_CREATE: 이미지 선택 실패 - $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: 이미지 업로드 처리

      // 타입별로 적절한 모델 생성 및 저장
      switch (widget.type) {
        case CommunityListType.freeSharing:
        case CommunityListType.itemSale:
          final sharingItem = SharingItem(
            id: 0,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            status: _selectedStatus,
            authorId: 0, // 서비스에서 자동 설정
            category: 'general',
            condition: '보통', // 기본값
            quantity: 1,
            location: _locationController.text.trim(),
            contactPhone: _contactPhoneController.text.trim(),
            contactEmail: _contactEmailController.text.trim().isEmpty
                ? null
                : _contactEmailController.text.trim(),
            isFree: _isFree,
            price: _isFree
                ? null
                : int.tryParse(_priceController.text.replaceAll(',', '')),
            images: [], // TODO: 업로드된 이미지 URL
            createdAt: DateTime.now(),
          );

          final response =
              await _communityService.createSharingItem(sharingItem);

          if (mounted) {
            if (response.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response.message)),
              );
              Navigator.pop(context, true); // 목록 새로고침 트리거
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response.message)),
              );
            }
          }
          break;

        case CommunityListType.itemRequest:
          final requestItem = RequestItem(
            id: 0,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            status: _selectedStatus,
            authorId: 0,
            category: 'general',
            location: _locationController.text.trim(),
            contactPhone: _contactPhoneController.text.trim(),
            contactEmail: _contactEmailController.text.trim().isEmpty
                ? null
                : _contactEmailController.text.trim(),
            urgency: 'normal',
            priceRange: _priceRangeController.text.trim().isEmpty
                ? null
                : _priceRangeController.text.trim(),
            quantity: null,
            createdAt: DateTime.now(),
          );

          final response =
              await _communityService.createRequestItem(requestItem);

          if (mounted) {
            if (response.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response.message)),
              );
              Navigator.pop(context, true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response.message)),
              );
            }
          }
          break;

        default:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('아직 지원하지 않는 기능입니다')),
            );
          }
      }
    } catch (e) {
      print('❌ COMMUNITY_CREATE: 게시글 작성 실패 - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 작성에 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
