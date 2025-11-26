import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/community_models.dart';
import 'package:smart_yoram_app/services/community_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/services/supabase_service.dart';
import 'package:smart_yoram_app/screens/community/community_list_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_yoram_app/components/index.dart';
import 'package:smart_yoram_app/utils/location_data.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController _priceController = TextEditingController();

  // 지역 선택 (도/시, 시/군/구)
  String? _selectedProvince; // 도/시
  String? _selectedDistrict; // 시/군/구
  bool _deliveryAvailable = false; // 택배 가능 여부
  DateTime? _purchaseDate; // 구매 날짜

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
  List<String> _existingImageUrls = []; // 기존 이미지 URL 목록
  String _selectedStatus = 'active';
  bool _isFreeSharing = false; // 무료나눔 체크박스 상태

  @override
  void initState() {
    super.initState();
    print('🔍 initState 호출됨 - existingPost: ${widget.existingPost != null ? "있음" : "없음"}');
    if (widget.existingPost != null) {
      print('📦 existingPost 내용: ${widget.existingPost}');
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
    super.dispose();
  }

  void _loadExistingPost() {
    final post = widget.existingPost;
    if (post == null) return;

    // Map 타입인 경우 (myPosts에서 온 경우)
    if (post is Map<String, dynamic>) {
      final tableName = post['tableName'] as String? ?? post['table'] as String?;

      // 공통 필드
      _titleController.text = post['title'] ?? '';
      _descriptionController.text = post['description'] ?? '';
      _locationController.text = post['location'] ?? '';

      // 이미지 로드
      if (post['images'] != null) {
        if (post['images'] is List) {
          _existingImageUrls = List<String>.from(post['images']);
        } else if (post['images'] is String) {
          _existingImageUrls = [post['images'] as String];
        }
        print('📸 기존 이미지 로드됨: ${_existingImageUrls.length}장 - $_existingImageUrls');
      }

      // 상태 로드
      if (post['status'] != null) {
        _selectedStatus = post['status'] as String;
      }

      // 테이블별 처리
      if (tableName == 'community_sharing') {
        _selectedCategory = post['category'];
        _selectedCondition = post['condition'];
        _isFreeSharing = post['is_free'] == true;
        if (!_isFreeSharing && post['price'] != null) {
          _priceController.text = post['price'].toString();
        }
        _contactController.text = post['contact_info'] ?? post['contact_phone'] ?? '';
        _emailController.text = post['contact_email'] ?? '';
      } else if (tableName == 'community_requests') {
        _requestedItemController.text = post['requested_item'] ?? '';
        _reasonController.text = post['reason'] ?? '';
        _neededDateController.text = post['needed_date'] ?? '';
        _priceRangeController.text = post['price_range'] ?? '';
        _quantityController.text = post['quantity']?.toString() ?? '';
        _selectedUrgency = post['urgency'] ?? 'normal';
        _contactController.text = post['contact_info'] ?? post['contact_phone'] ?? '';
        _emailController.text = post['contact_email'] ?? '';
      } else if (tableName == 'job_posts') {
        _companyController.text = post['company'] ?? '';
        _churchIntroController.text = post['church_intro'] ?? '';
        _positionController.text = post['position'] ?? '';
        _jobTypeController.text = post['job_type'] ?? '';
        _selectedEmploymentType = post['employment_type'];
        _salaryController.text = post['salary'] ?? '';
        _deadlineController.text = post['deadline'] ?? '';
        _contactController.text = post['contact_phone'] ?? '';
        _emailController.text = post['contact_email'] ?? '';
      } else if (tableName == 'community_music_teams') {
        _selectedRecruitmentType = post['recruitment_type'];
        _worshipTypeController.text = post['worship_type'] ?? '';
        _scheduleController.text = post['schedule'] ?? '';
        _requirementsController.text = post['requirements'] ?? '';
        _compensationController.text = post['compensation'] ?? '';
        _contactController.text = post['contact_phone'] ?? '';
        _emailController.text = post['contact_email'] ?? '';
      } else if (tableName == 'music_team_seekers') {
        _nameController.text = post['name'] ?? '';
        _teamNameController.text = post['team_name'] ?? '';
        _selectedInstrument = post['instrument'];
        _experienceController.text = post['experience'] ?? '';
        _portfolioController.text = post['portfolio'] ?? '';
        _availableDays = post['available_days'] != null
            ? List<String>.from(post['available_days'])
            : [];
        _availableTimeController.text = post['available_time'] ?? '';
        _introductionController.text = post['introduction'] ?? '';
        _contactController.text = post['contact_phone'] ?? '';
        _emailController.text = post['contact_email'] ?? '';
      } else if (tableName == 'church_news') {
        _contactController.text = post['contact_phone'] ?? '';
        _emailController.text = post['contact_email'] ?? '';
      }

      setState(() {});
      return;
    }

    // 타입별 필드 로드 (모델 객체인 경우)
    if (post is SharingItem) {
      _titleController.text = post.title;
      _descriptionController.text = post.description ?? '';
      _locationController.text = post.location ?? '';
      _selectedCategory = post.category;
      _selectedCondition = post.condition;
      _isFreeSharing = post.isFree;
      if (!_isFreeSharing && post.price != null) {
        _priceController.text = post.price.toString();
      }
      _contactController.text = post.contactPhone;
      _emailController.text = post.contactEmail ?? '';
      _selectedStatus = post.status;
      // 지역 정보 로드
      _selectedProvince = post.province;
      _selectedDistrict = post.district;
      _deliveryAvailable = post.deliveryAvailable ?? false;
      // 이미지 로드
      _existingImageUrls = List<String>.from(post.images);
      print('📸 기존 이미지 로드됨 (SharingItem): ${_existingImageUrls.length}장 - $_existingImageUrls');
    } else if (post is RequestItem) {
      _titleController.text = post.title;
      _descriptionController.text = post.description ?? '';
      _locationController.text = post.location ?? '';
      _requestedItemController.text = post.requestedItem ?? '';
      _reasonController.text = post.reason ?? '';
      _neededDateController.text = post.neededDate ?? '';
      _priceRangeController.text = post.priceRange ?? '';
      _quantityController.text = post.quantity?.toString() ?? '';
      _selectedUrgency = post.urgency ?? 'normal';
      _contactController.text = post.contactPhone;
      _emailController.text = post.contactEmail ?? '';
      _selectedStatus = post.status;
      // 지역 정보 로드
      _selectedProvince = post.province;
      _selectedDistrict = post.district;
      _deliveryAvailable = post.deliveryAvailable ?? false;
      // 이미지 로드
      if (post.images != null) {
        _existingImageUrls = List<String>.from(post.images!);
        print('📸 기존 이미지 로드됨 (RequestItem): ${_existingImageUrls.length}장 - $_existingImageUrls');
      }
    } else if (post is JobPost) {
      _titleController.text = post.title;
      _descriptionController.text = post.description ?? '';
      _locationController.text = post.location ?? '';
      _companyController.text = post.company ?? '';
      _churchIntroController.text = post.churchIntro ?? '';
      _positionController.text = post.position ?? '';
      _jobTypeController.text = post.jobType ?? '';
      _selectedEmploymentType = post.employmentType;
      _salaryController.text = post.salary ?? '';
      _deadlineController.text = post.deadline ?? '';
      _contactController.text = post.contactPhone ?? '';
      _emailController.text = post.contactEmail ?? '';
      // 지역 정보 로드
      _selectedProvince = post.province;
      _selectedDistrict = post.district;
      _deliveryAvailable = post.deliveryAvailable ?? false;
    } else if (post is MusicTeamRecruitment) {
      _titleController.text = post.title;
      _descriptionController.text = post.description ?? '';
      _locationController.text = post.location ?? '';
      _selectedRecruitmentType = post.recruitmentType;
      _worshipTypeController.text = post.worshipType ?? '';
      _scheduleController.text = post.schedule ?? '';
      _requirementsController.text = post.requirements ?? '';
      _compensationController.text = post.compensation ?? '';
      _contactController.text = post.contactPhone;
      _emailController.text = post.contactEmail ?? '';
    } else if (post is MusicTeamSeeker) {
      _titleController.text = post.title;
      _descriptionController.text = post.description ?? '';
      _nameController.text = post.name ?? '';
      _teamNameController.text = post.teamName ?? '';
      _selectedInstrument = post.instrument;
      _experienceController.text = post.experience ?? '';
      _portfolioController.text = post.portfolio ?? '';
      _availableDays = post.availableDays ?? [];
      _availableTimeController.text = post.availableTime ?? '';
      _introductionController.text = post.introduction ?? '';
      _contactController.text = post.contactPhone;
      _emailController.text = post.contactEmail ?? '';
    } else if (post is ChurchNews) {
      _titleController.text = post.title;
      _descriptionController.text = post.content ?? post.description ?? '';
      _locationController.text = post.location ?? '';
      _contactController.text = post.contactPhone ?? '';
      _emailController.text = post.contactEmail ?? '';
      _selectedStatus = post.status;
      // 이미지 로드
      if (post.images != null) {
        _existingImageUrls = List<String>.from(post.images!);
        print('📸 기존 이미지 로드됨 (ChurchNews): ${_existingImageUrls.length}장 - $_existingImageUrls');
      }
    }

    setState(() {});
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
    // 실제 타입 결정 (myPosts, myFavorites 등에서 수정하는 경우)
    CommunityListType actualType = widget.type;

    if (widget.type == CommunityListType.myPosts ||
        widget.type == CommunityListType.myFavorites) {
      // existingPost가 Map인 경우 tableName 정보로 타입 판단
      if (widget.existingPost is Map<String, dynamic>) {
        final post = widget.existingPost as Map<String, dynamic>;
        final tableName = post['tableName'] as String? ?? post['table'] as String?;
        final isFree = post['is_free'] == true;

        if (tableName == 'community_sharing') {
          actualType = isFree
              ? CommunityListType.freeSharing
              : CommunityListType.itemSale;
        } else if (tableName == 'community_requests') {
          actualType = CommunityListType.itemRequest;
        } else if (tableName == 'job_posts') {
          actualType = CommunityListType.jobPosting;
        } else if (tableName == 'community_music_teams') {
          actualType = CommunityListType.musicTeamRecruit;
        } else if (tableName == 'music_team_seekers') {
          actualType = CommunityListType.musicTeamSeeking;
        } else if (tableName == 'church_news') {
          actualType = CommunityListType.churchNews;
        }
      }
    }

    switch (actualType) {
      case CommunityListType.freeSharing:
      case CommunityListType.itemSale:
        return _buildSharingFields();
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
  Widget _buildSharingFields() {
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
            decoration: _buildInputDecoration(hintText: '카테고리를 선택하세요'),
            value: _selectedCategory,
            items: const [
              DropdownMenuItem(value: '가구', child: Text('가구')),
              DropdownMenuItem(value: '전자제품', child: Text('전자제품')),
              DropdownMenuItem(value: '도서', child: Text('도서')),
              DropdownMenuItem(value: '의류', child: Text('의류')),
              DropdownMenuItem(value: '장난감', child: Text('장난감')),
              DropdownMenuItem(value: '생활용품', child: Text('생활용품')),
              DropdownMenuItem(value: '기타', child: Text('기타')),
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
            decoration: _buildInputDecoration(
              hintText: '나눔할 물품의 제목을 입력해주세요',
              counterText: '${_titleController.text.length}/100',
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
            decoration: _buildInputDecoration(
              hintText: '나눔할 물품에 대한 상세한 설명을 입력해주세요',
              counterText: '${_descriptionController.text.length}/1000',
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
            decoration: _buildInputDecoration(hintText: '상품 상태를 선택하세요'),
            value: _selectedCondition,
            items: const [
              DropdownMenuItem(value: '새상품', child: Text('새 상품')),
              DropdownMenuItem(value: '거의새것', child: Text('거의 새것')),
              DropdownMenuItem(value: '양호', child: Text('양호')),
              DropdownMenuItem(value: '사용감있음', child: Text('사용감 있음')),
            ],
            onChanged: (value) => setState(() => _selectedCondition = value),
            validator: (value) => value == null ? '상품 상태를 선택해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 6. 판매 가격
          Text(
            '판매 가격',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _priceController,
            enabled: !_isFreeSharing, // 무료나눔 체크 시 비활성화
            decoration: _buildInputDecoration(
              hintText: _isFreeSharing ? '무료나눔' : '숫자로만 입력 (예: 50000)',
            ),
            style: FigmaTextStyles().body2.copyWith(
              color: _isFreeSharing ? NewAppColor.neutral400 : NewAppColor.neutral900,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (!_isFreeSharing && (value == null || value.trim().isEmpty)) {
                return '판매 가격을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 12.h),

          // 무료나눔 체크박스
          Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: Checkbox(
                  value: _isFreeSharing,
                  onChanged: (value) {
                    setState(() {
                      _isFreeSharing = value ?? false;
                      if (_isFreeSharing) {
                        _priceController.clear(); // 무료나눔 체크 시 가격 초기화
                      }
                    });
                  },
                  activeColor: NewAppColor.primary600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isFreeSharing = !_isFreeSharing;
                    if (_isFreeSharing) {
                      _priceController.clear();
                    }
                  });
                },
                child: Text(
                  '무료 나눔',
                  style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 7. 거래 지역
          Text(
            '거래 지역',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              // 도/시 선택
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  hint: Text(
                    '도/시 선택',
                    style: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral400,
                    ),
                  ),
                  decoration: _buildInputDecoration(hintText: ''),
                  items: LocationData.getCities().map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(
                        city,
                        style: FigmaTextStyles().body2,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedDistrict = null; // 도/시 변경 시 시/군/구 초기화
                    });
                  },
                ),
              ),
              SizedBox(width: 8.w),
              // 시/군/구 선택
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  hint: Text(
                    '시/군/구 선택',
                    style: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral400,
                    ),
                  ),
                  decoration: _buildInputDecoration(hintText: ''),
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!).map((district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Text(
                              district,
                              style: FigmaTextStyles().body2,
                            ),
                          );
                        }).toList()
                      : [],
                  onChanged: _selectedProvince == null
                      ? null
                      : (value) {
                          setState(() {
                            _selectedDistrict = value;
                          });
                        },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // 택배 가능 체크박스
          Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: Checkbox(
                  value: _deliveryAvailable,
                  onChanged: (value) {
                    setState(() {
                      _deliveryAvailable = value ?? false;
                    });
                  },
                  activeColor: NewAppColor.primary600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _deliveryAvailable = !_deliveryAvailable;
                  });
                },
                child: Text(
                  '택배 가능',
                  style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 구매 시기 (선택)
          Text(
            '구매 시기 (선택)',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _purchaseDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: NewAppColor.primary600,
                        onPrimary: Colors.white,
                        onSurface: NewAppColor.neutral900,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _purchaseDate = date);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: NewAppColor.neutral100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _purchaseDate == null
                        ? '구매한 시기를 선택해주세요'
                        : '${_purchaseDate!.year}년 ${_purchaseDate!.month}월',
                    style: FigmaTextStyles().body2.copyWith(
                      color: _purchaseDate == null
                          ? NewAppColor.neutral400
                          : NewAppColor.neutral900,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: 20.sp,
                    color: NewAppColor.neutral600,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),

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
            decoration: _buildInputDecoration(
              hintText: '연락 가능한 전화번호를 입력해주세요',
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
            decoration: _buildInputDecoration(
              hintText: '이메일 주소를 입력해주세요 (선택사항)',
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
              '${_existingImageUrls.length + _selectedImages.length}/$maxCount',
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
              if ((_existingImageUrls.length + _selectedImages.length) < maxCount)
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
              // 기존 이미지들 (URL)
              ..._existingImageUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final imageUrl = entry.value;
                return Container(
                  width: 100.w,
                  height: 100.h,
                  margin: EdgeInsets.only(left: 8.w),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(
                          imageUrl,
                          width: 100.w,
                          height: 100.h,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ 이미지 로드 실패: $imageUrl, 에러: $error');
                            return Container(
                              color: Colors.grey[300],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 40.sp, color: Colors.grey),
                                  Text(
                                    '이미지 로드 실패',
                                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4.h,
                        right: 4.w,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _existingImageUrls.removeAt(index);
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
              // 새로 선택된 이미지들 (파일)
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
            decoration: _buildInputDecoration(
              hintText: '요청할 물품의 제목을 입력하세요',
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
                      decoration: _buildInputDecoration(
                        hintText: '구체적인 물품명을 입력하세요',
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
                      decoration: _buildInputDecoration(
                        hintText: '카테고리 선택',
                      ),
                      value: _selectedCategory,
                      items: const [
                        DropdownMenuItem(value: '가구', child: Text('가구')),
                        DropdownMenuItem(value: '전자제품', child: Text('전자제품')),
                        DropdownMenuItem(value: '도서', child: Text('도서')),
                        DropdownMenuItem(value: '의류', child: Text('의류')),
                        DropdownMenuItem(value: '장난감', child: Text('장난감')),
                        DropdownMenuItem(value: '생활용품', child: Text('생활용품')),
                        DropdownMenuItem(value: '기타', child: Text('기타')),
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
                      decoration: _buildInputDecoration(
                        hintText: '1',
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
                      decoration: _buildInputDecoration(
                        hintText: '보통',
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
                      decoration: _buildInputDecoration(
                        hintText: '필요일을 선택해주세요',
                        prefixIcon: const Icon(Icons.calendar_today),
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
                      decoration: _buildInputDecoration(
                        hintText: '예: 50,000원',
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

          // 5. 거래 지역
          Text(
            '거래 지역',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              // 도/시 선택
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  hint: Text(
                    '도/시 선택',
                    style: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral400,
                    ),
                  ),
                  decoration: _buildInputDecoration(hintText: ''),
                  items: LocationData.getCities().map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(
                        city,
                        style: FigmaTextStyles().body2,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedDistrict = null; // 도/시 변경 시 시/군/구 초기화
                    });
                  },
                ),
              ),
              SizedBox(width: 8.w),
              // 시/군/구 선택
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  hint: Text(
                    '시/군/구 선택',
                    style: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral400,
                    ),
                  ),
                  decoration: _buildInputDecoration(hintText: ''),
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!).map((district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Text(
                              district,
                              style: FigmaTextStyles().body2,
                            ),
                          );
                        }).toList()
                      : [],
                  onChanged: _selectedProvince == null
                      ? null
                      : (value) {
                          setState(() {
                            _selectedDistrict = value;
                          });
                        },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // 택배 가능 체크박스
          Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: Checkbox(
                  value: _deliveryAvailable,
                  onChanged: (value) {
                    setState(() {
                      _deliveryAvailable = value ?? false;
                    });
                  },
                  activeColor: NewAppColor.primary600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _deliveryAvailable = !_deliveryAvailable;
                  });
                },
                child: Text(
                  '택배 가능',
                  style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral900,
                  ),
                ),
              ),
            ],
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
            decoration: _buildInputDecoration(
              hintText: '물품이 필요한 이유를 간단히 설명해주세요',
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
            decoration: _buildInputDecoration(
              hintText: '원하는 물품의 상세 조건이나 상태를 설명해주세요',
              counterText: '${_descriptionController.text.length}/1000',
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
                      decoration: _buildInputDecoration(
                        hintText: '010-1234-5678',
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
                      decoration: _buildInputDecoration(
                        hintText: 'example@email.com',
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
            decoration: _buildInputDecoration(
              hintText: '예: 청년부 담당 전도사 모집',
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
                      decoration: _buildInputDecoration(
                        hintText: '직책 선택',
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
                      decoration: _buildInputDecoration(
                        hintText: '고용 형태',
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
                      decoration: _buildInputDecoration(
                        hintText: '예: 월 300만원, 협의',
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
                      ),
                      style: FigmaTextStyles().body2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 3-1. 근무 지역
          Text(
            '근무 지역',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              // 도/시 선택
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  hint: Text(
                    '도/시 선택',
                    style: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral400,
                    ),
                  ),
                  decoration: _buildInputDecoration(hintText: ''),
                  items: LocationData.getCities().map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(
                        city,
                        style: FigmaTextStyles().body2,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedDistrict = null; // 도/시 변경 시 시/군/구 초기화
                    });
                  },
                ),
              ),
              SizedBox(width: 8.w),
              // 시/군/구 선택
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  hint: Text(
                    '시/군/구 선택',
                    style: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral400,
                    ),
                  ),
                  decoration: _buildInputDecoration(hintText: ''),
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!).map((district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Text(
                              district,
                              style: FigmaTextStyles().body2,
                            ),
                          );
                        }).toList()
                      : [],
                  onChanged: _selectedProvince == null
                      ? null
                      : (value) {
                          setState(() {
                            _selectedDistrict = value;
                          });
                        },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // 택배 가능 체크박스
          Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: Checkbox(
                  value: _deliveryAvailable,
                  onChanged: (value) {
                    setState(() {
                      _deliveryAvailable = value ?? false;
                    });
                  },
                  activeColor: NewAppColor.primary600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _deliveryAvailable = !_deliveryAvailable;
                  });
                },
                child: Text(
                  '택배 가능',
                  style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral900,
                  ),
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
            decoration: _buildInputDecoration(
              hintText: '지원 마감일을 선택해주세요',
              prefixIcon: const Icon(Icons.calendar_today),
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
            decoration: _buildInputDecoration(
              hintText: '담당하게 될 업무와 역할을 자세히 설명해주세요',
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
            decoration: _buildInputDecoration(
              hintText: '예: 신학대 졸업, 목사 안수, 청년 사역 경험',
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
            decoration: _buildInputDecoration(
              hintText: '예: 청년 사역 경험, 찬양 가능',
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
            decoration: _buildInputDecoration(
              hintText: '예: 4대보험, 연차, 숙소 제공',
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
                      decoration: _buildInputDecoration(
                        hintText: '010-1234-5678',
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
                      decoration: _buildInputDecoration(
                        hintText: 'example@email.com',
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
            decoration: _buildInputDecoration(
              hintText: '예: 주일예배 피아니스트 모집',
              counterText: '${_titleController.text.length}/100',
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
            decoration: _buildInputDecoration(
              hintText: '행사 유형 선택',
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
            decoration: _buildInputDecoration(
              hintText: '팀 형태 선택',
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
                      decoration: _buildInputDecoration(
                        hintText: '행사 날짜를 선택해주세요',
                        prefixIcon: const Icon(Icons.calendar_today),
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
                      decoration: _buildInputDecoration(
                        hintText: '예: 매주 토요일 오후 2시',
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 5. 지역
          Text(
            '지역 *',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: _buildInputDecoration(
                    hintText: '도/시 선택',
                  ),
                  items: LocationData.getCities().map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedDistrict = null;
                    });
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: _buildInputDecoration(
                    hintText: '시/군/구 선택',
                  ),
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!).map((district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          );
                        }).toList()
                      : [],
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 상세 주소
          Text(
            '상세 주소',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _locationController,
            decoration: _buildInputDecoration(
              hintText: '예: ○○교회, ○○센터 2층',
              prefixIcon: const Icon(Icons.location_on),
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
            decoration: _buildInputDecoration(
              hintText: '행사 내용, 분위기, 특별한 요구사항 등을 자세히 설명해주세요',
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
            decoration: _buildInputDecoration(
              hintText: '예: 3년 이상 연주 경험, 악보 시창 가능',
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
            decoration: _buildInputDecoration(
              hintText: '예: 회당 5만원, 봉사, 협의',
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
                      decoration: _buildInputDecoration(
                        hintText: '010-1234-5678',
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
                      decoration: _buildInputDecoration(
                        hintText: 'example@email.com',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '지원서 제목 *',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _titleController,
                      decoration: _buildInputDecoration(
                        hintText: '지원서 제목을 입력하세요',
                        counterText: '${_titleController.text.length}/100',
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
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 활동 팀명 (선택)',
                      style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _teamNameController,
                      decoration: _buildInputDecoration(
                        hintText: '팀명을 입력하세요',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 2. 팀 형태 *
          Text(
            '팀 형태 *',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            decoration: _buildInputDecoration(
              hintText: '팀 형태 선택',
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
          Text(
            '연주 경력',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _experienceController,
            decoration: _buildInputDecoration(
              hintText: '찬양팀, 워십팀, 밴드 등 경력을 쓰면 좋은 결과 생길 수 있습니다.',
            ),
            maxLines: 5,
          ),
          SizedBox(height: 16.h),

          // 4. 활동 가능 지역 (복수 선택 가능)
          Text(
            '활동 가능 지역 (복수 선택 가능)',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral700,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: _buildInputDecoration(
                    hintText: '도/시 선택',
                  ),
                  hint: const Text('도/시 선택'),
                  items: LocationData.getCities().map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedDistrict = null;
                    });
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: _buildInputDecoration(
                    hintText: '시/군/구 선택',
                  ),
                  hint: const Text('시/군/구 선택'),
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!).map((district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          );
                        }).toList()
                      : [],
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedProvince != null && _selectedDistrict != null) {
                  final location = '$_selectedProvince $_selectedDistrict';
                  if (!_preferredLocations.contains(location)) {
                    setState(() {
                      _preferredLocations.add(location);
                      _selectedProvince = null;
                      _selectedDistrict = null;
                    });
                  } else {
                    AppToast.show(context, '이미 추가된 지역입니다', type: ToastType.warning);
                  }
                } else {
                  AppToast.show(context, '도/시와 시/군/구를 선택해주세요', type: ToastType.warning);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: NewAppColor.primary500,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: Text(
                '추가',
                style: FigmaTextStyles().body2.copyWith(color: Colors.white),
              ),
            ),
          ),

          // 선택된 지역 목록
          if (_preferredLocations.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _preferredLocations.map((location) {
                return Chip(
                  label: Text(location),
                  deleteIcon: Icon(Icons.close, size: 18.r),
                  onDeleted: () {
                    setState(() {
                      _preferredLocations.remove(location);
                    });
                  },
                  backgroundColor: NewAppColor.primary100,
                  labelStyle: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.primary700,
                      ),
                );
              }).toList(),
            ),
          ],
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
          Text(
            '활동 가능 시간대',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            decoration: _buildInputDecoration(
              hintText: '활동 가능 시간대',
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
          Text(
            'YouTube 링크 (선택)',
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _youtubeController,
            decoration: _buildInputDecoration(
              hintText: 'YouTube 연주 영상 주소를 입력하세요',
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
                      decoration: _buildInputDecoration(
                        hintText: '010-1234-5678',
                      ),
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
                      decoration: _buildInputDecoration(
                        hintText: 'example@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
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
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 행사 이미지 (0/12)
          _buildImagePickerWithLabel(
            label: '행사 이미지',
            required: false,
            maxCount: 12,
          ),
          SizedBox(height: 24.h),

          // 카테고리 *
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
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
          SizedBox(height: 24.h),

          // 제목 *
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
              hintText: '행사 소식의 제목을 입력하세요',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              counterText: '${_titleController.text.length}/100',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
          SizedBox(height: 24.h),

          // 내용 *
          Text(
            '내용 *',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: '행사 소식의 상세 내용을 입력하세요',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              counterText: '${_descriptionController.text.length}/1000',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
          SizedBox(height: 24.h),

          // 우선순위 *
          Text(
            '우선순위 *',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: '일반',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            value: _selectedPriority,
            items: const [
              DropdownMenuItem(value: 'urgent', child: Text('긴급')),
              DropdownMenuItem(value: 'important', child: Text('중요')),
              DropdownMenuItem(value: 'normal', child: Text('일반')),
            ],
            onChanged: (value) => setState(() => _selectedPriority = value!),
          ),
          SizedBox(height: 24.h),

          // 행사일
          Text(
            '행사일',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _newsEventDateController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: '날짜를 선택해주세요',
              prefixIcon: Icon(Icons.calendar_today, size: 20.r, color: NewAppColor.neutral600),
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
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
                  _newsEventDateController.text = date.toString().split(' ')[0];
                });
              }
            },
          ),
          SizedBox(height: 24.h),

          // 행사 시간
          Text(
            '행사 시간',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _newsEventTimeController,
            decoration: InputDecoration(
              hintText: '-- --:--',
              suffixIcon: Icon(Icons.access_time, size: 20.r, color: NewAppColor.neutral600),
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 24.h),

          // 지역
          Text(
            '지역',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: InputDecoration(
                    hintText: '도/시 선택',
                    filled: true,
                    fillColor: NewAppColor.neutral100,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  items: LocationData.getCities().map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedDistrict = null;
                    });
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: InputDecoration(
                    hintText: '시/군/구 선택',
                    filled: true,
                    fillColor: NewAppColor.neutral100,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!).map((district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          );
                        }).toList()
                      : [],
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 상세 주소
          Text(
            '상세 주소',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: '예: ○○교회, ○○센터 2층',
              counterText: '${_locationController.text.length}/100',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            maxLength: 100,
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 24.h),

          // 주최자/부서 *
          Text(
            '주최자/부서 *',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _organizerController,
            decoration: InputDecoration(
              hintText: '행사를 주최하는 부서나 담당자',
              counterText: '${_organizerController.text.length}/50',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
          SizedBox(height: 24.h),

          // 대상
          Text(
            '대상',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _targetAudienceController,
            decoration: InputDecoration(
              hintText: '예: 전체, 청년부, 장년부 등',
              counterText: '${_targetAudienceController.text.length}/50',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            maxLength: 50,
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 24.h),

          // 참가비
          Text(
            '참가비',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _participationFeeController,
            decoration: InputDecoration(
              hintText: '예: 무료, 10,000원 등',
              counterText: '${_participationFeeController.text.length}/50',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            maxLength: 50,
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 24.h),

          // 담당자
          Text(
            '담당자',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _contactPersonController,
            decoration: InputDecoration(
              hintText: '문의 담당자 이름',
              counterText: '${_contactPersonController.text.length}/50',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            maxLength: 50,
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 24.h),

          // 연락처
          Text(
            '연락처',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _contactController,
            decoration: InputDecoration(
              hintText: '010-0000-0000',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 24.h),

          // 이메일
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
              hintText: 'contact@church.com',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  /// 공통 InputDecoration (보더 없는 스타일)
  InputDecoration _buildInputDecoration({
    required String hintText,
    String? counterText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: FigmaTextStyles().body2.copyWith(
        color: NewAppColor.neutral400,
      ),
      counterText: counterText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: NewAppColor.neutral100,
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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

  /// 이미지 압축 (최대 1MB로)
  Future<Uint8List> _compressImage(File imageFile) async {
    // 원본 이미지 읽기
    final bytes = await imageFile.readAsBytes();
    final originalSize = bytes.length;

    print('📊 원본 이미지 크기: ${(originalSize / 1024 / 1024).toStringAsFixed(2)}MB');

    // 1MB 이하면 압축하지 않음
    if (originalSize <= 1024 * 1024) {
      print('✅ 압축 불필요 (1MB 이하)');
      return bytes;
    }

    // 이미지 디코딩
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // 이미지 크기 계산 (최대 1920px)
    int targetWidth = image.width;
    int targetHeight = image.height;
    const maxSize = 1920;

    if (image.width > maxSize || image.height > maxSize) {
      if (image.width > image.height) {
        targetWidth = maxSize;
        targetHeight = (image.height * maxSize / image.width).round();
      } else {
        targetHeight = maxSize;
        targetWidth = (image.width * maxSize / image.height).round();
      }
      print('📐 이미지 리사이즈: ${image.width}x${image.height} → ${targetWidth}x${targetHeight}');
    }

    // 이미지 리사이즈
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      paint,
    );

    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(targetWidth, targetHeight);

    // JPEG로 인코딩 (품질 85%)
    final byteData = await resizedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final compressedBytes = byteData!.buffer.asUint8List();

    final compressedSize = compressedBytes.length;
    print('📊 압축 후 크기: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)}MB (${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}% 감소)');

    return compressedBytes;
  }

  /// 이미지 업로드 (Supabase Storage)
  Future<List<String>> _uploadImages() async {
    print('📸 이미지 업로드 시작: ${_selectedImages.length}장');

    if (_selectedImages.isEmpty) {
      return [];
    }

    final List<String> imageUrls = [];
    final supabase = SupabaseService().client;

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        final xFile = _selectedImages[i];
        final imageFile = File(xFile.path);

        // 파일명 생성: timestamp_random.png (압축 후 PNG)
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final random = (DateTime.now().microsecond % 10000).toString().padLeft(4, '0');
        final fileName = '${timestamp}_$random.png';

        print('📤 이미지 업로드 중 (${i + 1}/${_selectedImages.length}): $fileName');

        // 이미지 압축
        final compressedBytes = await _compressImage(imageFile);

        // Supabase Storage에 업로드
        final path = await supabase.storage
            .from('community-images')
            .uploadBinary(
              fileName,
              compressedBytes,
            );

        // Public URL 생성
        final publicUrl = supabase.storage
            .from('community-images')
            .getPublicUrl(fileName);

        imageUrls.add(publicUrl);
        print('✅ 업로드 완료: $publicUrl');
      }

      print('📸 이미지 업로드 완료: ${imageUrls.length}장');
      return imageUrls;
    } catch (e) {
      print('❌ 이미지 업로드 실패: $e');
      AppToast.show(context, '이미지 업로드에 실패했습니다: $e', type: ToastType.error);
      return [];
    }
  }

  /// 무료나눔/물품판매 제출
  Future<bool> _submitSharing(List<String> imageUrls) async {
    final response = await _communityService.createSharingItem(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      condition: _selectedCondition!,
      province: _selectedProvince,
      district: _selectedDistrict,
      deliveryAvailable: _deliveryAvailable,
      images: imageUrls,
      isFree: _isFreeSharing,
      price: _isFreeSharing ? null : int.tryParse(_priceController.text),
      purchaseDate: _purchaseDate,
      contactPhone: _contactController.text.trim(),
      contactEmail: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
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
      quantity: int.tryParse(_quantityController.text) ?? 1,
      reason: _reasonController.text.trim(),
      neededDate: _neededDateController.text.trim().isEmpty
          ? null
          : _neededDateController.text.trim(),
      province: _selectedProvince,
      district: _selectedDistrict,
      deliveryAvailable: _deliveryAvailable,
      priceRange: _priceRangeController.text.trim(),
      urgency: _selectedUrgency,
      images: imageUrls,
      contactPhone: _contactController.text.trim(),
      contactEmail: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
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
      province: _selectedProvince,
      district: _selectedDistrict,
      deliveryAvailable: _deliveryAvailable,
      deadline: _deadlineController.text.trim().isEmpty
          ? null
          : _deadlineController.text.trim(),
      contactPhone: _contactController.text.trim(),
      contactEmail: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
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
