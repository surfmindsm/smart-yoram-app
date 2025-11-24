# 명설교 기능 API 연동 가이드 (Flutter)

## 개요
모바일 앱에서 관리자가 등록한 유튜브 설교 영상을 모든 교인들이 시청할 수 있는 기능입니다.

## 🚀 빠른 시작

가장 중요한 3가지:

1. **Supabase 클라이언트 사용**:
   ```dart
   import 'package:supabase_flutter/supabase_flutter.dart';

   final supabase = Supabase.instance.client;
   ```

2. **활성화된 설교만 조회**:
   ```dart
   .eq('is_active', true)
   ```

3. **유튜브 플레이어 임베딩**:
   ```dart
   import 'package:youtube_player_flutter/youtube_player_flutter.dart';

   YoutubePlayer(
     controller: YoutubePlayerController(
       initialVideoId: sermon.youtubeVideoId,
     ),
   )
   ```

## Base URL
```
직접 Supabase 테이블 쿼리 사용
```

## 데이터베이스 테이블

### `sermons` 테이블 (메인)

| 컬럼 | 타입 | 필수 | 설명 | 기본값 |
|------|------|------|------|--------|
| id | UUID | ✅ | 설교 ID (PK) | gen_random_uuid() |
| title | VARCHAR(255) | ✅ | 설교 제목 | - |
| youtube_url | TEXT | ✅ | 유튜브 전체 URL | - |
| youtube_video_id | VARCHAR(20) | ✅ | 유튜브 비디오 ID | - |
| preacher_name | VARCHAR(100) | ❌ | 설교자 이름 | null |
| description | TEXT | ❌ | 설교 설명/요약 | null |
| thumbnail_url | TEXT | ❌ | 썸네일 URL (자동 생성) | null |
| duration_seconds | INTEGER | ❌ | 영상 길이 (초) | null |
| view_count | INTEGER | ✅ | 조회수 | 0 |
| category | VARCHAR(50) | ❌ | 카테고리 | null |
| sermon_date | DATE | ❌ | 설교 날짜 | null |
| is_featured | BOOLEAN | ✅ | 추천 설교 여부 | false |
| display_order | INTEGER | ✅ | 표시 순서 | 0 |
| is_active | BOOLEAN | ✅ | 활성화 여부 | true |
| created_at | TIMESTAMP | ✅ | 생성 시간 | NOW() |
| updated_at | TIMESTAMP | ✅ | 수정 시간 | NOW() |
| created_by | UUID | ❌ | 등록자 | null |
| updated_by | UUID | ❌ | 수정자 | null |

### category 값
- `주일설교`
- `수요예배`
- `금요기도회`
- `새벽기도회`
- `특별집회`
- `부흥회`
- `전도집회`
- `성경공부`

---

## 1. 전체 설교 목록 조회 (GET)

### Flutter 코드 예시
```dart
Future<List<Sermon>> getSermons({
  int skip = 0,
  int limit = 50,
  String? category,
  bool? isFeatured,
  bool onlyActive = true,
  String sortBy = 'created_at',
  String sortOrder = 'desc',
}) async {
  try {
    var query = supabase.from('sermons').select('*');

    // 필터 적용
    if (onlyActive) {
      query = query.eq('is_active', true);
    }
    if (category != null) {
      query = query.eq('category', category);
    }
    if (isFeatured != null) {
      query = query.eq('is_featured', isFeatured);
    }

    // 정렬
    if (isFeatured == true) {
      query = query.order('display_order', ascending: true);
    } else {
      query = query.order(sortBy, ascending: sortOrder == 'asc');
    }

    // 페이지네이션
    if (limit > 0) {
      query = query.limit(limit);
    }
    if (skip > 0) {
      query = query.range(skip, skip + limit - 1);
    }

    final response = await query;

    final sermons = (response as List)
        .map((item) => Sermon.fromJson(item as Map<String, dynamic>))
        .toList();

    return sermons;
  } catch (e) {
    throw Exception('설교 목록을 불러올 수 없습니다: $e');
  }
}
```

### 쿼리 파라미터
| 파라미터 | 타입 | 필수 | 설명 | 기본값 |
|----------|------|------|------|--------|
| skip | int | ❌ | 건너뛸 항목 수 (페이지네이션) | 0 |
| limit | int | ❌ | 가져올 항목 수 | 50 |
| category | String | ❌ | 카테고리 필터 | null |
| isFeatured | bool | ❌ | 추천 설교 여부 필터 | null |
| onlyActive | bool | ❌ | 활성화된 것만 조회 | true |
| sortBy | String | ❌ | 정렬 필드 | 'created_at' |
| sortOrder | String | ❌ | 정렬 순서 (asc/desc) | 'desc' |

### 응답 예시
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "은혜와 진리가 충만하신 예수",
    "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "youtube_video_id": "dQw4w9WgXcQ",
    "preacher_name": "김목사",
    "description": "요한복음 1장을 통해 살펴보는 예수님의 은혜와 진리",
    "thumbnail_url": null,
    "duration_seconds": null,
    "view_count": 1234,
    "category": "주일설교",
    "sermon_date": "2024-01-07",
    "is_featured": true,
    "display_order": 1,
    "is_active": true,
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
]
```

---

## 2. 추천 설교 조회 (GET)

### Flutter 코드 예시
```dart
Future<List<Sermon>> getFeaturedSermons({int limit = 5}) async {
  try {
    final response = await supabase
        .from('sermons')
        .select('*')
        .eq('is_active', true)
        .eq('is_featured', true)
        .order('display_order', ascending: true)
        .limit(limit);

    final sermons = (response as List)
        .map((item) => Sermon.fromJson(item as Map<String, dynamic>))
        .toList();

    return sermons;
  } catch (e) {
    throw Exception('추천 설교를 불러올 수 없습니다: $e');
  }
}
```

---

## 3. 카테고리별 설교 조회 (GET)

### Flutter 코드 예시
```dart
Future<List<Sermon>> getSermonsByCategory(
  String category, {
  int limit = 20,
}) async {
  try {
    final response = await supabase
        .from('sermons')
        .select('*')
        .eq('is_active', true)
        .eq('category', category)
        .order('sermon_date', ascending: false)
        .limit(limit);

    final sermons = (response as List)
        .map((item) => Sermon.fromJson(item as Map<String, dynamic>))
        .toList();

    return sermons;
  } catch (e) {
    throw Exception('카테고리별 설교를 불러올 수 없습니다: $e');
  }
}
```

---

## 4. 특정 설교 상세 조회 (GET)

### Flutter 코드 예시
```dart
Future<Sermon> getSermon(String id) async {
  try {
    final response = await supabase
        .from('sermons')
        .select('*')
        .eq('id', id)
        .single();

    return Sermon.fromJson(response);
  } catch (e) {
    throw Exception('설교를 불러올 수 없습니다: $e');
  }
}
```

---

## 5. 조회수 증가 (POST)

### Flutter 코드 예시
```dart
Future<void> incrementViewCount(String id) async {
  try {
    // 현재 조회수 가져오기
    final sermon = await getSermon(id);
    final newViewCount = sermon.viewCount + 1;

    // 조회수 업데이트
    await supabase
        .from('sermons')
        .update({'view_count': newViewCount})
        .eq('id', id);

    log('조회수 증가 완료: $newViewCount');
  } catch (e) {
    log('조회수 증가 오류: $e');
    // 조회수 증가 실패는 무시 (사용자 경험에 영향 없음)
  }
}
```

**참고:** 설교를 재생할 때 한 번만 호출하세요.

---

## 6. 카테고리 목록 조회 (GET)

### Flutter 코드 예시
```dart
Future<List<String>> getCategories() async {
  try {
    final response = await supabase
        .from('sermons')
        .select('category')
        .eq('is_active', true)
        .not('category', 'is', null);

    // 중복 제거 및 정렬
    final categories = (response as List)
        .map((item) => item['category'] as String)
        .toSet()
        .toList()
      ..sort();

    return categories;
  } catch (e) {
    log('카테고리 조회 오류: $e');
    // 기본 카테고리 반환
    return ['주일설교', '수요예배', '특별집회'];
  }
}
```

---

## 사용 예시

### 완전한 SermonService 클래스
```dart
import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class SermonService {
  final supabase = Supabase.instance.client;

  // 설교 목록 조회
  Future<List<Sermon>> getSermons({
    int skip = 0,
    int limit = 50,
    String? category,
    bool? isFeatured,
    bool onlyActive = true,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    // 위의 코드 참조
  }

  // 추천 설교 조회
  Future<List<Sermon>> getFeaturedSermons({int limit = 5}) async {
    // 위의 코드 참조
  }

  // 카테고리별 조회
  Future<List<Sermon>> getSermonsByCategory(
    String category, {
    int limit = 20,
  }) async {
    // 위의 코드 참조
  }

  // 특정 설교 조회
  Future<Sermon> getSermon(String id) async {
    // 위의 코드 참조
  }

  // 조회수 증가
  Future<void> incrementViewCount(String id) async {
    // 위의 코드 참조
  }

  // 카테고리 목록
  Future<List<String>> getCategories() async {
    // 위의 코드 참조
  }

  // 유튜브 URL에서 비디오 ID 추출
  static String? extractYoutubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);

      // youtube.com/watch?v=VIDEO_ID
      if (uri.host.contains('youtube.com') &&
          uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }

      // youtu.be/VIDEO_ID
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }

      // youtube.com/embed/VIDEO_ID
      if (uri.host.contains('youtube.com') &&
          uri.pathSegments.length >= 2 &&
          uri.pathSegments[0] == 'embed') {
        return uri.pathSegments[1];
      }

      return null;
    } catch (e) {
      log('유튜브 비디오 ID 추출 오류: $e');
      return null;
    }
  }
}
```

### 화면 예시
```dart
class SermonsScreen extends StatefulWidget {
  const SermonsScreen({super.key});

  @override
  State<SermonsScreen> createState() => _SermonsScreenState();
}

class _SermonsScreenState extends State<SermonsScreen> {
  final SermonService _sermonService = SermonService();
  List<Sermon> _sermons = [];
  List<Sermon> _featuredSermons = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _sermonService.getFeaturedSermons(),
        _sermonService.getSermons(),
        _sermonService.getCategories(),
      ]);

      setState(() {
        _featuredSermons = results[0] as List<Sermon>;
        _sermons = results[1] as List<Sermon>;
        _categories = results[2] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // 에러 처리
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // 추천 설교 섹션
          if (_featuredSermons.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildFeaturedSermons(),
            ),
          ],

          // 카테고리 필터
          SliverToBoxAdapter(
            child: _buildCategoryFilter(),
          ),

          // 전체 설교 리스트
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => SermonCard(sermon: _sermons[index]),
              childCount: _sermons.length,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 유튜브 플레이어 사용
```dart
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SermonDetailScreen extends StatefulWidget {
  final Sermon sermon;

  const SermonDetailScreen({super.key, required this.sermon});

  @override
  State<SermonDetailScreen> createState() => _SermonDetailScreenState();
}

class _SermonDetailScreenState extends State<SermonDetailScreen> {
  late YoutubePlayerController _controller;
  final SermonService _sermonService = SermonService();

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.sermon.youtubeVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
      ),
    );
    _incrementViewCount();
  }

  Future<void> _incrementViewCount() async {
    await _sermonService.incrementViewCount(widget.sermon.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text('명설교')),
          body: Column(
            children: [
              player, // 유튜브 플레이어
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sermon.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (widget.sermon.preacherName != null)
                        Text(widget.sermon.preacherName!),
                      if (widget.sermon.description != null)
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(widget.sermon.description!),
                        ),
                      // 기타 정보
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 주의사항

1. **RLS (Row Level Security)**:
   - Supabase RLS 정책에 따라 `is_active = true`인 설교만 조회 가능
   - 앱에서는 **SELECT만** 사용 (INSERT/UPDATE/DELETE는 관리자만 가능)

2. **썸네일 자동 생성**:
   ```dart
   String getThumbnailUrl(Sermon sermon, {String quality = 'hqdefault'}) {
     if (sermon.thumbnailUrl != null && sermon.thumbnailUrl!.isNotEmpty) {
       return sermon.thumbnailUrl!;
     }
     // 유튜브 썸네일 자동 생성
     return 'https://img.youtube.com/vi/${sermon.youtubeVideoId}/$quality.jpg';
   }
   ```
   - quality 옵션: `default`, `mqdefault`, `hqdefault`, `sddefault`, `maxresdefault`

3. **조회수 중복 방지**:
   - 설교 상세 화면 진입 시 한 번만 호출
   - 중복 호출을 막기 위해 플래그 사용 권장

4. **에러 처리**:
   ```dart
   try {
     final sermons = await _sermonService.getSermons();
   } catch (e) {
     // 사용자에게 에러 메시지 표시
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('설교를 불러올 수 없습니다')),
     );
   }
   ```

5. **오프라인 지원**:
   - 유튜브 영상은 스트리밍 방식이므로 오프라인 재생 불가
   - 설교 메타데이터(제목, 설명 등)는 캐싱 가능

6. **성능 최적화**:
   - 페이지네이션 사용 (limit, skip)
   - 캐싱 전략 적용 (10분 간격 권장)
   - 썸네일 이미지 lazy loading

---

## Dart 모델 클래스

```dart
class Sermon {
  final String id;
  final String title;
  final String youtubeUrl;
  final String youtubeVideoId;
  final String? preacherName;
  final String? description;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int viewCount;
  final String? category;
  final DateTime? sermonDate;
  final bool isFeatured;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Sermon({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    this.preacherName,
    this.description,
    this.thumbnailUrl,
    this.durationSeconds,
    this.viewCount = 0,
    this.category,
    this.sermonDate,
    this.isFeatured = false,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      id: json['id'] as String,
      title: json['title'] as String,
      youtubeUrl: json['youtube_url'] as String,
      youtubeVideoId: json['youtube_video_id'] as String,
      preacherName: json['preacher_name'] as String?,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      viewCount: json['view_count'] as int? ?? 0,
      category: json['category'] as String?,
      sermonDate: json['sermon_date'] != null
          ? DateTime.parse(json['sermon_date'] as String)
          : null,
      isFeatured: json['is_featured'] as bool? ?? false,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'youtube_url': youtubeUrl,
      'youtube_video_id': youtubeVideoId,
      'preacher_name': preacherName,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'view_count': viewCount,
      'category': category,
      'sermon_date': sermonDate?.toIso8601String(),
      'is_featured': isFeatured,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
```

---

## 트러블슈팅

### 자주 발생하는 에러

#### 1. "No rows found" 에러
```
PostgrestException(message: No rows found, code: PGRST116)
```
**원인**: 조회 조건에 맞는 데이터가 없음
**해결**:
- `is_active = true` 필터 확인
- 데이터베이스에 실제 데이터가 있는지 확인

#### 2. "Invalid JWT" 에러
```
PostgrestException(message: Invalid JWT, code: ...)
```
**원인**: Supabase 인증 토큰 문제
**해결**: Supabase 클라이언트 초기화 확인

#### 3. 유튜브 플레이어 오류
```
YouTube player error
```
**원인**: 잘못된 비디오 ID 또는 비공개 영상
**해결**:
- `youtube_video_id` 값 확인
- 유튜브 영상이 공개 상태인지 확인
- 네트워크 연결 확인

---

## 문의

API 연동 중 문제가 발생하면 백엔드 개발팀에 문의하세요.

### 디버깅 팁
1. Supabase Dashboard → Table Editor에서 데이터 확인
2. Flutter DevTools → Network에서 쿼리 확인
3. `dart:developer`의 `log()` 함수로 디버그 로그 출력

---

**작성일:** 2024-11-24
**버전:** 1.0
**담당자:** 백엔드 개발팀
