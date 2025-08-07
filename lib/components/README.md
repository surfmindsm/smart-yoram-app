# shadcn/ui 스타일 Flutter 컴포넌트 시스템

shadcn/ui 디자인 철학을 따른 재사용 가능한 Flutter 컴포넌트 라이브러리입니다.

## 설치 및 사용법

```dart
import '../components/index.dart';
```

## 컴포넌트 목록

### 1. AppAlert
다양한 상태를 표시하는 알림 컴포넌트

```dart
// 기본 알림
AppAlert(
  title: "알림",
  description: "이것은 정보성 알림입니다.",
  type: AlertType.info,
  onClose: () => print("닫기"),
)

// 편의 생성자들
InfoAlert(title: "정보", description: "정보성 메시지"),
WarningAlert(title: "경고", description: "주의가 필요합니다"),
ErrorAlert(title: "오류", description: "문제가 발생했습니다"),
SuccessAlert(title: "성공", description: "작업이 완료되었습니다"),
```

### 2. AppButton
다양한 스타일의 버튼 컴포넌트

```dart
// 기본 버튼
AppButton(
  text: "클릭하세요",
  onPressed: () => print("클릭됨"),
  variant: ButtonVariant.primary,
  size: ButtonSize.md,
)

// 편의 생성자들
PrimaryButton(text: "주요 버튼", onPressed: () {}),
SecondaryButton(text: "보조 버튼", onPressed: () {}),
OutlineButton(text: "외곽선 버튼", onPressed: () {}),

// 아이콘 버튼
IconButton(
  icon: Icons.favorite,
  onPressed: () {},
)

// 로딩 상태
AppButton(
  text: "로딩중...",
  isLoading: true,
  onPressed: () {},
)
```

### 3. AppInput
다양한 형태의 입력 필드 컴포넌트

```dart
// 기본 입력
AppInput(
  label: "이름",
  placeholder: "이름을 입력하세요",
  required: true,
  onChanged: (value) => print(value),
)

// 검색 입력
AppSearchInput(
  placeholder: "검색어를 입력하세요",
  onChanged: (value) => print("검색: $value"),
)

// 비밀번호 입력
AppPasswordInput(
  label: "비밀번호",
  required: true,
)
```

### 4. AppCard
다양한 스타일의 카드 컴포넌트

```dart
// 기본 카드
AppCard(
  child: Column(
    children: [
      AppCardHeader(title: "카드 제목", subtitle: "부제목"),
      AppCardContent(child: Text("카드 내용")),
      AppCardFooter(children: [
        PrimaryButton(text: "확인", onPressed: () {}),
      ]),
    ],
  ),
)

// 정보 카드
InfoCard(
  title: "공지사항",
  description: "새로운 업데이트가 있습니다.",
  icon: Icons.info,
  onTap: () => print("카드 클릭됨"),
)

// 통계 카드
StatsCard(
  title: "총 사용자",
  value: "1,234",
  subtitle: "전월 대비",
  icon: Icons.people,
  trend: Text("+12%", style: TextStyle(color: Colors.green)),
)
```

### 5. AppDialog
모달 다이얼로그 컴포넌트

```dart
// 기본 다이얼로그
AppDialog.show(
  context: context,
  title: "확인",
  description: "정말로 삭제하시겠습니까?",
  actions: [
    SecondaryButton(text: "취소", onPressed: () => Navigator.pop(context)),
    PrimaryButton(text: "삭제", onPressed: () => deleteItem()),
  ],
);

// Alert 다이얼로그 (확인/취소)
AppAlertDialog.show(
  context: context,
  title: "삭제 확인",
  description: "이 작업은 되돌릴 수 없습니다.",
  destructive: true,
);

// 로딩 다이얼로그
AppLoadingDialog.show(
  context: context,
  message: "데이터를 불러오는 중...",
);
```

### 6. AppBadge
상태나 라벨을 표시하는 배지 컴포넌트

```dart
// 기본 배지
AppBadge(
  text: "새로움",
  variant: BadgeVariant.primary,
  size: BadgeSize.md,
)

// 아이콘이 있는 배지
AppBadge(
  text: "온라인",
  icon: Icons.circle,
  variant: BadgeVariant.success,
)

// 다양한 상태 배지
AppBadge(text: "진행중", variant: BadgeVariant.warning),
AppBadge(text: "완료", variant: BadgeVariant.success),
AppBadge(text: "오류", variant: BadgeVariant.error),
```

### 7. AppAvatar
사용자 아바타 컴포넌트

```dart
// 이미지 아바타
AppAvatar(
  imageUrl: "https://example.com/avatar.jpg",
  size: AvatarSize.lg,
)

// 이니셜 아바타
AppAvatar(
  initials: "홍길동",
  size: AvatarSize.md,
)

// 프로필 아바타 (온라인 상태 표시)
AppProfileAvatar(
  imageUrl: "https://example.com/profile.jpg",
  showOnlineStatus: true,
  isOnline: true,
)

// 아바타 그룹
AppAvatarGroup(
  avatars: [
    AppAvatar(initials: "김"),
    AppAvatar(initials: "이"),
    AppAvatar(initials: "박"),
  ],
  maxVisible: 2,
)
```

### 8. AppTabs
탭 네비게이션 컴포넌트

```dart
// 라인 스타일 탭 (TabBarView 포함)
AppTabs(
  variant: TabsVariant.line,
  tabs: [
    AppTab(
      label: "홈",
      content: HomeContent(),
      icon: Icons.home,
    ),
    AppTab(
      label: "설정",
      content: SettingsContent(),
      icon: Icons.settings,
    ),
  ],
)

// 알약 스타일 탭
AppTabs(
  variant: TabsVariant.pills,
  tabs: tabs,
)

// 헤더만 있는 탭
AppTabsHeader(
  tabs: ["전체", "읽지 않음", "중요"],
  selectedIndex: 0,
  onChanged: (index) => setState(() => selectedTab = index),
)
```

### 9. AppSkeleton
로딩 상태를 표시하는 스켈레톤 컴포넌트

```dart
// 기본 스켈레톤
AppSkeleton(
  width: 200,
  height: 20,
)

// 텍스트 스켈레톤
AppTextSkeleton(
  lines: 3,
  height: 16,
)

// 원형 스켈레톤 (아바타용)
AppCircleSkeleton(size: 48),

// 카드 스켈레톤
AppCardSkeleton(
  showAvatar: true,
  titleLines: 1,
  bodyLines: 3,
),

// 리스트 아이템 스켈레톤
AppListItemSkeleton(
  showLeading: true,
  titleLines: 1,
  subtitleLines: 2,
),

// 테이블 스켈레톤
AppTableSkeleton(
  rows: 5,
  columns: 4,
  showHeader: true,
),
```

### 10. AppDropdown
드롭다운 선택 컴포넌트

```dart
// 기본 드롭다운
AppDropdown<String>(
  label: "국가 선택",
  placeholder: "국가를 선택하세요",
  value: selectedCountry,
  items: [
    AppDropdownMenuItem(
      value: "ko",
      text: "대한민국",
      leading: Icon(Icons.flag),
    ),
    AppDropdownMenuItem(
      value: "us",
      text: "미국",
      leading: Icon(Icons.flag),
    ),
  ],
  onChanged: (value) => setState(() => selectedCountry = value),
)

// 문자열 드롭다운 편의 생성자
AppDropdown.text(
  label: "언어",
  options: ["한국어", "English", "日本語"],
  value: selectedLanguage,
  onChanged: (value) => setState(() => selectedLanguage = value),
)
```

### 11. AppCheckbox
체크박스 컴포넌트

```dart
// 기본 체크박스
AppCheckbox(
  value: isChecked,
  label: "이용약관에 동의합니다",
  onChanged: (value) => setState(() => isChecked = value ?? false),
)

// 설명이 있는 체크박스
AppCheckbox.withDescription(
  value: isChecked,
  label: "마케팅 수신 동의",
  description: "프로모션 및 이벤트 정보를 받아보실 수 있습니다",
  onChanged: (value) => setState(() => isChecked = value ?? false),
)
```

### 12. AppRadio & AppRadioGroup
라디오 버튼 컴포넌트

```dart
// 라디오 그룹
AppRadioGroup<String>(
  label: "성별",
  value: selectedGender,
  options: [
    AppRadioOption(value: "male", label: "남성"),
    AppRadioOption(value: "female", label: "여성"),
    AppRadioOption(value: "other", label: "기타"),
  ],
  onChanged: (value) => setState(() => selectedGender = value),
)

// 문자열 라디오 그룹 편의 생성자
AppRadioGroup.text(
  label: "선호 언어",
  options: ["한국어", "영어", "일본어"],
  value: selectedLanguage,
  onChanged: (value) => setState(() => selectedLanguage = value),
  direction: Axis.horizontal,
)
```

### 13. AppSwitch
스위치 토글 컴포넌트

```dart
// 기본 스위치
AppSwitch(
  value: isEnabled,
  label: "알림 설정",
  onChanged: (value) => setState(() => isEnabled = value),
)

// 설명이 있는 스위치
AppSwitch.labeled(
  value: isDarkMode,
  label: "다크모드",
  description: "어두운 테마를 사용합니다",
  onChanged: (value) => setState(() => isDarkMode = value),
)
```

### 14. AppSlider & AppRangeSlider
슬라이더 컴포넌트

```dart
// 기본 슬라이더
AppSlider(
  value: currentValue,
  min: 0,
  max: 100,
  label: "볼륨",
  showValue: true,
  onChanged: (value) => setState(() => currentValue = value),
)

// 퍼센트 슬라이더
AppSlider.percentage(
  value: progress,
  label: "진행률",
  onChanged: (value) => setState(() => progress = value),
)

// 범위 슬라이더
AppRangeSlider(
  values: RangeValues(minPrice, maxPrice),
  min: 0,
  max: 1000000,
  label: "가격 범위",
  showValues: true,
  valueFormatter: (value) => "₩${value.toInt()}",
  onChanged: (values) => setState(() {
    minPrice = values.start;
    maxPrice = values.end;
  }),
)
```

### 15. AppProgress & AppCircularProgress
진행률 표시 컴포넌트

```dart
// 선형 진행률 표시
AppProgress(
  value: 0.7,
  label: "다운로드 진행률",
  showPercentage: true,
  variant: ProgressVariant.primary,
)

// 퍼센트 진행률
AppProgress.percentage(
  percentage: downloadProgress,
  label: "파일 다운로드",
  variant: ProgressVariant.success,
)

// 단계별 진행률
AppProgress.withSteps(
  current: currentStep,
  total: totalSteps,
  label: "설치 진행률",
)

// 원형 진행률 표시
AppCircularProgress(
  value: 0.8,
  showPercentage: true,
  size: 80,
  label: "로딩 중...",
)
```

### 16. AppTooltip & AppRichTooltip
툴팁 컴포넌트

```dart
// 기본 툴팁
AppTooltip(
  message: "이것은 도움말입니다",
  child: Icon(Icons.help_outline),
)

// 상태별 툴팁
AppTooltip.warning(
  message: "주의가 필요합니다",
  child: Icon(Icons.warning),
)

// 리치 툴팁 (복잡한 내용)
AppRichTooltip(
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text("상세 정보", style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 4),
      Text("여기에 더 자세한 설명을 넣을 수 있습니다."),
    ],
  ),
  child: Icon(Icons.info),
)
```

### 17. AppSelect
고급 선택 컴포넌트 (검색 가능)

```dart
// 검색 가능한 선택
AppSelect<String>(
  label: "도시 선택",
  placeholder: "도시를 검색하세요",
  value: selectedCity,
  searchable: true,
  options: [
    AppSelectOption(
      value: "seoul",
      label: "서울특별시",
      leading: Icon(Icons.location_city),
    ),
    AppSelectOption(
      value: "busan",
      label: "부산광역시",
      leading: Icon(Icons.location_city),
    ),
  ],
  onChanged: (value) => setState(() => selectedCity = value),
)

// 간단한 문자열 선택
AppSelect.text(
  label: "카테고리",
  options: ["전체", "예배/모임", "교우 소식", "행사/공지"],
  value: selectedCategory,
  searchable: true,
  onChanged: (value) => setState(() => selectedCategory = value),
)
```

### 18. AppToast
토스트 알림 컴포넌트 (전역 사용)

```dart
// 기본 토스트
AppToast.info(
  context,
  "정보가 저장되었습니다",
  title: "저장 완료",
)

// 상태별 토스트
AppToast.success(context, "작업이 성공적으로 완료되었습니다");
AppToast.warning(context, "주의가 필요합니다");
AppToast.error(context, "오류가 발생했습니다");

// 액션이 있는 토스트
AppToast.show(
  context,
  "파일이 삭제되었습니다",
  type: ToastType.info,
  action: TextButton(
    onPressed: () => undoDelete(),
    child: Text("취소"),
  ),
)
```

### 19. AppPopover
팝오버 컴포넌트 (오버레이 콘텐츠 표시)

```dart
// 기본 팝오버
AppPopover(
  child: Icon(Icons.more_vert),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text("팝오버 제목", style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text("여기에 상세 내용이 들어갑니다."),
    ],
  ),
  position: PopoverPosition.bottom,
)

// 메뉴 팝오버
AppPopover.menu(
  child: ElevatedButton(
    onPressed: null,
    child: Text("메뉴"),
  ),
  items: [
    AppPopoverMenuItem(
      title: "편집",
      icon: Icons.edit,
      onTap: () => print("편집 선택됨"),
    ),
    AppPopoverMenuItem(
      title: "삭제",
      icon: Icons.delete,
      onTap: () => print("삭제 선택됨"),
    ),
  ],
)

// 정보 팝오버
AppPopover.info(
  child: Icon(Icons.help_outline),
  title: "도움말",
  description: "이 기능에 대한 설명입니다.",
  position: PopoverPosition.top,
)
```

### 20. AppSheet
바텀시트 및 사이드시트 컴포넌트

```dart
// 기본 바텀시트
AppSheet.showBottomSheet(
  context,
  title: "옵션 선택",
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: Icon(Icons.photo),
        title: Text("사진 선택"),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: Icon(Icons.camera),
        title: Text("카메라 촬영"),
        onTap: () => Navigator.pop(context),
      ),
    ],
  ),
)

// 메뉴 바텀시트
AppSheet.showMenu(
  context,
  title: "작업 선택",
  items: [
    AppSheetMenuItem(
      title: "공유하기",
      icon: Icons.share,
      onTap: () => print("공유"),
    ),
    AppSheetMenuItem(
      title: "즐겨찾기",
      icon: Icons.favorite,
      onTap: () => print("즐겨찾기"),
    ),
  ],
)

// 확인 다이얼로그 스타일 바텀시트
AppSheet.showConfirm(
  context,
  title: "삭제 확인",
  message: "정말로 이 항목을 삭제하시겠습니까?",
  onConfirm: () => print("삭제 확인"),
  onCancel: () => print("취소"),
)

// 사이드시트 (폼 입력용)
AppSheet.showSideSheet(
  context,
  title: "새 항목 추가",
  width: 400,
  child: Column(
    children: [
      TextField(decoration: InputDecoration(labelText: "제목")),
      SizedBox(height: 16),
      TextField(
        decoration: InputDecoration(labelText: "설명"),
        maxLines: 3,
      ),
    ],
  ),
)
```

### 21. AppCalendar & AppDatePicker
달력 및 날짜 선택 컴포넌트

```dart
// 단일 날짜 선택 달력
AppCalendar(
  selectedDate: selectedDate,
  onDateChanged: (date) => setState(() => selectedDate = date),
  selectionMode: CalendarSelectionMode.single,
  minDate: DateTime(2024, 1, 1),
  maxDate: DateTime(2024, 12, 31),
)

// 여러 날짜 선택 달력
AppCalendar(
  selectedDates: selectedDates,
  onDatesChanged: (dates) => setState(() => selectedDates = dates),
  selectionMode: CalendarSelectionMode.multiple,
)

// 날짜 범위 선택 달력
AppCalendar(
  selectedRange: selectedRange,
  onRangeChanged: (range) => setState(() => selectedRange = range),
  selectionMode: CalendarSelectionMode.range,
)

// 이벤트가 있는 달력
AppCalendar(
  selectedDate: selectedDate,
  onDateChanged: (date) => setState(() => selectedDate = date),
  events: {
    DateTime(2024, 8, 15): [
      CalendarEvent(
        title: "회의",
        color: Colors.blue,
        dateTime: DateTime(2024, 8, 15, 14, 0),
      ),
      CalendarEvent(
        title: "점심 약속",
        color: Colors.green,
        dateTime: DateTime(2024, 8, 15, 12, 0),
      ),
    ],
  },
)

// 날짜 선택 다이얼로그
final selectedDate = await AppDatePicker.show(
  context,
  title: "날짜를 선택하세요",
  initialDate: DateTime.now(),
  minDate: DateTime(2024, 1, 1),
  maxDate: DateTime(2024, 12, 31),
);

// 날짜 범위 선택 다이얼로그
final selectedRange = await AppDatePicker.showRange(
  context,
  title: "기간을 선택하세요",
  initialRange: DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(Duration(days: 7)),
  ),
);
```

## 디자인 토큰

컴포넌트들은 `AppColor` 클래스의 디자인 토큰을 사용합니다:

- **Primary Colors**: 주요 브랜드 컬러
- **Secondary Colors**: 텍스트 및 배경
- **Status Colors**: 성공, 경고, 오류 상태

## 커스터마이징

각 컴포넌트는 높은 수준의 커스터마이징을 지원합니다:

```dart
AppButton(
  text: "커스텀 버튼",
  variant: ButtonVariant.primary,
  size: ButtonSize.lg,
  icon: Icons.send,
  onPressed: () {},
)
```

## 확장 가능성

새로운 컴포넌트를 추가하려면:

1. 새 파일을 `lib/components/` 디렉토리에 생성
2. `index.dart`에 export 추가
3. shadcn/ui의 디자인 원칙을 따라 구현

## shadcn/ui 철학

- **Copy & Paste**: 필요에 따라 컴포넌트를 복사하여 수정
- **Customizable**: 모든 컴포넌트는 완전히 커스터마이징 가능
- **Accessible**: 접근성을 고려한 디자인
- **Composable**: 작은 컴포넌트들을 조합하여 복잡한 UI 구성
