# 포트폴리오 파일 업로드 버킷 변경 방법

## 현재 문제
`community-images` 버킷이 이미지 파일만 허용하도록 설정되어 있어 PDF, MP3, MP4 등의 파일 업로드가 실패합니다.

## 해결 방법

### 방법 1: community-images 버킷 설정 변경 (권장)

1. Supabase 대시보드 → Storage → community-images
2. Configuration 탭
3. Allowed MIME types에 다음 추가:
   - `application/pdf`
   - `application/msword`
   - `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
   - `audio/mpeg`
   - `video/mp4`
   - `video/quicktime`

   또는 모든 타입 허용: `*/*`

### 방법 2: 새 버킷 생성 (community-files)

Supabase SQL Editor에서 실행:

```sql
-- 1. community-files 버킷 생성
INSERT INTO storage.buckets (id, name, public)
VALUES ('community-files', 'community-files', true);

-- 2. 모든 인증된 사용자가 업로드 가능하도록 설정
CREATE POLICY "Allow authenticated users to upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'community-files');

-- 3. 모든 사용자가 읽기 가능
CREATE POLICY "Allow public read access"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'community-files');

-- 4. 작성자가 삭제 가능
CREATE POLICY "Allow users to delete own files"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'community-files' AND auth.uid()::text = owner::text);
```

그 후 코드 수정 (community_create_screen.dart:3704, 3712):
```dart
// 변경 전
.from('community-images')

// 변경 후
.from('community-files')
```

## 권장 사항

**방법 1**을 권장합니다. 단순히 버킷 설정만 변경하면 되므로 코드 수정이 필요 없습니다.
