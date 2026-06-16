import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/community_models.dart';
import 'package:smart_yoram_app/services/community_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/services/supabase_service.dart';
import 'package:smart_yoram_app/screens/community/community_list_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smart_yoram_app/components/index.dart' hide IconButton;
import 'package:smart_yoram_app/utils/location_data.dart';
import 'package:flutter/services.dart';
import 'package:smart_yoram_app/widgets/custom_date_picker.dart';

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
  final TextEditingController _purchaseDateController =
      TextEditingController(); // 구매 시기 (텍스트)

  // 물품요청 전용
  String _selectedUrgency = 'normal'; // low, normal, high
  String? _rewardType; // free, exchange, payment
  final TextEditingController _rewardAmountController = TextEditingController();
  final TextEditingController _exchangeItemController = TextEditingController();

  // 사역자모집 전용
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _churchIntroController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _jobTypeController = TextEditingController();
  String? _selectedEmploymentType; // full-time, part-time, contract, volunteer
  final TextEditingController _salaryController = TextEditingController();
  bool _isSalaryNegotiable = false; // 급여 협의 여부
  final TextEditingController _qualificationsController =
      TextEditingController();
  final TextEditingController _preferredQualificationsController =
      TextEditingController();
  final TextEditingController _benefitsController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  // 행사팀모집 전용
  String?
      _selectedRecruitmentType; // new_member, substitute, project, permanent
  String? _selectedEventType; // sunday-service, wednesday-service, etc.
  String? _selectedTeamType; // solo, praise-team, worship-team, etc.
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _rehearsalTimeController =
      TextEditingController();
  final TextEditingController _worshipTypeController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _compensationController = TextEditingController();

  // 행사팀지원 전용
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();
  String? _portfolioFileUrl; // 포트폴리오 파일 URL
  List<String> _preferredLocations = [];
  List<String> _availableDays = [];
  final TextEditingController _availableTimeController =
      TextEditingController();
  final TextEditingController _introductionController = TextEditingController();
  String? _selectedTimeSlot; // 활동 가능 시간대
  final TextEditingController _youtubeController =
      TextEditingController(); // YouTube 링크

  // 교회소식 전용
  String? _selectedNewsCategory; // worship, event, retreat, mission, etc.
  String _selectedPriority = 'normal'; // urgent, important, normal
  final TextEditingController _newsEventDateController =
      TextEditingController();
  final TextEditingController _newsEventTimeController =
      TextEditingController();
  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _targetAudienceController =
      TextEditingController();
  final TextEditingController _participationFeeController =
      TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();

  bool _isLoading = false;
  List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = []; // 기존 이미지 URL 목록
  String _selectedStatus = 'active';
  bool _isFreeSharing = false; // 무료나눔 체크박스 상태

  @override
  void initState() {
    super.initState();
    print(
        '🔍 initState 호출됨 - existingPost: ${widget.existingPost != null ? "있음" : "없음"}');
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
    _purchaseDateController.dispose();
    _rewardAmountController.dispose();
    _exchangeItemController.dispose();
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
      final tableName =
          post['tableName'] as String? ?? post['table'] as String?;

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
        print(
            '📸 기존 이미지 로드됨: ${_existingImageUrls.length}장 - $_existingImageUrls');
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
        // 구매시기 로드
        if (post['purchase_date'] != null) {
          _purchaseDateController.text = post['purchase_date'].toString();
        }
        _contactController.text =
            post['contact_info'] ?? post['contact_phone'] ?? '';
        _emailController.text = post['contact_email'] ?? '';
      } else if (tableName == 'community_requests') {
        // 'none'을 'free'로 변환
        final rawRewardType = post['reward_type'];
        _rewardType = rawRewardType == 'none' ? 'free' : rawRewardType;
        _rewardAmountController.text = post['reward_amount']?.toString() ?? '';
        _exchangeItemController.text = post['exchange_item'] ?? '';
        _selectedUrgency = post['urgency'] ?? 'normal';
        _contactController.text =
            post['contact_info'] ?? post['contact_phone'] ?? '';
        _emailController.text = post['contact_email'] ?? '';
      } else if (tableName == 'job_posts') {
        _companyController.text = post['company'] ?? '';
        _churchIntroController.text = post['church_intro'] ?? '';
        _positionController.text = post['position'] ?? '';
        _jobTypeController.text = post['job_type'] ?? '';
        _selectedEmploymentType = post['employment_type'];
        final salary = post['salary'] ?? '';
        if (salary == '협의' || salary.toLowerCase() == 'negotiable') {
          _isSalaryNegotiable = true;
          _salaryController.text = '협의';
        } else {
          _salaryController.text = salary;
        }
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
      // 구매시기 로드
      if (post.purchaseDate != null) {
        _purchaseDateController.text = post.formattedPurchaseDate;
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
      print(
          '📸 기존 이미지 로드됨 (SharingItem): ${_existingImageUrls.length}장 - $_existingImageUrls');
    } else if (post is RequestItem) {
      _titleController.text = post.title;
      _descriptionController.text = post.description ?? '';
      _locationController.text = post.location ?? '';
      // 'none'을 'free'로 변환
      final rawRewardType = post.rewardType;
      _rewardType = rawRewardType == 'none' ? 'free' : rawRewardType;
      _rewardAmountController.text = post.rewardAmount?.toString() ?? '';
      // exchangeItem 필드가 모델에 있다면 로드
      // _exchangeItemController.text = post.exchangeItem ?? '';
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
        print(
            '📸 기존 이미지 로드됨 (RequestItem): ${_existingImageUrls.length}장 - $_existingImageUrls');
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
      final salary = post.salary ?? '';
      if (salary == '협의' || salary.toLowerCase() == 'negotiable') {
        _isSalaryNegotiable = true;
        _salaryController.text = '협의';
      } else {
        _salaryController.text = salary;
      }
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

      // 위치 정보 로드
      _selectedProvince = post.province;
      _selectedDistrict = post.district;
      _locationController.text = post.location;

      _selectedRecruitmentType = post.recruitmentType;
      _worshipTypeController.text = post.worshipType ?? '';
      _scheduleController.text = post.schedule ?? '';
      _requirementsController.text = post.requirements ?? '';
      _compensationController.text = post.benefits ?? '';
      _contactController.text = post.contactPhone ?? '';
      _emailController.text = post.contactEmail ?? '';
    } else if (post is MusicTeamSeeker) {
      _titleController.text = post.title;
      _descriptionController.text = post.description ?? '';
      _nameController.text = post.name ?? '';
      _teamNameController.text = post.teamName ?? '';
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
        print(
            '📸 기존 이미지 로드됨 (ChurchNews): ${_existingImageUrls.length}장 - $_existingImageUrls');
      }
    }

    setState(() {});
  }

  /// 필수 필드가 모두 채워졌는지 확인
  bool _isFormValid() {
    // 실제 타입 결정
    CommunityListType actualType = widget.type;

    if (widget.type == CommunityListType.myPosts ||
        widget.type == CommunityListType.myFavorites) {
      if (widget.existingPost is Map<String, dynamic>) {
        final post = widget.existingPost as Map<String, dynamic>;
        final tableName =
            post['tableName'] as String? ?? post['table'] as String?;
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
        // 필수: 제목, 설명, 카테고리, 상태, 위치 정보
        // 위치 정보: 지역 선택 OR 택배 가능 체크 중 하나 이상 필수
        // 판매인 경우(무료나눔 아닌 경우) 가격도 필수
        final basicValid = _titleController.text.trim().isNotEmpty &&
            _descriptionController.text.trim().isNotEmpty &&
            _selectedCategory != null &&
            _selectedCondition != null &&
            (_selectedProvince != null || _deliveryAvailable);

        // 무료나눔이 아니면 가격도 필수
        if (!_isFreeSharing) {
          return basicValid && _priceController.text.trim().isNotEmpty;
        }

        return basicValid;

      case CommunityListType.itemRequest:
        // 필수: 제목, 카테고리, 거래 지역 (지역 OR 택배), 보상 정보, 상세 설명
        final titleValid = _titleController.text.trim().isNotEmpty;
        final categoryValid = _selectedCategory != null;
        final locationValid = (_selectedProvince != null || _deliveryAvailable);
        final rewardValid = _rewardType != null;
        final descriptionValid = _descriptionController.text.trim().isNotEmpty;

        print('🔍 물품요청 등록 조건 체크:');
        print('  제목: $titleValid (${_titleController.text})');
        print('  카테고리: $categoryValid ($_selectedCategory)');
        print('  거래지역: $locationValid (도/시: $_selectedProvince, 택배: $_deliveryAvailable)');
        print('  보상정보: $rewardValid ($_rewardType)');
        print('  상세설명: $descriptionValid (${_descriptionController.text.length}자)');

        return titleValid && categoryValid && locationValid && rewardValid && descriptionValid;

      case CommunityListType.jobPosting:
        // 필수: 제목, 설명, 교회/기관명, 직책, 고용형태, 급여(또는 협의), 마감일
        // 연락처는 선택사항 (개인정보 보호)
        return _titleController.text.trim().isNotEmpty &&
            _descriptionController.text.trim().isNotEmpty &&
            _companyController.text.trim().isNotEmpty &&
            _selectedCategory != null &&
            _selectedEmploymentType != null &&
            (_salaryController.text.trim().isNotEmpty || _isSalaryNegotiable) &&
            _deadlineController.text.trim().isNotEmpty;

      case CommunityListType.musicTeamRecruit:
        // 필수: 제목, 설명, 행사 유형, 팀 형태, 지역
        final titleValid = _titleController.text.trim().isNotEmpty;
        final descValid = _descriptionController.text.trim().isNotEmpty;
        final eventTypeValid = _selectedEventType != null;
        final teamTypeValid = _selectedTeamType != null;
        final locationValid = _locationController.text.trim().isNotEmpty;

        print('🔍 행사팀 모집 필수 필드 검증:');
        print('  제목: $titleValid (${_titleController.text.trim()})');
        print('  설명: $descValid (길이: ${_descriptionController.text.trim().length})');
        print('  행사유형: $eventTypeValid ($_selectedEventType)');
        print('  팀형태: $teamTypeValid ($_selectedTeamType)');
        print('  위치: $locationValid (${_locationController.text.trim()})');
        print('  → 전체 유효성: ${titleValid && descValid && eventTypeValid && teamTypeValid && locationValid}');

        return titleValid && descValid && eventTypeValid && teamTypeValid && locationValid;

      case CommunityListType.musicTeamSeeking:
        // 필수: 제목, 팀 형태
        return _titleController.text.trim().isNotEmpty &&
            _selectedTeamType != null;

      case CommunityListType.churchNews:
        // 필수: 제목, 설명, 행사일
        return _titleController.text.trim().isNotEmpty &&
            _descriptionController.text.trim().isNotEmpty &&
            _newsEventDateController.text.trim().isNotEmpty;

      default:
        return true;
    }
  }

  /// 날짜 선택 다이얼로그 테마 builder
  Widget _buildDatePickerTheme(BuildContext context, Widget? child) {
    return Transform.translate(
      offset: Offset(0, -60.h), // 상단을 위로 이동시켜 잘라내기
      child: ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 0.82, // 적절한 높이로 조정
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF2196F3),
                onPrimary: Colors.white,
                onSurface: const Color(0xFF333333),
                surface: Colors.white,
              ),
              dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith((states) {
                    // 취소 버튼 완전히 숨기기
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.transparent;
                    }
                    return Colors.white;
                  }),
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    // 취소 버튼 완전히 숨기기
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.transparent;
                    }
                    return const Color(0xFF2196F3);
                  }),
                  textStyle: MaterialStateProperty.all(
                    FigmaTextStyles().button2.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(horizontal: 48.w, vertical: 14.h),
                  ),
                  minimumSize: MaterialStateProperty.resolveWith((states) {
                    // 취소 버튼 크기 0으로
                    if (states.contains(MaterialState.disabled)) {
                      return Size.zero;
                    }
                    return Size(140.w, 48.h);
                  }),
                  overlayColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.transparent;
                    }
                    return null;
                  }),
                ),
              ),
              dialogTheme: DialogThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                elevation: 4,
                backgroundColor: Colors.white,
              ),
              textTheme: TextTheme(
                // 년월 표시 텍스트 (July 2019)
                headlineMedium: FigmaTextStyles().headline3.copyWith(
                      color: const Color(0xFF333333),
                      fontWeight: FontWeight.w700,
                      fontSize: 24.sp,
                    ),
                labelLarge: const TextStyle(
                  fontSize: 0, // "날짜 선택" 텍스트 숨기기
                  height: 0,
                ),
              ),
              datePickerTheme: DatePickerThemeData(
                backgroundColor: Colors.white,
                elevation: 0,
                // 헤더 완전히 제거
                headerBackgroundColor: Colors.white,
                headerForegroundColor: Colors.white,
                headerHeadlineStyle: const TextStyle(
                  fontSize: 0,
                  height: 0,
                  color: Colors.transparent,
                ),
                headerHelpStyle: const TextStyle(
                  fontSize: 0,
                  height: 0,
                  color: Colors.transparent,
                ),
                // 상단 여백 최소화
                rangePickerHeaderHeadlineStyle:
                    const TextStyle(fontSize: 0, height: 0),
                rangePickerHeaderHelpStyle:
                    const TextStyle(fontSize: 0, height: 0),
                // 요일 스타일 (M T W T F S S)
                weekdayStyle: FigmaTextStyles().caption1.copyWith(
                      color: const Color(0xFF999999),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      fontSize: 13.sp,
                    ),
                // 날짜 숫자 스타일
                dayStyle: FigmaTextStyles().body2.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 15.sp,
                    ),
                // 년 선택 스타일
                yearStyle: FigmaTextStyles().headline4.copyWith(
                      color: const Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                    ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                // 선택된 날짜 - 파란색 원형
                dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xFF2196F3);
                  }
                  return Colors.transparent;
                }),
                dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  if (states.contains(MaterialState.disabled)) {
                    return const Color(0xFFDDDDDD);
                  }
                  return const Color(0xFF333333);
                }),
                dayOverlayColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.hovered)) {
                    return const Color(0xFF2196F3).withOpacity(0.1);
                  }
                  return null;
                }),
                // 날짜를 원형으로
                dayShape: MaterialStateProperty.all(
                  const CircleBorder(),
                ),
                // 오늘 날짜 스타일
                todayBorder: BorderSide.none,
                todayForegroundColor:
                    MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  return const Color(0xFF64B5F6); // 연한 파란색
                }),
                todayBackgroundColor:
                    MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xFF2196F3);
                  }
                  return Colors.transparent;
                }),
              ),
            ),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Stack(
                children: [
                  child!,
                  // 왼쪽 취소 버튼 영역 가리기
                  Positioned(
                    bottom: 16.h,
                    left: 16.w,
                    child: Container(
                      width: 160.w,
                      height: 48.h,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 필수 레이블 생성 (빨간 * 포함)
  Widget _buildRequiredLabel(String text) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          TextSpan(
            text: ' *',
            style: FigmaTextStyles().body2.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  /// 타입별 작성 가이드 보여주기
  void _showGuide() {
    // 실제 타입 결정
    CommunityListType actualType = widget.type;

    if (widget.type == CommunityListType.myPosts ||
        widget.type == CommunityListType.myFavorites) {
      if (widget.existingPost is Map<String, dynamic>) {
        final post = widget.existingPost as Map<String, dynamic>;
        final tableName =
            post['tableName'] as String? ?? post['table'] as String?;
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

    String title = '';
    List<String> tips = [];

    switch (actualType) {
      case CommunityListType.freeSharing:
      case CommunityListType.itemSale:
        title = '물품 판매 작성 가이드';
        tips = [
          '✓ 상품 사진을 여러 장 첨부하면 신뢰도가 높아집니다',
          '✓ 무료 나눔인 경우 가격을 0원으로 설정해주세요',
          '✓ 정확한 가격과 상품 상태를 입력해주세요',
          '✓ 구매 시기를 입력하면 신뢰도가 높아집니다',
          '✓ 거래 희망 지역과 택배 가능 여부를 체크해주세요',
          '✓ 연락처는 정확하게 입력해주세요',
        ];
        break;
      case CommunityListType.itemRequest:
        title = '물품 요청 작성 가이드';
        tips = [
          '✓ 필요한 물품을 구체적으로 설명해주세요',
          '✓ 거래 지역을 선택하거나 택배 가능 여부를 선택해주세요',
          '✓ 보상 방식을 명확히 선택해주세요',
          '✓ 상세 설명에 원하는 물품의 조건을 구체적으로 적어주세요',
        ];
        break;
      case CommunityListType.jobPosting:
        title = '사역자 모집 작성 가이드';
        tips = [
          '✓ 모집 제목을 명확하게 작성해주세요',
          '✓ 교회/기관명과 직책을 정확히 입력해주세요',
          '✓ 상세 내용에 교회 소개, 업무 내용, 자격 요건, 복리후생을 포함해주세요',
          '✓ 급여는 투명하게 공개하거나 협의로 설정해주세요',
          '✓ 지원 마감일을 정확히 입력해주세요',
        ];
        break;
      case CommunityListType.musicTeamRecruit:
        title = '행사팀 모집 작성 가이드';
        tips = [
          '✓ 행사 날짜와 리허설 일정을 명확히 입력해주세요',
          '✓ 필요한 악기/파트를 구체적으로 선택해주세요',
          '✓ 예배 스타일과 분위기를 설명해주세요',
          '✓ 사례비나 교통비 지원 여부를 명시해주세요',
          '✓ 연습 및 예배 시간대를 상세히 작성해주세요',
        ];
        break;
      case CommunityListType.musicTeamSeeking:
        title = '행사팀 지원 작성 가이드';
        tips = [
          '✓ 지원서 제목을 명확하게 작성해주세요 (필수)',
          '✓ 원하는 팀 형태를 선택해주세요 (필수)',
          '✓ 경력과 경험을 작성하면 신뢰도가 높아집니다',
          '✓ 포트폴리오 파일이나 링크를 첨부해주세요',
          '✓ 가능한 지역과 요일을 명확히 선택해주세요',
        ];
        break;
      case CommunityListType.churchNews:
        title = '행사 소식 작성 가이드';
        tips = [
          '✓ 행사 일시와 장소를 명확히 입력해주세요',
          '✓ 행사의 목적과 내용을 상세히 작성해주세요',
          '✓ 참가 신청 방법이 있다면 명시해주세요',
          '✓ 사진이나 포스터를 첨부하면 좋습니다',
        ];
        break;
      default:
        title = '작성 가이드';
        tips = ['게시글을 작성해주세요'];
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: NewAppColor.skyPrimary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    title,
                    style: FigmaTextStyles().headline4.copyWith(
                          color: NewAppColor.neutral900,
                        ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              ...tips.map((tip) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      tip,
                      style: FigmaTextStyles().body2.copyWith(
                            color: NewAppColor.neutral700,
                            height: 1.5,
                          ),
                    ),
                  )),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NewAppColor.skyPrimary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    '확인',
                    style: FigmaTextStyles().button1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 타입별 제목 반환
  String _getTitleByType() {
    // 수정 모드인 경우
    if (widget.existingPost != null) {
      return '수정하기';
    }

    // 실제 타입 결정 (myPosts, myFavorites 등에서 작성하는 경우)
    CommunityListType actualType = widget.type;

    if (widget.type == CommunityListType.myPosts ||
        widget.type == CommunityListType.myFavorites) {
      // existingPost가 Map인 경우 tableName 정보로 타입 판단
      if (widget.existingPost is Map<String, dynamic>) {
        final post = widget.existingPost as Map<String, dynamic>;
        final tableName =
            post['tableName'] as String? ?? post['table'] as String?;
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

    // 타입별 제목
    switch (actualType) {
      case CommunityListType.freeSharing:
      case CommunityListType.itemSale:
        return '물품 판매 글쓰기';
      case CommunityListType.itemRequest:
        return '물품 요청 글쓰기';
      case CommunityListType.jobPosting:
        return '사역자 모집 글쓰기';
      case CommunityListType.musicTeamRecruit:
        return '행사팀 모집 글쓰기';
      case CommunityListType.musicTeamSeeking:
        return '행사팀 지원 글쓰기';
      case CommunityListType.churchNews:
        return '행사 소식 글쓰기';
      default:
        return '글쓰기';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTitleByType(),
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.info,
                color: NewAppColor.textMuted, size: 22.sp),
            onPressed: _showGuide,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: NewAppColor.borderSoft,
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
                    SizedBox(height: 120.h),
                  ],
                ),
              ),
            ),
      floatingActionButton: _isLoading
          ? null
          : Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: FloatingActionButton.extended(
                onPressed: _isFormValid() ? _submit : null,
                backgroundColor: _isFormValid()
                    ? NewAppColor.skyPrimary
                    : NewAppColor.neutral300,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '등록',
                      style: FigmaTextStyles().button1.copyWith(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
        final tableName =
            post['tableName'] as String? ?? post['table'] as String?;
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
          CustomDropdownField<String>(
            label: '카테고리',
            hintText: '카테고리를 선택하세요',
            value: _selectedCategory,
            required: true,
            items: buildSimpleDropdownItems(
              items: const ['가구', '전자제품', '도서', '의류', '장난감', '생활용품', '기타'],
              currentValue: _selectedCategory,
            ),
            onChanged: (value) => setState(() => _selectedCategory = value),
            validator: (value) => value == null ? '카테고리를 선택해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 3. 제목 *
          _buildRequiredLabel('제목'),
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
          _buildRequiredLabel('설명'),
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
          CustomDropdownField<String>(
            label: '상태',
            hintText: '상품 상태를 선택하세요',
            value: _selectedCondition,
            required: true,
            items: buildSimpleDropdownItems(
              items: const ['새상품', '거의새것', '양호', '사용감있음'],
              currentValue: _selectedCondition,
            ),
            onChanged: (value) => setState(() => _selectedCondition = value),
            validator: (value) => value == null ? '상품 상태를 선택해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 6. 판매 가격 *
          _buildRequiredLabel('판매 가격'),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _priceController,
            enabled: !_isFreeSharing, // 무료나눔 체크 시 비활성화
            decoration: _buildInputDecoration(
              hintText: _isFreeSharing ? '무료나눔' : '숫자로만 입력 (예: 50000)',
            ),
            style: FigmaTextStyles().body2.copyWith(
                  color: _isFreeSharing
                      ? NewAppColor.neutral400
                      : NewAppColor.neutral900,
                ),
            keyboardType: TextInputType.number,
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
                  activeColor: NewAppColor.skyPrimary,
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

          // 7. 거래 지역 *
          Row(
            children: [
              // 도/시 선택
              Expanded(
                child: CustomDropdownField<String>(
                  label: '도/시',
                  hintText: '도/시 선택',
                  value: _selectedProvince,
                  required: true,
                  items: LocationData.getCities().map((city) {
                    return buildDropdownItem<String>(
                      value: city,
                      text: city,
                      currentValue: _selectedProvince,
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
                child: CustomDropdownField<String>(
                  label: '시/군/구',
                  hintText: '시/군/구 선택',
                  value: _selectedDistrict,
                  required: true,
                  enabled: _selectedProvince != null,
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!)
                          .map((district) {
                          return buildDropdownItem<String>(
                            value: district,
                            text: district,
                            currentValue: _selectedDistrict,
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
                  activeColor: NewAppColor.skyPrimary,
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
          TextField(
            controller: _purchaseDateController,
            decoration: _buildInputDecoration(
              hintText: '예: 2023년 3월, 작년 여름 등',
            ),
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                ),
          ),
          SizedBox(height: 24.h),

          // 8 (무료나눔의 경우 6). 연락처 (선택)
          Text(
            '연락처 (선택)',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _contactController,
            decoration: _buildInputDecoration(
              hintText: '연락 가능한 전화번호를 입력해주세요 (선택사항)',
            ),
            style: FigmaTextStyles().body2,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 24.h),

          // 9 (무료나눔의 경우 7). 이메일 (선택)
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
              if ((_existingImageUrls.length + _selectedImages.length) <
                  maxCount)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100.w,
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                        Icon(LucideIcons.plus,
                            size: 32.sp, color: NewAppColor.neutral400),
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
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
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
                                  Icon(LucideIcons.imageOff,
                                      size: 40.sp, color: Colors.grey),
                                  Text(
                                    '이미지 로드 실패',
                                    style: TextStyle(
                                        fontSize: 10.sp, color: Colors.grey),
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
                              LucideIcons.x,
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
                              LucideIcons.x,
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
          _buildRequiredLabel('제목'),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _titleController,
            decoration: _buildInputDecoration(
              hintText: '요청할 물품의 제목을 입력하세요',
            ),
            style: FigmaTextStyles().body2,
            onChanged: (value) {
              setState(() {}); // 입력 시 UI 업데이트 (등록 버튼 활성화 체크)
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '제목을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 24.h),

          // 2. 카테고리 *
          CustomDropdownField<String>(
            label: '카테고리',
            hintText: '카테고리 선택',
            value: _selectedCategory,
            required: true,
            items: buildSimpleDropdownItems(
              items: const [
                '가구',
                '전자제품',
                '도서',
                '의류',
                '장난감',
                '생활용품',
                '기타'
              ],
              currentValue: _selectedCategory,
            ),
            onChanged: (value) =>
                setState(() => _selectedCategory = value),
            validator: (value) => value == null ? '카테고리를 선택해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 3. 거래 지역 * (지역 선택 OR 택배 가능 중 하나 필수)
          _buildRequiredLabel('거래 지역'),
          SizedBox(height: 8.h),
          Row(
            children: [
              // 도/시 선택
              Expanded(
                child: CustomDropdownField<String>(
                  hintText: '도/시 선택',
                  value: _selectedProvince,
                  items: LocationData.getCities().map((city) {
                    return buildDropdownItem<String>(
                      value: city,
                      text: city,
                      currentValue: _selectedProvince,
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
                child: CustomDropdownField<String>(
                  hintText: '시/군/구 선택',
                  value: _selectedDistrict,
                  enabled: _selectedProvince != null,
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!)
                          .map((district) {
                          return buildDropdownItem<String>(
                            value: district,
                            text: district,
                            currentValue: _selectedDistrict,
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
                  activeColor: NewAppColor.skyPrimary,
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

          // 4. 보상 정보 *
          _buildRequiredLabel('보상 정보'),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: CustomDropdownField<String>(
                  hintText: '보상 유형 선택',
                  value: _rewardType,
                  required: true,
                  items: [
                    buildDropdownItem<String>(
                        value: 'free', text: '무료나눔', currentValue: _rewardType),
                    buildDropdownItem<String>(
                        value: 'exchange',
                        text: '교환',
                        currentValue: _rewardType),
                    buildDropdownItem<String>(
                        value: 'payment',
                        text: '금액',
                        currentValue: _rewardType),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _rewardType = value;
                      // 유형 변경 시 입력값 초기화
                      if (value == 'free') {
                        _rewardAmountController.clear();
                        _exchangeItemController.clear();
                      } else if (value == 'exchange') {
                        _rewardAmountController.clear();
                      } else if (value == 'payment') {
                        _exchangeItemController.clear();
                      }
                    });
                  },
                  validator: (value) => value == null ? '보상 유형을 선택해주세요' : null,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_rewardType == 'exchange')
                      TextFormField(
                        controller: _exchangeItemController,
                        decoration: _buildInputDecoration(
                          hintText: '교환할 물건',
                        ),
                        style: FigmaTextStyles().body2,
                      )
                    else if (_rewardType == 'payment')
                      TextFormField(
                        controller: _rewardAmountController,
                        decoration: _buildInputDecoration(
                          hintText: '보상 금액 (원)',
                        ),
                        style: FigmaTextStyles().body2,
                        keyboardType: TextInputType.number,
                      )
                    else
                      TextFormField(
                        decoration: _buildInputDecoration(
                          hintText: '해당 없음',
                        ),
                        style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral400,
                        ),
                        enabled: false,
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 5. 상세 설명 *
          _buildRequiredLabel('상세 설명'),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _descriptionController,
            decoration: _buildInputDecoration(
              hintText: '원하는 물품의 상세 조건이나 상태를 설명해주세요',
              counterText: '${_descriptionController.text.length}/1000',
            ),
            style: FigmaTextStyles().body2,
            maxLines: 4,
            onChanged: (value) {
              setState(() {}); // 입력 시 UI 업데이트 (등록 버튼 활성화 체크)
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '상세 설명을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 24.h),

          // 8. 연락처 (선택) | 이메일 (Row)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '연락처 (선택)',
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
        ],
      ),
    );
  }

  /// 안내 항목
  Widget _buildInfoItem(String text) {
    return Text(
      text,
      style: FigmaTextStyles().caption1.copyWith(
            color: NewAppColor.skyDeep,
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
          _buildRequiredLabel('모집 제목'),
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

          // 2. 교회/기관명 *
          _buildRequiredLabel('교회/기관명'),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _companyController,
            decoration: _buildInputDecoration(
              hintText: '예: 은혜교회, 사랑의교회',
            ),
            style: FigmaTextStyles().body2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '교회/기관명을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: 24.h),

          // 3. 직책 * | 고용 형태 (Row)
          Row(
            children: [
              Expanded(
                child: CustomDropdownField<String>(
                  label: '직책',
                  hintText: '직책 선택',
                  value: _selectedCategory,
                  required: true,
                  items: [
                    buildDropdownItem<String>(
                        value: 'pastor',
                        text: '목사',
                        currentValue: _selectedCategory),
                    buildDropdownItem<String>(
                        value: 'minister',
                        text: '전도사',
                        currentValue: _selectedCategory),
                    buildDropdownItem<String>(
                        value: 'worship',
                        text: '찬양사역자',
                        currentValue: _selectedCategory),
                    buildDropdownItem<String>(
                        value: 'admin',
                        text: '행정간사',
                        currentValue: _selectedCategory),
                    buildDropdownItem<String>(
                        value: 'education',
                        text: '교육간사',
                        currentValue: _selectedCategory),
                    buildDropdownItem<String>(
                        value: 'other',
                        text: '기타',
                        currentValue: _selectedCategory),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                  validator: (value) => value == null ? '직책을 선택해주세요' : null,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: CustomDropdownField<String>(
                  label: '고용 형태',
                  hintText: '고용 형태',
                  value: _selectedEmploymentType,
                  required: true,
                  items: [
                    buildDropdownItem<String>(
                        value: 'full-time',
                        text: '정규직',
                        currentValue: _selectedEmploymentType),
                    buildDropdownItem<String>(
                        value: 'contract',
                        text: '계약직',
                        currentValue: _selectedEmploymentType),
                    buildDropdownItem<String>(
                        value: 'part-time',
                        text: '시간제',
                        currentValue: _selectedEmploymentType),
                    buildDropdownItem<String>(
                        value: 'volunteer',
                        text: '자원봉사',
                        currentValue: _selectedEmploymentType),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedEmploymentType = value),
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
                    _buildRequiredLabel('급여 조건'),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _salaryController,
                      enabled: !_isSalaryNegotiable,
                      decoration: _buildInputDecoration(
                        hintText: _isSalaryNegotiable ? '협의' : '예: 월 300만원',
                      ),
                      style: FigmaTextStyles().body2,
                      onChanged: (value) {
                        setState(() {}); // validation 업데이트
                      },
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: Checkbox(
                            value: _isSalaryNegotiable,
                            onChanged: (value) {
                              setState(() {
                                _isSalaryNegotiable = value ?? false;
                                if (_isSalaryNegotiable) {
                                  _salaryController.text = '협의';
                                } else {
                                  _salaryController.clear();
                                }
                              });
                            },
                            activeColor: NewAppColor.skyPrimary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '급여 협의',
                          style: FigmaTextStyles().body2.copyWith(
                                color: NewAppColor.neutral700,
                              ),
                        ),
                      ],
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
                child: CustomDropdownField<String>(
                  hintText: '도/시 선택',
                  value: _selectedProvince,
                  items: LocationData.getCities().map((city) {
                    return buildDropdownItem<String>(
                      value: city,
                      text: city,
                      currentValue: _selectedProvince,
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
                child: CustomDropdownField<String>(
                  hintText: '시/군/구 선택',
                  value: _selectedDistrict,
                  enabled: _selectedProvince != null,
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!)
                          .map((district) {
                          return buildDropdownItem<String>(
                            value: district,
                            text: district,
                            currentValue: _selectedDistrict,
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
          SizedBox(height: 24.h),

          // 4. 지원 마감일 *
          _buildRequiredLabel('지원 마감일'),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _deadlineController,
            readOnly: true,
            decoration: _buildInputDecoration(
              hintText: '지원 마감일을 선택해주세요',
              prefixIcon: const Icon(LucideIcons.calendarDays),
            ),
            style: FigmaTextStyles().body2,
            onTap: () async {
              final date = await showCustomDatePicker(
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
          // Text(
          //   '상세 내용',
          //   style: FigmaTextStyles().headline4.copyWith(
          //     color: NewAppColor.neutral900,
          //     fontWeight: FontWeight.w700,
          //   ),
          // ),
          // SizedBox(height: 24.h),

          // 5. 상세 내용 (통합)
          _buildRequiredLabel('상세 내용'),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _descriptionController,
            decoration: _buildInputDecoration(
              hintText: '''아래 내용을 포함하여 작성해주세요:

• 교회 소개 (비전, 역사, 특징 등)
• 담당 업무 및 역할
• 자격 요건 (학력, 경력, 자격증 등)
• 우대 사항
• 복리후생 (4대보험, 연차, 숙소 제공 등)
• 기타 참고사항''',
            ),
            style: FigmaTextStyles().body2,
            maxLines: 15,
          ),
          SizedBox(height: 32.h),

          // ===== 섹션 3: 연락처 정보 =====
          Text(
            '연락처 정보(선택)',
            style: FigmaTextStyles().headline4.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 24.h),

          // 6. 담당자 연락처(선택) | 이메일(선택) (Row)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '담당자 연락처',
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
          _buildRequiredLabel('모집 제목'),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _titleController,
            decoration: _buildInputDecoration(
              hintText: '예: 주일예배 피아니스트 모집',
              counterText: '${_titleController.text.length}/100',
            ),
            maxLength: 100,
            onChanged: (value) => setState(() {}),
            validator: (value) =>
                value?.trim().isEmpty ?? true ? '제목을 입력해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 2. 행사 유형 *
          CustomDropdownField<String>(
            label: '행사 유형',
            hintText: '행사 유형 선택',
            value: _selectedEventType,
            required: true,
            items: [
              buildDropdownItem<String>(
                  value: 'sunday-service',
                  text: '주일예배',
                  currentValue: _selectedEventType),
              buildDropdownItem<String>(
                  value: 'wednesday-service',
                  text: '수요예배',
                  currentValue: _selectedEventType),
              buildDropdownItem<String>(
                  value: 'dawn-service',
                  text: '새벽예배',
                  currentValue: _selectedEventType),
              buildDropdownItem<String>(
                  value: 'special-service',
                  text: '특별예배',
                  currentValue: _selectedEventType),
              buildDropdownItem<String>(
                  value: 'revival',
                  text: '부흥회',
                  currentValue: _selectedEventType),
              buildDropdownItem<String>(
                  value: 'praise-meeting',
                  text: '찬양집회',
                  currentValue: _selectedEventType),
              buildDropdownItem<String>(
                  value: 'wedding',
                  text: '결혼식',
                  currentValue: _selectedEventType),
              buildDropdownItem<String>(
                  value: 'funeral',
                  text: '장례식',
                  currentValue: _selectedEventType),
              buildDropdownItem<String>(
                  value: 'retreat',
                  text: '수련회',
                  currentValue: _selectedEventType),
              buildDropdownItem<String>(
                  value: 'concert',
                  text: '콘서트',
                  currentValue: _selectedEventType),
              buildDropdownItem<String>(
                  value: 'other', text: '기타', currentValue: _selectedEventType),
            ],
            onChanged: (value) => setState(() => _selectedEventType = value),
            validator: (value) => value == null ? '행사 유형을 선택해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 3. 모집 팀 형태 *
          CustomDropdownField<String>(
            label: '모집 팀 형태',
            hintText: '팀 형태 선택',
            value: _selectedTeamType,
            required: true,
            items: [
              buildDropdownItem<String>(
                  value: 'solo',
                  text: '현재 솔로 활동',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'praise-team',
                  text: '찬양팀',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'worship-team',
                  text: '워십팀',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'acoustic-team',
                  text: '어쿠스틱 팀',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'band', text: '밴드', currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'orchestra',
                  text: '오케스트라',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'choir', text: '합창단', currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'dance-team',
                  text: '무용팀',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'other', text: '기타', currentValue: _selectedTeamType),
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
                        prefixIcon: const Icon(LucideIcons.calendarDays),
                      ),
                      onTap: () async {
                        final date = await showCustomDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _eventDateController.text =
                                date.toString().split(' ')[0];
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
                        prefixIcon: const Icon(LucideIcons.clock),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 5. 지역
          _buildRequiredLabel('지역'),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: CustomDropdownField<String>(
                  hintText: '도/시 선택',
                  value: _selectedProvince,
                  items: LocationData.getCities().map((city) {
                    return buildDropdownItem<String>(
                      value: city,
                      text: city,
                      currentValue: _selectedProvince,
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
                child: CustomDropdownField<String>(
                  hintText: '시/군/구 선택',
                  value: _selectedDistrict,
                  enabled: _selectedProvince != null,
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!)
                          .map((district) {
                          return buildDropdownItem<String>(
                            value: district,
                            text: district,
                            currentValue: _selectedDistrict,
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

          // 위치 상세 정보
          TextFormField(
            controller: _locationController,
            decoration: _buildInputDecoration(
              hintText: '상세정보를 입력해주세요',
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

          // 통합 상세 설명
          _buildRequiredLabel('상세 설명'),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _descriptionController,
            decoration: _buildInputDecoration(
              hintText: '''다음 내용을 포함하여 자세히 작성해주세요:

• 행사 내용 및 분위기
  예: 주일 1부 예배, 현대적인 워십 스타일

• 자격 요건 및 경력
  예: 3년 이상 연주 경험, 악보 시창 가능

• 보상 및 사례비
  예: 회당 5만원 / 봉사 / 협의 등''',
              counterText: '${_descriptionController.text.length}/1000',
            ),
            maxLines: 10,
            maxLength: 1000,
            onChanged: (value) => setState(() {}),
            validator: (value) =>
                value?.trim().isEmpty ?? true ? '상세 설명을 입력해주세요' : null,
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

          // 담당자 연락처 (선택) | 이메일 (선택) (2 columns)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '담당자 연락처 (선택)',
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
                    _buildRequiredLabel('지원서 제목'),
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
          CustomDropdownField<String>(
            label: '팀 형태',
            hintText: '팀 형태 선택',
            value: _selectedTeamType,
            required: true,
            items: [
              buildDropdownItem<String>(
                  value: 'solo',
                  text: '현재 솔로 활동',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'praise-team',
                  text: '찬양팀',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'worship-team',
                  text: '워십팀',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'acoustic-team',
                  text: '어쿠스틱 팀',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'band', text: '밴드', currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'orchestra',
                  text: '오케스트라',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'choir', text: '합창단', currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'dance-team',
                  text: '무용팀',
                  currentValue: _selectedTeamType),
              buildDropdownItem<String>(
                  value: 'other', text: '기타', currentValue: _selectedTeamType),
            ],
            onChanged: (value) => setState(() => _selectedTeamType = value),
            validator: (value) => value == null ? '팀 형태를 선택해주세요' : null,
          ),
          SizedBox(height: 16.h),

          // 3. 팀 소개
          Text(
            '팀 소개',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _experienceController,
            decoration: _buildInputDecoration(
              hintText: '찬양팀, 워십팀, 밴드 등 팀을 소개하면 좋은 결과 생길 수 있습니다.',
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
                child: CustomDropdownField<String>(
                  hintText: '도/시 선택',
                  value: _selectedProvince,
                  items: LocationData.getCities().map((city) {
                    return buildDropdownItem<String>(
                      value: city,
                      text: city,
                      currentValue: _selectedProvince,
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
                child: CustomDropdownField<String>(
                  hintText: '시/군/구 선택',
                  value: _selectedDistrict,
                  enabled: _selectedProvince != null,
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!)
                          .map((district) {
                          return buildDropdownItem<String>(
                            value: district,
                            text: district,
                            currentValue: _selectedDistrict,
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
                    AppToast.show(context, '이미 추가된 지역입니다',
                        type: ToastType.warning);
                  }
                } else {
                  AppToast.show(context, '도/시와 시/군/구를 선택해주세요',
                      type: ToastType.warning);
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
                  deleteIcon: Icon(LucideIcons.x, size: 18.r),
                  onDeleted: () {
                    setState(() {
                      _preferredLocations.remove(location);
                    });
                  },
                  backgroundColor: NewAppColor.skyTint,
                  labelStyle: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.skyDeep,
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
                                    color: _availableDays.contains(day)
                                        ? Colors.white
                                        : NewAppColor.neutral700,
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
                          showCheckmark: false, // 체크 표시 제거
                          side: BorderSide.none, // 보더라인 제거
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 16.h),

          // 6. 활동 가능 시간대
          CustomDropdownField<String>(
            label: '활동 가능 시간대',
            hintText: '활동 가능 시간대',
            value: _selectedTimeSlot,
            items: [
              buildDropdownItem<String>(
                  value: 'morning',
                  text: '오전 (9:00-12:00)',
                  currentValue: _selectedTimeSlot),
              buildDropdownItem<String>(
                  value: 'afternoon',
                  text: '오후 (13:00-18:00)',
                  currentValue: _selectedTimeSlot),
              buildDropdownItem<String>(
                  value: 'evening',
                  text: '저녁 (18:00-21:00)',
                  currentValue: _selectedTimeSlot),
              buildDropdownItem<String>(
                  value: 'night',
                  text: '야간 (21:00-23:00)',
                  currentValue: _selectedTimeSlot),
              buildDropdownItem<String>(
                  value: 'anytime',
                  text: '상시 가능',
                  currentValue: _selectedTimeSlot),
              buildDropdownItem<String>(
                  value: 'negotiable',
                  text: '협의 후 결정',
                  currentValue: _selectedTimeSlot),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTimeSlot = value;
                if (value != null) {
                  final timeLabels = {
                    'morning': '오전 (9:00-12:00)',
                    'afternoon': '오후 (13:00-18:00)',
                    'evening': '저녁 (18:00-21:00)',
                    'night': '야간 (21:00-23:00)',
                    'anytime': '상시 가능',
                    'negotiable': '협의 후 결정',
                  };
                  _availableTimeController.text = timeLabels[value] ?? value;
                }
              });
            },
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
                    Icon(LucideIcons.upload,
                        size: 40.r, color: NewAppColor.neutral500),
                    SizedBox(height: 8.h),
                    Text(
                      '파일을 드래그',
                      style: FigmaTextStyles().body2.copyWith(
                            color: NewAppColor.neutral700,
                          ),
                    ),
                    SizedBox(height: 12.h),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _pickPortfolioFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NewAppColor.primary500,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        _portfolioFileUrl != null ? '파일 변경' : '파일 선택',
                        style: FigmaTextStyles().body2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (_portfolioFileUrl != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: NewAppColor.skyTint,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.circleCheck,
                                size: 16.r, color: NewAppColor.skyPrimary),
                            SizedBox(width: 4.w),
                            Text(
                              '파일 업로드 완료',
                              style: FigmaTextStyles().body2.copyWith(
                                    fontSize: 12.sp,
                                    color: NewAppColor.skyPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(width: 8.w),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _portfolioFileUrl = null;
                                });
                              },
                              child: Icon(LucideIcons.x,
                                  size: 16.r, color: NewAppColor.skyPrimary),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
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

          // 연락처 (선택) | 이메일 (선택) - 2 columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '연락처 (선택)',
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
          CustomDropdownField<String>(
            label: '카테고리',
            hintText: '카테고리 선택',
            value: _selectedNewsCategory,
            required: true,
            items: [
              buildDropdownItem<String>(
                  value: 'worship',
                  text: '특별예배/연합예배',
                  currentValue: _selectedNewsCategory),
              buildDropdownItem<String>(
                  value: 'event',
                  text: '행사',
                  currentValue: _selectedNewsCategory),
              buildDropdownItem<String>(
                  value: 'retreat',
                  text: '수련회',
                  currentValue: _selectedNewsCategory),
              buildDropdownItem<String>(
                  value: 'mission',
                  text: '선교',
                  currentValue: _selectedNewsCategory),
              buildDropdownItem<String>(
                  value: 'education',
                  text: '교육',
                  currentValue: _selectedNewsCategory),
              buildDropdownItem<String>(
                  value: 'volunteer',
                  text: '봉사',
                  currentValue: _selectedNewsCategory),
              buildDropdownItem<String>(
                  value: 'other',
                  text: '기타',
                  currentValue: _selectedNewsCategory),
            ],
            onChanged: (value) => setState(() => _selectedNewsCategory = value),
            validator: (value) => value == null ? '카테고리를 선택해주세요' : null,
          ),
          SizedBox(height: 24.h),

          // 제목 *
          _buildRequiredLabel('제목'),
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
          _buildRequiredLabel('내용'),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: '행사 소식의 상세 내용을 입력하세요\n\n예시:\n- 주최자/부서: 청년부\n- 대상: 청년부 전체\n- 참가비: 무료\n- 담당자: 홍길동',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              counterText: '${_descriptionController.text.length}/1000',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            maxLines: 8,
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
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              prefixIcon: Icon(LucideIcons.calendarDays,
                  size: 20.r, color: NewAppColor.neutral600),
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            onTap: () async {
              final date = await showCustomDatePicker(
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
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              suffixIcon: Icon(LucideIcons.clock,
                  size: 20.r, color: NewAppColor.neutral600),
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                child: CustomDropdownField<String>(
                  hintText: '도/시 선택',
                  value: _selectedProvince,
                  items: LocationData.getCities().map((city) {
                    return buildDropdownItem<String>(
                      value: city,
                      text: city,
                      currentValue: _selectedProvince,
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
                child: CustomDropdownField<String>(
                  hintText: '시/군/구 선택',
                  value: _selectedDistrict,
                  enabled: _selectedProvince != null,
                  items: _selectedProvince != null
                      ? LocationData.getDistricts(_selectedProvince!)
                          .map((district) {
                          return buildDropdownItem<String>(
                            value: district,
                            text: district,
                            currentValue: _selectedDistrict,
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
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: '상세 주소를 입력하세요 (예: ○○교회, ○○센터 2층)',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              counterText: '${_locationController.text.length}/100',
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            maxLength: 100,
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 24.h),

          // 연락처(선택)
          Text(
            '연락처(선택)',
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
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 24.h),

          // 이메일
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
              hintText: 'contact@church.com',
              hintStyle: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              filled: true,
              fillColor: NewAppColor.neutral100,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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

    // 무료나눔/물품판매 추가 검증
    if (widget.type == CommunityListType.freeSharing ||
        widget.type == CommunityListType.itemSale) {
      // 사진 필수
      if (_selectedImages.isEmpty) {
        AppToast.show(
          context,
          '최소 1장 이상의 사진을 등록해주세요',
          type: ToastType.error,
        );
        return;
      }

      // 금액 필수 (무료나눔 체크하면 통과)
      if (!_isFreeSharing && _priceController.text.trim().isEmpty) {
        AppToast.show(
          context,
          '판매 가격을 입력하거나 무료나눔을 선택해주세요',
          type: ToastType.error,
        );
        return;
      }

      // 지역 필수 (택배 가능 체크하면 통과)
      if (!_deliveryAvailable &&
          _selectedProvince == null &&
          _selectedDistrict == null) {
        AppToast.show(
          context,
          '거래 지역을 선택하거나 택배 가능을 체크해주세요',
          type: ToastType.error,
        );
        return;
      }
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
      print(
          '📐 이미지 리사이즈: ${image.width}x${image.height} → ${targetWidth}x${targetHeight}');
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
    print(
        '📊 압축 후 크기: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)}MB (${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}% 감소)');

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
        final random =
            (DateTime.now().microsecond % 10000).toString().padLeft(4, '0');
        final fileName = '${timestamp}_$random.png';

        print('📤 이미지 업로드 중 (${i + 1}/${_selectedImages.length}): $fileName');

        // 이미지 압축
        final compressedBytes = await _compressImage(imageFile);

        // Supabase Storage에 업로드
        final path =
            await supabase.storage.from('community-images').uploadBinary(
                  fileName,
                  compressedBytes,
                );

        // Public URL 생성
        final publicUrl =
            supabase.storage.from('community-images').getPublicUrl(fileName);

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

  /// 포트폴리오 파일 선택
  Future<void> _pickPortfolioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'mp3', 'mp4', 'mov'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // 파일 크기 체크 (10MB = 10 * 1024 * 1024 bytes)
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            AppToast.show(
              context,
              '파일 크기는 10MB를 초과할 수 없습니다',
              type: ToastType.error,
            );
          }
          return;
        }

        setState(() => _isLoading = true);

        // 파일 업로드
        final fileUrl = await _uploadPortfolioFile(file);

        if (fileUrl != null) {
          setState(() {
            _portfolioFileUrl = fileUrl;
          });
          if (mounted) {
            AppToast.show(
              context,
              '파일이 업로드되었습니다',
              type: ToastType.success,
            );
          }
        }
      }
    } catch (e) {
      print('❌ 파일 선택 실패: $e');
      if (mounted) {
        AppToast.show(
          context,
          '파일 선택에 실패했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 포트폴리오 파일 업로드 (Supabase Storage)
  Future<String?> _uploadPortfolioFile(PlatformFile file) async {
    print('📄 파일 업로드 시작: ${file.name}');

    final supabase = SupabaseService().client;

    try {
      // 파일명 생성: timestamp_originalname
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension ?? 'bin';
      final fileName = '${timestamp}_portfolio.$extension';

      print(
          '📤 파일 업로드 중: $fileName (${(file.size / 1024 / 1024).toStringAsFixed(2)}MB)');

      Uint8List fileBytes;
      if (file.bytes != null) {
        fileBytes = file.bytes!;
      } else if (file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      } else {
        throw Exception('파일 데이터를 읽을 수 없습니다');
      }

      // MIME 타입 결정
      String contentType = 'application/octet-stream';
      switch (extension.toLowerCase()) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'mp3':
          contentType = 'audio/mpeg';
          break;
        case 'mp4':
          contentType = 'video/mp4';
          break;
        case 'mov':
          contentType = 'video/quicktime';
          break;
      }

      // Supabase Storage에 업로드 (community-files 버킷 사용)
      await supabase.storage.from('community-files').uploadBinary(
            fileName,
            fileBytes,
          );

      // Public URL 생성
      final publicUrl =
          supabase.storage.from('community-files').getPublicUrl(fileName);

      print('✅ 파일 업로드 완료: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ 파일 업로드 실패: $e');
      if (mounted) {
        AppToast.show(
          context,
          '파일 업로드에 실패했습니다: $e',
          type: ToastType.error,
        );
      }
      return null;
    }
  }

  /// 도/시, 시/군/구, 상세주소를 합쳐서 전체 위치 문자열 생성
  String _buildFullLocation() {
    final parts = <String>[];

    if (_selectedProvince != null && _selectedProvince!.isNotEmpty) {
      parts.add(_selectedProvince!);
    }

    if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
      parts.add(_selectedDistrict!);
    }

    final detailLocation = _locationController.text.trim();
    if (detailLocation.isNotEmpty) {
      parts.add(detailLocation);
    }

    return parts.join(' ');
  }

  /// 위치 문자열을 파싱하여 도/시, 시/군/구, 상세주소로 분리
  void _parseLocationString(String location) {
    if (location.isEmpty) {
      _selectedProvince = null;
      _selectedDistrict = null;
      _locationController.text = '';
      return;
    }

    final parts = location.split(' ');
    final cities = LocationData.getCities();

    // 첫 번째 파트가 도/시 목록에 있는지 확인
    if (parts.isNotEmpty && cities.contains(parts[0])) {
      _selectedProvince = parts[0];

      // 두 번째 파트가 시/군/구 목록에 있는지 확인
      if (parts.length > 1) {
        final districts = LocationData.getDistricts(_selectedProvince!);
        if (districts.contains(parts[1])) {
          _selectedDistrict = parts[1];

          // 나머지는 상세주소
          if (parts.length > 2) {
            _locationController.text = parts.sublist(2).join(' ');
          } else {
            _locationController.text = '';
          }
        } else {
          // 두 번째 파트가 시/군/구가 아니면 전체를 상세주소로
          _selectedDistrict = null;
          _locationController.text = parts.sublist(1).join(' ');
        }
      } else {
        _selectedDistrict = null;
        _locationController.text = '';
      }
    } else {
      // 도/시가 없으면 전체를 상세주소로
      _selectedProvince = null;
      _selectedDistrict = null;
      _locationController.text = location;
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
      purchaseDate: _purchaseDateController.text.trim().isEmpty
          ? null
          : _purchaseDateController.text.trim(),
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
      province: _selectedProvince,
      district: _selectedDistrict,
      deliveryAvailable: _deliveryAvailable,
      urgency: _selectedUrgency,
      images: imageUrls,
      contactPhone: _contactController.text.trim(),
      contactEmail: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      rewardType: _rewardType,
      rewardAmount: _rewardType == 'payment'
          ? double.tryParse(_rewardAmountController.text.trim())
          : null,
      exchangeItem: _rewardType == 'exchange'
          ? _exchangeItemController.text.trim()
          : null,
    );

    return response.success;
  }

  /// 사역자모집 제출
  Future<bool> _submitJobPosting() async {
    // 수정 모드인지 확인
    final isEditMode = widget.existingPost != null;

    final response = isEditMode
        ? await _communityService.updateJobPost(
            id: widget.existingPost is Map
                ? (widget.existingPost as Map<String, dynamic>)['id'] as int
                : (widget.existingPost as JobPost).id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            company: _companyController.text.trim(),
            churchIntro: '', // 상세 내용에 통합됨
            position: _selectedCategory ?? 'other', // UI의 직책 dropdown
            jobType: '', // 사용하지 않음
            employmentType: _selectedEmploymentType ?? 'full-time',
            salary: _salaryController.text.trim(),
            qualifications: '', // 상세 내용에 통합됨
            province: _selectedProvince,
            district: _selectedDistrict,
            deliveryAvailable: _deliveryAvailable,
            deadline: _deadlineController.text.trim().isEmpty
                ? null
                : _deadlineController.text.trim(),
            contactPhone: _contactController.text.trim().isEmpty
                ? null
                : _contactController.text.trim(),
            contactEmail: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          )
        : await _communityService.createJobPost(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            company: _companyController.text.trim(),
            churchIntro: '', // 상세 내용에 통합됨
            position: _selectedCategory ?? 'other', // UI의 직책 dropdown
            jobType: '', // 사용하지 않음
            employmentType: _selectedEmploymentType ?? 'full-time',
            salary: _salaryController.text.trim(),
            qualifications: '', // 상세 내용에 통합됨
            province: _selectedProvince,
            district: _selectedDistrict,
            deliveryAvailable: _deliveryAvailable,
            deadline: _deadlineController.text.trim().isEmpty
                ? null
                : _deadlineController.text.trim(),
            contactPhone: _contactController.text.trim().isEmpty
                ? null
                : _contactController.text.trim(),
            contactEmail: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          );

    return response.success;
  }

  /// 행사팀모집 제출
  Future<bool> _submitMusicTeamRecruit() async {
    // 수정 모드인지 확인
    final isEditMode = widget.existingPost != null;

    final response = isEditMode
        ? await _communityService.updateMusicTeamRecruitment(
            id: widget.existingPost is Map
                ? (widget.existingPost as Map<String, dynamic>)['id'] as int
                : (widget.existingPost as MusicTeamRecruitment).id,
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
            province: _selectedProvince,
            district: _selectedDistrict,
            location: _locationController.text.trim(),
            contactPhone: _contactController.text.trim().isEmpty
                ? null
                : _contactController.text.trim(),
            contactEmail: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          )
        : await _communityService.createMusicTeamRecruitment(
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
            province: _selectedProvince,
            district: _selectedDistrict,
            location: _locationController.text.trim(),
            contactPhone: _contactController.text.trim().isEmpty
                ? null
                : _contactController.text.trim(),
            contactEmail: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          );

    return response.success;
  }

  /// 행사팀지원 제출
  Future<bool> _submitMusicTeamSeeking() async {
    final response = widget.existingPost != null
        ? await _communityService.updateMusicTeamSeeker(
            id: widget.existingPost is Map
                ? (widget.existingPost as Map<String, dynamic>)['id'] as int
                : (widget.existingPost as MusicTeamSeeker).id,
            title: _titleController.text.trim(),
            teamName: _teamNameController.text.trim().isEmpty
                ? '없음'
                : _teamNameController.text.trim(),
            instrument: _selectedTeamType ?? 'none', // 팀 형태를 instrument에 저장
            experience: _experienceController.text.trim(),
            portfolio: _youtubeController.text.trim(), // YouTube 링크를 portfolio로 사용
            portfolioFile: _portfolioFileUrl,
            preferredLocation: _preferredLocations,
            availableDays: _availableDays,
            availableTime: _availableTimeController.text.trim(),
            contactPhone: _contactController.text.trim(),
            contactEmail: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          )
        : await _communityService.createMusicTeamSeeker(
            title: _titleController.text.trim(),
            teamName: _teamNameController.text.trim().isEmpty
                ? '없음'
                : _teamNameController.text.trim(),
            instrument: _selectedTeamType ?? 'none', // 팀 형태를 instrument에 저장
            experience: _experienceController.text.trim(),
            portfolio: _youtubeController.text.trim(), // YouTube 링크를 portfolio로 사용
            portfolioFile: _portfolioFileUrl,
            preferredLocation: _preferredLocations,
            availableDays: _availableDays,
            availableTime: _availableTimeController.text.trim(),
            contactPhone: _contactController.text.trim(),
            contactEmail: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          );

    return response.success;
  }

  /// 교회소식 제출
  Future<bool> _submitChurchNews(List<String> imageUrls) async {
    // 지역 정보 통합
    String fullLocation = _locationController.text.trim();
    if (_selectedProvince != null || _selectedDistrict != null) {
      final locationParts = <String>[];
      if (_selectedProvince != null) locationParts.add(_selectedProvince!);
      if (_selectedDistrict != null) locationParts.add(_selectedDistrict!);
      if (fullLocation.isNotEmpty) locationParts.add(fullLocation);
      fullLocation = locationParts.join(' ');
    }

    final response = await _communityService.createChurchNews(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedNewsCategory!,
      priority: 'normal', // 기본값 사용
      eventDate: _newsEventDateController.text.trim().isEmpty
          ? null
          : _newsEventDateController.text.trim(),
      eventTime: _newsEventTimeController.text.trim().isEmpty
          ? null
          : _newsEventTimeController.text.trim(),
      location: fullLocation,
      organizer: '', // 빈 값으로 전송
      targetAudience: '', // 빈 값으로 전송
      participationFee: '', // 빈 값으로 전송
      contactPerson: '', // 빈 값으로 전송
      images: imageUrls,
    );

    return response.success;
  }
}
