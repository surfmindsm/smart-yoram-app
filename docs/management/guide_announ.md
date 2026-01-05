  웹 공지사항 구현 구조

  1. API 서비스 (announcementService.ts)

  웹에서는 두 가지 유형의 공지사항을 지원합니다:

  교회 공지사항 (교회 관리자용):
  // 공지사항 생성
  createAnnouncement(announcement: AnnouncementCreate)
  → POST /announcements/

  // 공지사항 수정
  updateAnnouncement(id, announcement)
  → PUT /announcements/{id}

  // 공지사항 삭제
  deleteAnnouncement(id)
  → DELETE /announcements/{id}

  // 공지사항 목록 조회
  getAnnouncementsAdmin()
  → GET /announcements/church-admin

  데이터 구조:
  interface AnnouncementCreate {
    title: string;              // 제목
    content: string;            // 내용
    category?: string;          // 카테고리 (worship, member_news, event)
    subcategory?: string;       // 하위 카테고리
    priority: 'urgent' | 'important' | 'normal';  // 우선순위
    target_type?: 'all' | 'specific' | 'single';  // 대상 타입
    target_church_ids?: number[];  // 대상 교회 IDs
    church_id?: number;         // 교회 ID
    start_date: string;         // 시작일 (YYYY-MM-DD)
    end_date?: string;          // 종료일
    is_active?: boolean;        // 활성 상태
  }

  2. UI 구현 (AnnouncementManagement.tsx)

  웹에서는 다음과 같은 흐름으로 구현되어 있습니다:

  공지사항 생성 과정:
  1. "새 공지사항" 버튼 클릭 → 모달 열림
  2. 폼 입력:
    - 제목 (필수)
    - 내용 (필수, Textarea)
    - 카테고리 선택 (예배/모임, 교우 소식, 행사/공지)
    - 대상 선택 (전체, 일반 교인, 청소년부, 리더)
    - 상단 고정 옵션 (is_pinned)
    - 활성화 옵션 (is_active)
  3. 저장 → API 호출 → 목록 새로고침

  핵심 코드 패턴:
  // 1. Church ID 가져오기 (로컬스토리지에서)
  const getChurchId = () => {
    const sessionStr = localStorage.getItem('supabase_session');
    if (sessionStr) {
      const session = JSON.parse(sessionStr);
      return session?.user?.church_id;
    }
    return 6; // 기본값
  };

  // 2. 공지사항 생성
  const handleSubmit = async (e) => {
    const submitData = {
      ...formData,
      church_id: churchId,
      author_id: 1,
      author_name: '관리자'
    };

    await supabaseApiService.announcements.create(submitData);
    // 성공 토스트 표시 + 목록 새로고침
  };

  3. 모바일 구현 가이드

  모바일에서 교회 관리자가 공지사항을 보낼 때 필요한 단계:

  1단계: API 연동
  // 백엔드 엔드포인트
  const API_BASE = 'https://your-api.com';

  // 공지사항 생성 함수
  async function createAnnouncement(data) {
    const response = await fetch(`${API_BASE}/announcements/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${userToken}`, // 인증 토큰
      },
      body: JSON.stringify({
        title: data.title,
        content: data.content,
        category: data.category || 'general',
        priority: data.priority || 'normal',
        start_date: data.start_date,
        is_active: true,
        church_id: userChurchId,  // 사용자의 교회 ID
        author_id: userId,
        author_name: userName
      })
    });

    return await response.json();
  }

  2단계: UI 화면 구성 (React Native 예시)
  // 필수 입력 필드
  - 제목 입력 (TextInput)
  - 내용 입력 (TextInput, multiline)
  - 카테고리 선택 (Picker/Dropdown)
    - 예배/모임 (worship)
    - 교우 소식 (member_news)
    - 행사/공지 (event)
  - 우선순위 선택 (Picker)
    - 긴급 (urgent)
    - 중요 (important)
    - 일반 (normal)
  - 시작일 선택 (DatePicker)
  - 저장 버튼

  3단계: 인증 정보
  // 로컬 저장소에서 필요한 정보
  - church_id: 사용자의 교회 ID
  - user_id: 사용자 ID
  - user_name: 사용자 이름
  - auth_token: API 호출용 인증 토큰

  4. 주요 API 엔드포인트

  모바일에서 필요한 API 목록:

  | 기능  | 메서드    | 엔드포인트                       | 설명           |
  |-----|--------|-----------------------------|--------------|
  | 생성  | POST   | /announcements/             | 새 공지사항 작성    |
  | 수정  | PUT    | /announcements/{id}         | 기존 공지사항 수정   |
  | 삭제  | DELETE | /announcements/{id}         | 공지사항 삭제      |
  | 목록  | GET    | /announcements/church-admin | 내 교회 공지사항 목록 |
  | 활성화 | PUT    | /announcements/{id}         | is_active 토글 |

  5. 참고할 웹 파일 위치

  모바일 개발 시 참고할 파일:
  - API 서비스: admin-dashboard/src/services/announcementService.ts:218-222
  - UI 컴포넌트: admin-dashboard/src/components/AnnouncementManagement.tsx:201-235
  - 데이터 모델: admin-dashboard/src/services/announcementService.ts:33-47

  모바일에서 이 구조를 따라 구현하시면 됩니다! 추가 질문이 있으시면 말씀해주세요.