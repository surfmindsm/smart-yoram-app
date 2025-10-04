import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/community_models.dart';
import 'package:smart_yoram_app/services/community_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/screens/community/community_list_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_yoram_app/components/index.dart';

/// 커뮤니티 게시글 작성/수정 화면 (공통)
/// docs/writing/ API 명세서 기반 구현
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
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // 공통 필드
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // 무료나눔/물품판매 전용
  String? _selectedCategory; // furniture, electronics, books, etc.
  String? _selectedCondition; // new, like_new, used
  int _quantity = 1;
  final TextEditingController _priceController = TextEditingController();
  String? _selectedDeliveryMethod; // 직거래, 택배, 협의
  final TextEditingController _purchaseDateController = TextEditingController();

  // 물품요청 전용
  final TextEditingController _requestedItemController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _neededDateController = TextEditingController();
  final TextEditingController _priceRangeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _selectedUrgency = 'normal'; // low, normal, high

  // 사역자모집 전용
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _churchIntroController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _jobTypeController = TextEditingController();
  String? _selectedEmploymentType; // full-time, part-time, contract, volunteer
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _qualificationsController = TextEditingController();
  final TextEditingController _preferredQualificationsController = TextEditingController();
  final TextEditingController _benefitsController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  // 행사팀모집 전용
  String? _selectedRecruitmentType; // new_member, substitute, project, permanent
  String? _selectedEventType; // sunday-service, wednesday-service, etc.
  String? _selectedTeamType; // solo, praise-team, worship-team, etc.
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _rehearsalTimeController = TextEditingController();
  final TextEditingController _worshipTypeController = TextEditingController();
  List<String> _selectedInstruments = []; // 필요 악기/파트
  final TextEditingController _scheduleController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _compensationController = TextEditingController();

  // 행사팀지원 전용
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();
  String? _selectedInstrument; // 전공 파트
  List<String> _compatibleInstruments = []; // 호환 악기
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();
  String? _portfolioFileUrl; // 포트폴리오 파일 URL
  List<String> _preferredLocations = [];
  List<String> _availableDays = [];
  final TextEditingController _availableTimeController = TextEditingController();
  final TextEditingController _introductionController = TextEditingController();
  String? _selectedTimeSlot; // 활동 가능 시간대
  final TextEditingController _youtubeController = TextEditingController(); // YouTube 링크

  // 교회소식 전용
  String? _selectedNewsCategory; // worship, event, retreat, mission, etc.
  String _selectedPriority = 'normal'; // urgent, important, normal
  final TextEditingController _newsEventDateController = TextEditingController();
  final TextEditingController _newsEventTimeController = TextEditingController();
  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _targetAudienceController = TextEditingController();
  final TextEditingController _participationFeeController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();

  bool _isLoading = false;
  List<XFile> _selectedImages = [];
  String _selectedStatus = 'active';

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
    _contactController.dispose();
    _emailController.dispose();
    _priceController.dispose();
    _requestedItemController.dispose();
    _reasonController.dispose();
    _neededDateController.dispose();
    _priceRangeController.dispose();
    _quantityController.dispose();
    _companyController.dispose();
    _churchIntroController.dispose();
    _positionController.dispose();
    _jobTypeController.dispose();
    _salaryController.dispose();
    _qualificationsController.dispose();
    _preferredQualificationsController.dispose();
    _benefitsController.dispose();
    _deadlineController.dispose();
    _worshipTypeController.dispose();
    _scheduleController.dispose();
    _requirementsController.dispose();
    _compensationController.dispose();
    _nameController.dispose();
    _teamNameController.dispose();
    _experienceController.dispose();
    _portfolioController.dispose();
    _availableTimeController.dispose();
    _introductionController.dispose();
    _youtubeController.dispose();
    _eventDateController.dispose();
    _rehearsalTimeController.dispose();
    _newsEventDateController.dispose();
    _newsEventTimeController.dispose();
    _organizerController.dispose();
    _targetAudienceController.dispose();
    _participationFeeController.dispose();
    _contactPersonController.dispose();
    _purchaseDateController.dispose();
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
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.black),
          ),
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

  /// 공통 필드 - 타입별로 다르게 표시하지 않음
  Widget _buildCommonFields() {
    // 공통 필드는 타입별 필드에서 각각 구현
    return const SizedBox.shrink();
  }

  /// 타입별 특수 필드
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
      case CommunityListType.musicTeamRecruit:
        return _buildMusicTeamRecruitFields();
      case CommunityListType.musicTeamSeeking:
        return _buildMusicTeamSeekingFields();
      case CommunityListType.churchNews:
        return _buildChurchNewsFields();
      default:
        return const SizedBox.shrink();
    }
  }

  /// 무료나눔/물품판매 필드 (웹 기준)
  Widget _buildSharingFields({required bool isFree}) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 상품이미지 (웹: 0/12, 모바일: 0/5)
          _buildImagePickerWithLabel(
            label: '상품이미지',
            required: true,
            maxCount: 12,
          ),
          SizedBox(height: 24.h),

          // 2. 카테고리 *
          Text(
            '카테고리 *',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: '카테고리를 선택하세요',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            value: _selectedCategory,
            items: const [
              DropdownMenuItem(value: 'furniture', child: Text('가구')),
              DropdownMenuItem(value: 'electronics', child: Text('전자제품')),
              DropdownMenuItem(value: 'books', child: Text('도서')),
              DropdownMenuItem(value: 'clothing', child: Text('의류')),
              DropdownMenuItem(value: 'toys', child: Text('장난감')),
              DropdownMenuItem(value: 'household', child: Text('생활용품')),
              DropdownMenuItem(value: 'other', child: Text('기타')),
            ],
            onChanged: (value) => setState(() => _selectedCategory = value),
            validator: (value) => value == null ? '카테고리를 선택해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 3. 제목 *
          Text(
            '제목 *',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: '나눔할 물품의 제목을 입력해주세요',
              hintStyle: FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral400,
              ),
              counterText: '${_titleController.text.length}/100',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            onChanged: (value) => setState(() {}), // 글자수 업데이트
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '제목을 입력해주세요';
              }
              if (value.length > 100) {
                return '제목은 최대 100자까지 입력 가능합니다';
              }
              return null;
            },
          ),
          SizedBox(height: 24.h),

          // 4. 설명 *
          Text(
            '설명 *',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: '나눔할 물품에 대한 상세한 설명을 입력해주세요',
              hintStyle: FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral400,
              ),
              counterText: '${_descriptionController.text.length}/1000',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            maxLines: 8,
            onChanged: (value) => setState(() {}), // 글자수 업데이트
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '설명을 입력해주세요';
              }
              if (value.length > 1000) {
                return '설명은 최대 1000자까지 입력 가능합니다';
              }
              return null;
            },
          ),
          SizedBox(height: 24.h),

          // 5. 상태 *
          Text(
            '상태 *',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: '상품 상태를 선택하세요',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            value: _selectedCondition,
            items: const [
              DropdownMenuItem(value: 'new', child: Text('새 상품')),
              DropdownMenuItem(value: 'like_new', child: Text('거의 새것')),
              DropdownMenuItem(value: 'used', child: Text('사용감 있음')),
            ],
            onChanged: (value) => setState(() => _selectedCondition = value),
            validator: (value) => value == null ? '상품 상태를 선택해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 6. 판매 가격 * (물품판매만)
          if (!isFree) ...[
            Text(
              '판매 가격 *',
              style: FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral900,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                hintText: '숫자로만 입력 (예: 50000)',
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
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
              ),
              style: FigmaTextStyles().body2,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (!isFree && (value == null || value.trim().isEmpty)) {
                  return '판매 가격을 입력해주세요';
                }
                return null;
              },
            ),
            SizedBox(height: 24.h),
          ],

          // 7. 구매 시기 (물품판매만)
          if (!isFree) ...[
            Text(
              '구매 시기',
              style: FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral900,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _purchaseDateController,
              decoration: InputDecoration(
                hintText: '예: 2023년 3월, 작년, 6개월 전',
                hintStyle: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral400,
                ),
                counterText: '${_purchaseDateController.text.length}/50',
                counterStyle: FigmaTextStyles().caption1.copyWith(
                  color: NewAppColor.neutral500,
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
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
              ),
              style: FigmaTextStyles().body2,
              maxLength: 50,
              onChanged: (value) => setState(() {}),
            ),
            SizedBox(height: 24.h),
          ],

          // 8 (무료나눔의 경우 6). 연락처 *
          Text(
            '연락처 *',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _contactController,
            decoration: InputDecoration(
              hintText: '연락 가능한 전화번호를 입력해주세요',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
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
          SizedBox(height: 24.h),

          // 9 (무료나눔의 경우 7). 이메일 (선택)
          Text(
            '이메일',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: '이메일 주소를 입력해주세요 (선택사항)',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  /// 이미지 선택 위젯 (라벨 포함)
  Widget _buildImagePickerWithLabel({
    required String label,
    required bool required,
    required int maxCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral900,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: FigmaTextStyles().body2.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '최대 ${maxCount}장, 각 파일 최대 10MB',
              style: FigmaTextStyles().caption1.copyWith(
                color: NewAppColor.neutral500,
              ),
            ),
            Text(
              '${_selectedImages.length}/$maxCount',
              style: FigmaTextStyles().caption1.copyWith(
                color: NewAppColor.neutral500,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 100.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 사진 추가 버튼
              if (_selectedImages.length < maxCount)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100.w,
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: NewAppColor.neutral100,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: NewAppColor.neutral200,
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 32.sp, color: NewAppColor.neutral400),
                        SizedBox(height: 4.h),
                        Text(
                          '이미지 추가',
                          style: FigmaTextStyles().caption1.copyWith(
                            color: NewAppColor.neutral400,
                          ),
                        ),
                        Text(
                          '최대 10 MB',
                          style: FigmaTextStyles().caption2.copyWith(
                            color: NewAppColor.neutral400,
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
                  width: 100.w,
                  height: 100.h,
                  margin: EdgeInsets.only(left: 8.w),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.file(
                          File(image.path),
                          width: 100.w,
                          height: 100.h,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4.h,
                        right: 4.w,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
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

  /// 물품요청 필드 (웹 기준)
  Widget _buildRequestFields() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 타이틀
          Text(
            '요청 정보',
            style: FigmaTextStyles().headline4.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24.h),

          // 1. 제목 *
          Text(
            '제목 *',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: '요청할 물품의 제목을 입력하세요',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '제목을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 24.h),

          // 2. 요청 물품 * | 카테고리 * (Row)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '요청 물품 *',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _requestedItemController,
                      decoration: InputDecoration(
                        hintText: '구체적인 물품명을 입력하세요',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      style: FigmaTextStyles().body2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '요청 물품을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '카테고리 *',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: '카테고리 선택',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      value: _selectedCategory,
                      items: const [
                        DropdownMenuItem(value: 'furniture', child: Text('가구')),
                        DropdownMenuItem(value: 'electronics', child: Text('전자제품')),
                        DropdownMenuItem(value: 'books', child: Text('도서')),
                        DropdownMenuItem(value: 'clothing', child: Text('의류')),
                        DropdownMenuItem(value: 'toys', child: Text('장난감')),
                        DropdownMenuItem(value: 'household', child: Text('생활용품')),
                        DropdownMenuItem(value: 'other', child: Text('기타')),
                      ],
                      onChanged: (value) => setState(() => _selectedCategory = value),
                      validator: (value) => value == null ? '카테고리를 선택해주세요' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 3. 수량 | 우선순위 (Row)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '수량',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        hintText: '1',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      style: FigmaTextStyles().body2,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '우선순위',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: '보통',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      value: _selectedUrgency,
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('낮음')),
                        DropdownMenuItem(value: 'normal', child: Text('보통')),
                        DropdownMenuItem(value: 'high', child: Text('높음')),
                      ],
                      onChanged: (value) => setState(() => _selectedUrgency = value!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 4. 필요일 * | 최대 예산 (Row)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '필요일 *',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _neededDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: '필요일을 선택해주세요',
                        hintStyle: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral400,
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      style: FigmaTextStyles().body2,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          _neededDateController.text = date.toString().split(' ')[0];
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '필요일을 선택해주세요';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '최대 예산 (선택)',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _priceRangeController,
                      decoration: InputDecoration(
                        hintText: '예: 50,000원',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      style: FigmaTextStyles().body2,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 5. 희망 지역
          Text(
            '희망 지역',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: '거래 희망 지역을 입력하세요',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
          ),
          SizedBox(height: 24.h),

          // 6. 필요 이유
          Text(
            '필요 이유',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: '물품이 필요한 이유를 간단히 설명해주세요',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            maxLines: 4,
          ),
          SizedBox(height: 24.h),

          // 7. 상세 설명
          Text(
            '상세 설명',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: '원하는 물품의 상세 조건이나 상태를 설명해주세요',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            maxLines: 4,
          ),
          SizedBox(height: 24.h),

          // 8. 연락처 * | 이메일 (Row)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '연락처 *',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        hintText: '010-1234-5678',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
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
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이메일 (선택)',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'example@email.com',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      style: FigmaTextStyles().body2,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),

          // 물품 요청 안내
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: NewAppColor.primary100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: NewAppColor.primary600, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '물품 요청 안내',
                      style: FigmaTextStyles().subtitle2.copyWith(
                        color: NewAppColor.primary700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildInfoItem('• 구체적인 물품명과 조건을 명시하면 더 좋은 응답을 받을 수 있습니다.'),
                SizedBox(height: 4.h),
                _buildInfoItem('• 필요일을 정확히 입력하여 적절한 시점에 연락받으세요.'),
                SizedBox(height: 4.h),
                _buildInfoItem('• 예산 범위를 제시하면 적절한 거래가 이루어질 수 있습니다.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 안내 항목
  Widget _buildInfoItem(String text) {
    return Text(
      text,
      style: FigmaTextStyles().caption1.copyWith(
        color: NewAppColor.primary700,
        height: 1.4,
      ),
    );
  }

  /// 사역자모집 필드 (웹 기준)
  Widget _buildJobPostingFields() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== 섹션 1: 모집 정보 =====
          Text(
            '모집 정보',
            style: FigmaTextStyles().headline4.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24.h),

          // 1. 모집 제목 *
          Text(
            '모집 제목 *',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: '예: 청년부 담당 전도사 모집',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '모집 제목을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 24.h),

          // 2. 직책 * | 고용 형태 (Row)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '직책 *',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: '직책 선택',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      value: _selectedCategory,
                      items: const [
                        DropdownMenuItem(value: 'pastor', child: Text('목사')),
                        DropdownMenuItem(value: 'minister', child: Text('전도사')),
                        DropdownMenuItem(value: 'worship', child: Text('찬양사역자')),
                        DropdownMenuItem(value: 'admin', child: Text('행정간사')),
                        DropdownMenuItem(value: 'education', child: Text('교육간사')),
                        DropdownMenuItem(value: 'other', child: Text('기타')),
                      ],
                      onChanged: (value) => setState(() => _selectedCategory = value),
                      validator: (value) => value == null ? '직책을 선택해주세요' : null,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '고용 형태',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: '고용 형태',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      value: _selectedEmploymentType,
                      items: const [
                        DropdownMenuItem(value: 'full-time', child: Text('정규직')),
                        DropdownMenuItem(value: 'contract', child: Text('계약직')),
                        DropdownMenuItem(value: 'part-time', child: Text('시간제')),
                        DropdownMenuItem(value: 'volunteer', child: Text('자원봉사')),
                      ],
                      onChanged: (value) => setState(() => _selectedEmploymentType = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 3. 급여 조건 | 근무 지역 (Row with icons)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '급여 조건',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _salaryController,
                      decoration: InputDecoration(
                        hintText: '예: 월 300만원, 협의',
                        hintStyle: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral400,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 12.w, right: 8.w),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₩',
                                style: FigmaTextStyles().body2.copyWith(
                                  color: NewAppColor.neutral400,
                                  fontSize: 18.sp,
                                ),
                              ),
                            ],
                          ),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      style: FigmaTextStyles().body2,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '근무 지역',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: '예: 서울 강남구 (교회 주소 자동)',
                        hintStyle: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral400,
                        ),
                        prefixIcon: Icon(Icons.location_on, color: NewAppColor.neutral400, size: 20.sp),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      style: FigmaTextStyles().body2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 4. 지원 마감일 *
          Text(
            '지원 마감일 *',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _deadlineController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: '지원 마감일을 선택해주세요',
              hintStyle: FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral400,
              ),
              prefixIcon: const Icon(Icons.calendar_today),
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                _deadlineController.text = date.toString().split(' ')[0];
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '지원 마감일을 선택해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 32.h),

          // ===== 섹션 2: 상세 내용 =====
          Text(
            '상세 내용',
            style: FigmaTextStyles().headline4.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24.h),

          // 5. 업무 내용
          Text(
            '업무 내용',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: '담당하게 될 업무와 역할을 자세히 설명해주세요',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            maxLines: 6,
          ),
          SizedBox(height: 24.h),

          // 6. 자격 요건
          Text(
            '자격 요건',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _qualificationsController,
            decoration: InputDecoration(
              hintText: '예: 신학대 졸업, 목사 안수, 청년 사역 경험',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            maxLines: 4,
          ),
          SizedBox(height: 24.h),

          // 7. 우대 사항
          Text(
            '우대 사항',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _preferredQualificationsController,
            decoration: InputDecoration(
              hintText: '예: 청년 사역 경험, 찬양 가능',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            maxLines: 4,
          ),
          SizedBox(height: 24.h),

          // 8. 복리후생
          Text(
            '복리후생',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _benefitsController,
            decoration: InputDecoration(
              hintText: '예: 4대보험, 연차, 숙소 제공',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
            style: FigmaTextStyles().body2,
            maxLines: 4,
          ),
          SizedBox(height: 32.h),

          // ===== 섹션 3: 연락처 정보 =====
          Text(
            '연락처 정보',
            style: FigmaTextStyles().headline4.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24.h),

          // 9. 담당자 연락처 * | 이메일(선택) (Row)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '담당자 연락처 *',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        hintText: '010-1234-5678',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
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
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이메일 (선택)',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'example@email.com',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      style: FigmaTextStyles().body2,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),

          // 사역자 모집 안내
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: NewAppColor.primary100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: NewAppColor.primary600, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '사역자 모집 안내',
                      style: FigmaTextStyles().subtitle2.copyWith(
                        color: NewAppColor.primary700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildInfoItem('• 명확한 업무 내용과 자격 요건을 제시하면 적합한 지원자를 받을 수 있습니다.'),
                SizedBox(height: 4.h),
                _buildInfoItem('• 급여 조건과 복리후생을 구체적으로 명시해주세요.'),
                SizedBox(height: 4.h),
                _buildInfoItem('• 교회 소개를 통해 지원자가 교회 분위기를 파악할 수 있도록 해주세요.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 행사팀모집 필드
  Widget _buildMusicTeamRecruitFields() {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== 섹션 1: 모집 정보 =====
          Text(
            '모집 정보',
            style: FigmaTextStyles().headline4.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 24.h),

          // 1. 모집 제목 *
          Text(
            '모집 제목 *',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: '예: 주일예배 피아니스트 모집',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              counterText: '${_titleController.text.length}/100',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.primary500, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            maxLength: 100,
            onChanged: (value) => setState(() {}),
            validator: (value) => value?.trim().isEmpty ?? true ? '제목을 입력해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 2. 행사 유형 *
          Text(
            '행사 유형 *',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: '행사 유형 선택',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            value: _selectedEventType,
            items: const [
              DropdownMenuItem(value: 'sunday-service', child: Text('주일예배')),
              DropdownMenuItem(value: 'wednesday-service', child: Text('수요예배')),
              DropdownMenuItem(value: 'dawn-service', child: Text('새벽예배')),
              DropdownMenuItem(value: 'special-service', child: Text('특별예배')),
              DropdownMenuItem(value: 'revival', child: Text('부흥회')),
              DropdownMenuItem(value: 'praise-meeting', child: Text('찬양집회')),
              DropdownMenuItem(value: 'wedding', child: Text('결혼식')),
              DropdownMenuItem(value: 'funeral', child: Text('장례식')),
              DropdownMenuItem(value: 'retreat', child: Text('수련회')),
              DropdownMenuItem(value: 'concert', child: Text('콘서트')),
              DropdownMenuItem(value: 'other', child: Text('기타')),
            ],
            onChanged: (value) => setState(() => _selectedEventType = value),
            validator: (value) => value == null ? '행사 유형을 선택해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 3. 모집 팀 형태 *
          Text(
            '모집 팀 형태 *',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: '팀 형태 선택',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            value: _selectedTeamType,
            items: const [
              DropdownMenuItem(value: 'solo', child: Text('현재 솔로 활동')),
              DropdownMenuItem(value: 'praise-team', child: Text('찬양팀')),
              DropdownMenuItem(value: 'worship-team', child: Text('워십팀')),
              DropdownMenuItem(value: 'acoustic-team', child: Text('어쿠스틱 팀')),
              DropdownMenuItem(value: 'band', child: Text('밴드')),
              DropdownMenuItem(value: 'orchestra', child: Text('오케스트라')),
              DropdownMenuItem(value: 'choir', child: Text('합창단')),
              DropdownMenuItem(value: 'dance-team', child: Text('무용팀')),
              DropdownMenuItem(value: 'other', child: Text('기타')),
            ],
            onChanged: (value) => setState(() => _selectedTeamType = value),
            validator: (value) => value == null ? '팀 형태를 선택해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 4. 행사 날짜 | 리허설 일정 (2 columns)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '행사 날짜',
                      style: FigmaTextStyles().body2.copyWith(
                            color: NewAppColor.neutral900,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _eventDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: '행사 날짜를 선택해주세요',
                        hintStyle: FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral400,
                            ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 12.w, right: 8.w),
                          child: Icon(Icons.calendar_today, size: 20.r, color: NewAppColor.neutral500),
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 40.w),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: NewAppColor.neutral300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: NewAppColor.neutral300),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _eventDateController.text = date.toString().split(' ')[0];
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '리허설 일정',
                      style: FigmaTextStyles().body2.copyWith(
                            color: NewAppColor.neutral900,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _rehearsalTimeController,
                      decoration: InputDecoration(
                        hintText: '예: 매주 토요일 오후 2시',
                        hintStyle: FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral400,
                            ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 12.w, right: 8.w),
                          child: Icon(Icons.access_time, size: 20.r, color: NewAppColor.neutral500),
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 40.w),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: NewAppColor.neutral300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: NewAppColor.neutral300),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 5. 장소
          Text(
            '장소',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: '교회 주소나 지역을 입력하세요',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 12.w, right: 8.w),
                child: Icon(Icons.location_on, size: 20.r, color: NewAppColor.neutral500),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 40.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 32.h),

          // ===== 섹션 2: 상세 내용 =====
          Text(
            '상세 내용',
            style: FigmaTextStyles().headline4.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 24.h),

          // 1. 상세 설명
          Text(
            '상세 설명',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: '행사 내용, 분위기, 특별한 요구사항 등을 자세히 설명해주세요',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.primary500, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            maxLines: 5,
          ),
          SizedBox(height: 24.h),

          // 2. 자격 요건
          Text(
            '자격 요건',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _requirementsController,
            decoration: InputDecoration(
              hintText: '예: 3년 이상 연주 경험, 악보 시창 가능',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 24.h),

          // 3. 보상/사례비
          Text(
            '보상/사례비',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _compensationController,
            decoration: InputDecoration(
              hintText: '예: 회당 5만원, 봉사, 협의',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: NewAppColor.neutral300),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 32.h),

          // ===== 섹션 3: 연락처 정보 =====
          Text(
            '연락처 정보',
            style: FigmaTextStyles().headline4.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 24.h),

          // 담당자 연락처 * | 이메일 (선택) (2 columns)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '담당자 연락처 *',
                      style: FigmaTextStyles().body2.copyWith(
                            color: NewAppColor.neutral900,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        hintText: '010-1234-5678',
                        hintStyle: FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral400,
                            ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: NewAppColor.neutral300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: NewAppColor.neutral300),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.trim().isEmpty ?? true ? '연락처를 입력해주세요' : null,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이메일 (선택)',
                      style: FigmaTextStyles().body2.copyWith(
                            color: NewAppColor.neutral900,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'example@email.com',
                        hintStyle: FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral400,
                            ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: NewAppColor.neutral300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: NewAppColor.neutral300),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),

          // ===== 행사팀 모집 안내 =====
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: NewAppColor.primary100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20.r, color: NewAppColor.primary500),
                    SizedBox(width: 8.w),
                    Text(
                      '행사팀 모집 안내',
                      style: FigmaTextStyles().body1.copyWith(
                            color: NewAppColor.primary500,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildInfoItem('필요한 팀 형태의 연주 수준을 구체적으로 명시해주세요.'),
                _buildInfoItem('리허설 일정과 행사 일정을 명확히 안내해주세요.'),
                _buildInfoItem('보상이나 사례비 조건을 미리 협의해두시기 바랍니다.'),
                _buildInfoItem('교회의 음악 스타일이나 선호하는 장르가 있다면 안내해주세요.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 행사팀지원 필드
  Widget _buildMusicTeamSeekingFields() {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== 섹션 1: 기본 정보 =====
          Text(
            '기본 정보',
            style: FigmaTextStyles().headline4.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 16.h),

          // 1. 지원서 제목 * | 현재 활동 팀명 (선택) - 2 columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: '지원서 제목 *',
                    hintText: '지원서 제목을 입력하세요',
                    counterText: '${_titleController.text.length}/100',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  maxLength: 100,
                  onChanged: (value) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '지원서 제목을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextFormField(
                  controller: _teamNameController,
                  decoration: InputDecoration(
                    labelText: '현재 활동 팀명 (선택)',
                    hintText: '팀명을 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 2. 팀 형태 *
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: '팀 형태 *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            value: _selectedTeamType,
            items: const [
              DropdownMenuItem(value: 'solo', child: Text('현재 솔로 활동')),
              DropdownMenuItem(value: 'praise-team', child: Text('찬양팀')),
              DropdownMenuItem(value: 'worship-team', child: Text('워십팀')),
              DropdownMenuItem(value: 'acoustic-team', child: Text('어쿠스틱 팀')),
              DropdownMenuItem(value: 'band', child: Text('밴드')),
              DropdownMenuItem(value: 'orchestra', child: Text('오케스트라')),
              DropdownMenuItem(value: 'choir', child: Text('합창단')),
              DropdownMenuItem(value: 'dance-team', child: Text('무용팀')),
              DropdownMenuItem(value: 'other', child: Text('기타')),
            ],
            onChanged: (value) => setState(() => _selectedTeamType = value),
            validator: (value) => value == null ? '팀 형태를 선택해주세요' : null,
          ),
          SizedBox(height: 16.h),

          // 3. 연주 경력
          TextFormField(
            controller: _experienceController,
            decoration: InputDecoration(
              labelText: '연주 경력',
              hintText: '찬양팀, 워십팀, 밴드 등 경력을 쓰면 좋은 결과 생길 수 있습니다.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            maxLines: 5,
          ),
          SizedBox(height: 16.h),

          // 4. 활동 가능 지역
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: '활동 가능 지역',
              hintText: '주소 또는 시/군 이름 입력',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20.r, color: NewAppColor.neutral600),
              suffixIcon: TextButton(
                onPressed: () {
                  // TODO: 지역 추가 기능
                  AppToast.show(context, '지역 추가 기능 준비 중', type: ToastType.info);
                },
                child: Text(
                  '추가',
                  style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.primary500,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // 5. 활동 가능 요일
          Text(
            '활동 가능 요일',
            style: FigmaTextStyles().body1.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: ['월', '화', '수', '목', '금', '토', '일']
                .map((day) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: day != '일' ? 8.w : 0),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: FigmaTextStyles().body2.copyWith(
                                    color: _availableDays.contains(day) ? Colors.white : NewAppColor.neutral700,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          selected: _availableDays.contains(day),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _availableDays.add(day);
                              } else {
                                _availableDays.remove(day);
                              }
                            });
                          },
                          selectedColor: NewAppColor.primary500,
                          backgroundColor: NewAppColor.neutral100,
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 16.h),

          // 6. 활동 가능 시간대
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: '활동 가능 시간대',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            value: _selectedTimeSlot,
            items: const [
              DropdownMenuItem(value: 'morning', child: Text('오전 (9:00-12:00)')),
              DropdownMenuItem(value: 'afternoon', child: Text('오후 (13:00-18:00)')),
              DropdownMenuItem(value: 'evening', child: Text('저녁 (18:00-21:00)')),
              DropdownMenuItem(value: 'night', child: Text('야간 (21:00-23:00)')),
              DropdownMenuItem(value: 'anytime', child: Text('상시 가능')),
              DropdownMenuItem(value: 'negotiable', child: Text('협의 후 결정')),
            ],
            onChanged: (value) => setState(() => _selectedTimeSlot = value),
          ),
          SizedBox(height: 24.h),

          // ===== 섹션 2: 포트폴리오 =====
          Text(
            '포트폴리오',
            style: FigmaTextStyles().headline4.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 16.h),

          // 1. YouTube 링크 (선택)
          TextFormField(
            controller: _youtubeController,
            decoration: InputDecoration(
              labelText: 'YouTube 링크 (선택)',
              hintText: 'YouTube 연주 영상 주소를 입력하세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // 2. 포트폴리오 파일 업로드 (선택)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '포트폴리오 파일 업로드 (선택)',
                style: FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  border: Border.all(color: NewAppColor.neutral300),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Icon(Icons.upload_file, size: 40.r, color: NewAppColor.neutral500),
                    SizedBox(height: 8.h),
                    Text(
                      '파일을 드래그',
                      style: FigmaTextStyles().body2.copyWith(
                            color: NewAppColor.neutral700,
                          ),
                    ),
                    SizedBox(height: 12.h),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: 파일 업로드
                        AppToast.show(context, '파일 업로드 기능 준비 중', type: ToastType.info);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NewAppColor.primary500,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        '파일 선택',
                        style: FigmaTextStyles().body2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'PDF, MP3, MP4, DOC (최대 10MB)',
                      style: FigmaTextStyles().body2.copyWith(
                            fontSize: 12.sp,
                            color: NewAppColor.neutral500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // ===== 섹션 3: 연락처 정보 =====
          Text(
            '연락처 정보',
            style: FigmaTextStyles().headline4.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 16.h),

          // 연락처 * | 이메일 (선택) - 2 columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    labelText: '연락처 *',
                    hintText: '010-1234-5678',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '연락처를 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: '이메일 (선택)',
                    hintText: 'example@email.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 교회소식 필드 (행사 소식 등록)
  Widget _buildChurchNewsFields() {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 행사 이미지 (0/12)
          Text(
            '행사 이미지 (0/12)',
            style: FigmaTextStyles().body1.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () {
              // TODO: 이미지 선택
              AppToast.show(context, '이미지 선택 기능 준비 중', type: ToastType.info);
            },
            child: Container(
              width: 164.w,
              height: 164.w,
              decoration: BoxDecoration(
                border: Border.all(color: NewAppColor.neutral300, width: 1),
                borderRadius: BorderRadius.circular(8.r),
                color: NewAppColor.neutral100,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 40.r, color: NewAppColor.neutral400),
                  SizedBox(height: 8.h),
                  Text(
                    '이미지 추가',
                    style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral600,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '최대 10 MB',
                    style: FigmaTextStyles().body2.copyWith(
                          fontSize: 12.sp,
                          color: NewAppColor.neutral500,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // 카테고리 *
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: '카테고리 *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            value: _selectedNewsCategory,
            items: const [
              DropdownMenuItem(value: 'worship', child: Text('특별예배/연합예배')),
              DropdownMenuItem(value: 'event', child: Text('행사')),
              DropdownMenuItem(value: 'retreat', child: Text('수련회')),
              DropdownMenuItem(value: 'mission', child: Text('선교')),
              DropdownMenuItem(value: 'education', child: Text('교육')),
              DropdownMenuItem(value: 'volunteer', child: Text('봉사')),
              DropdownMenuItem(value: 'other', child: Text('기타')),
            ],
            onChanged: (value) => setState(() => _selectedNewsCategory = value),
            validator: (value) => value == null ? '카테고리를 선택해주세요' : null,
          ),
          SizedBox(height: 16.h),

          // 제목 *
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '제목 *',
              hintText: '행사 소식의 제목을 입력하세요',
              counterText: '${_titleController.text.length}/100',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            maxLength: 100,
            onChanged: (value) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '제목을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),

          // 내용 *
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: '내용 *',
              hintText: '행사 소식의 상세 내용을 입력하세요',
              counterText: '${_descriptionController.text.length}/1000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            maxLines: 6,
            maxLength: 1000,
            onChanged: (value) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '내용을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),

          // 우선순위 *
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: '우선순위 *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            value: _selectedPriority,
            items: const [
              DropdownMenuItem(value: 'urgent', child: Text('긴급')),
              DropdownMenuItem(value: 'important', child: Text('중요')),
              DropdownMenuItem(value: 'normal', child: Text('일반')),
            ],
            onChanged: (value) => setState(() => _selectedPriority = value!),
          ),
          SizedBox(height: 16.h),

          // 행사일
          TextFormField(
            controller: _newsEventDateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: '행사일',
              hintText: '날짜를 선택해주세요',
              prefixIcon: Icon(Icons.calendar_today, size: 20.r, color: NewAppColor.neutral600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _newsEventDateController.text = date.toString().split(' ')[0];
                });
              }
            },
          ),
          SizedBox(height: 16.h),

          // 행사 시간
          TextFormField(
            controller: _newsEventTimeController,
            decoration: InputDecoration(
              labelText: '행사 시간',
              hintText: '-- --:--',
              suffixIcon: Icon(Icons.access_time, size: 20.r, color: NewAppColor.neutral600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // 장소
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: '장소',
              hintText: '행사가 열리는 장소',
              counterText: '${_locationController.text.length}/100',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            maxLength: 100,
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 16.h),

          // 주최자/부서 *
          TextFormField(
            controller: _organizerController,
            decoration: InputDecoration(
              labelText: '주최자/부서 *',
              hintText: '행사를 주최하는 부서나 담당자',
              counterText: '${_organizerController.text.length}/50',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            maxLength: 50,
            onChanged: (value) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '주최자/부서를 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),

          // 대상
          TextFormField(
            controller: _targetAudienceController,
            decoration: InputDecoration(
              labelText: '대상',
              hintText: '예: 전체, 청년부, 장년부 등',
              counterText: '${_targetAudienceController.text.length}/50',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            maxLength: 50,
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 16.h),

          // 참가비
          TextFormField(
            controller: _participationFeeController,
            decoration: InputDecoration(
              labelText: '참가비',
              hintText: '예: 무료, 10,000원 등',
              counterText: '${_participationFeeController.text.length}/50',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            maxLength: 50,
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 16.h),

          // 담당자
          TextFormField(
            controller: _contactPersonController,
            decoration: InputDecoration(
              labelText: '담당자',
              hintText: '문의 담당자 이름',
              counterText: '${_contactPersonController.text.length}/50',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            maxLength: 50,
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 16.h),

          // 연락처
          TextFormField(
            controller: _contactController,
            decoration: InputDecoration(
              labelText: '연락처',
              hintText: '010-0000-0000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16.h),

          // 이메일
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: '이메일',
              hintText: 'contact@church.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  /// 이미지 선택
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          // 최대 5장까지만 추가
          final remainingSlots = 5 - _selectedImages.length;
          _selectedImages.addAll(images.take(remainingSlots));
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '이미지 선택 실패: $e',
          type: ToastType.error,
        );
      }
    }
  }

  /// 제출
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 무료나눔/물품판매는 사진 필수
    if ((widget.type == CommunityListType.freeSharing ||
         widget.type == CommunityListType.itemSale) &&
        _selectedImages.isEmpty) {
      AppToast.show(
        context,
        '최소 1장 이상의 사진을 등록해주세요',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. 이미지 업로드
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }

      // 2. 게시글 작성
      bool success = false;
      switch (widget.type) {
        case CommunityListType.freeSharing:
        case CommunityListType.itemSale:
          success = await _submitSharing(imageUrls);
          break;
        case CommunityListType.itemRequest:
          success = await _submitRequest(imageUrls);
          break;
        case CommunityListType.jobPosting:
          success = await _submitJobPosting();
          break;
        case CommunityListType.musicTeamRecruit:
          success = await _submitMusicTeamRecruit();
          break;
        case CommunityListType.musicTeamSeeking:
          success = await _submitMusicTeamSeeking();
          break;
        case CommunityListType.churchNews:
          success = await _submitChurchNews(imageUrls);
          break;
        default:
          success = false;
      }

      if (mounted) {
        if (success) {
          AppToast.show(context, '게시글이 등록되었습니다', type: ToastType.success);
          Navigator.pop(context, true); // 성공 시 true 반환
        } else {
          AppToast.show(context, '게시글 등록에 실패했습니다', type: ToastType.error);
        }
      }
    } catch (e) {
      print('❌ 게시글 작성 실패: $e');
      if (mounted) {
        AppToast.show(
          context,
          '게시글 등록 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 이미지 업로드 (Supabase Storage)
  Future<List<String>> _uploadImages() async {
    // TODO: Supabase Storage에 이미지 업로드 구현
    // docs/writing/mobile-api-free-sharing.md 참고
    print('📸 이미지 업로드 시작: ${_selectedImages.length}장');

    // 임시로 빈 배열 반환
    AppToast.show(context, '이미지 업로드 기능 준비 중', type: ToastType.info);
    return [];
  }

  /// 무료나눔/물품판매 제출
  Future<bool> _submitSharing(List<String> imageUrls) async {
    final isFree = widget.type == CommunityListType.freeSharing;

    final response = await _communityService.createSharingItem(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      condition: _selectedCondition!,
      quantity: _quantity,
      location: _locationController.text.trim(),
      images: imageUrls,
      isFree: isFree,
      price: isFree ? null : int.tryParse(_priceController.text),
      deliveryMethod: _selectedDeliveryMethod,
      purchaseDate: _purchaseDateController.text.trim().isEmpty
          ? null
          : _purchaseDateController.text.trim(),
    );

    return response.success;
  }

  /// 물품요청 제출
  Future<bool> _submitRequest(List<String> imageUrls) async {
    final response = await _communityService.createRequestItem(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory ?? 'other',
      requestedItem: _requestedItemController.text.trim(),
      quantity: _quantity,
      reason: _reasonController.text.trim(),
      neededDate: _neededDateController.text.trim().isEmpty
          ? null
          : _neededDateController.text.trim(),
      location: _locationController.text.trim(),
      priceRange: _priceRangeController.text.trim(),
      urgency: _selectedUrgency,
      images: imageUrls,
    );

    return response.success;
  }

  /// 사역자모집 제출
  Future<bool> _submitJobPosting() async {
    final response = await _communityService.createJobPost(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      company: _companyController.text.trim(),
      churchIntro: _churchIntroController.text.trim(),
      position: _positionController.text.trim(),
      jobType: _jobTypeController.text.trim(),
      employmentType: _selectedEmploymentType ?? 'full-time',
      salary: _salaryController.text.trim(),
      qualifications: _qualificationsController.text.trim(),
      location: _locationController.text.trim(),
      deadline: _deadlineController.text.trim().isEmpty
          ? null
          : _deadlineController.text.trim(),
    );

    return response.success;
  }

  /// 행사팀모집 제출
  Future<bool> _submitMusicTeamRecruit() async {
    final response = await _communityService.createMusicTeamRecruitment(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      eventType: _selectedEventType ?? 'other',
      teamType: _selectedTeamType ?? 'other',
      eventDate: _eventDateController.text.trim().isEmpty
          ? null
          : _eventDateController.text.trim(),
      rehearsalSchedule: _rehearsalTimeController.text.trim().isEmpty
          ? null
          : _rehearsalTimeController.text.trim(),
      location: _locationController.text.trim(),
      requirements: _requirementsController.text.trim().isEmpty
          ? null
          : _requirementsController.text.trim(),
      compensation: _compensationController.text.trim().isEmpty
          ? null
          : _compensationController.text.trim(),
      contactPhone: _contactController.text.trim(),
      contactEmail: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
    );

    return response.success;
  }

  /// 행사팀지원 제출
  Future<bool> _submitMusicTeamSeeking() async {
    final response = await _communityService.createMusicTeamSeeker(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      name: _nameController.text.trim(),
      teamName: _teamNameController.text.trim(),
      instrument: _selectedInstrument!,
      instruments: _compatibleInstruments,
      experience: _experienceController.text.trim(),
      portfolio: _portfolioController.text.trim(),
      portfolioFile: _portfolioFileUrl,
      preferredLocation: _preferredLocations,
      availableDays: _availableDays,
      availableTime: _availableTimeController.text.trim(),
      introduction: _introductionController.text.trim(),
    );

    return response.success;
  }

  /// 교회소식 제출
  Future<bool> _submitChurchNews(List<String> imageUrls) async {
    final response = await _communityService.createChurchNews(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedNewsCategory!,
      priority: _selectedPriority,
      eventDate: _newsEventDateController.text.trim().isEmpty
          ? null
          : _newsEventDateController.text.trim(),
      eventTime: _newsEventTimeController.text.trim().isEmpty
          ? null
          : _newsEventTimeController.text.trim(),
      location: _locationController.text.trim(),
      organizer: _organizerController.text.trim(),
      targetAudience: _targetAudienceController.text.trim(),
      participationFee: _participationFeeController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      images: imageUrls,
    );

    return response.success;
  }
}
