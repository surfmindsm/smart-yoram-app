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
