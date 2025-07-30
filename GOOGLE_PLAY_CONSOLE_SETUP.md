# Google Play Console 개인정보처리방침 설정 가이드

## 🚨 CAMERA 권한 개인정보처리방침 오류 해결 방법

### 1. Google Play Console 접속 및 앱 선택
1. [Google Play Console](https://play.google.com/console) 로그인
2. Smart Yoram 앱 선택

### 2. 개인정보처리방침 URL 설정
**경로**: 정책 > 앱 콘텐츠 > 개인정보처리방침

**설정할 내용**:
- 개인정보처리방침 URL: **앱 내부에서 제공** (별도 URL 불필요)
- 또는 임시 URL: `https://smartyoram.com/privacy-policy`

### 3. 데이터 보안 섹션 설정 (가장 중요!)
**경로**: 정책 > 데이터 보안

#### 3.1 데이터 수집 및 공유
**"앱에서 사용자 데이터를 수집하거나 공유하나요?"** → **예**

#### 3.2 카메라 관련 설정
**"다음 중 앱에서 수집하거나 공유하는 데이터 유형은 무엇인가요?"**

✅ **사진 및 동영상** 선택

**사진 및 동영상 데이터에 대한 세부 설정**:

1. **데이터 수집 여부**: ✅ 수집됨
2. **데이터 공유 여부**: ❌ 공유 안 함
3. **수집 목적**:
   - ✅ 앱 기능
   - ❌ 광고 또는 마케팅
   - ❌ 분석

4. **필수 또는 선택 사항**: ✅ 선택 사항 (사용자가 거부 가능)

#### 3.3 권한 설명 작성
**카메라 권한 사용 설명 (영문)**:
```
Camera permission is used for:
• QR code scanning for church attendance tracking
• Taking photos of church events and activities
• Registering member profile pictures

All photos are stored only with explicit user consent and used solely for church management purposes. No data is shared with third parties.
```

**카메라 권한 사용 설명 (한국어)**:
```
카메라 권한은 다음 목적으로 사용됩니다:
• 교회 출석 체크를 위한 QR 코드 스캔
• 교회 행사 및 활동 사진 촬영
• 교인 프로필 사진 등록

모든 사진은 사용자의 명시적 동의 하에서만 저장되며, 교회 관리 목적으로만 사용됩니다. 제3자와 데이터를 공유하지 않습니다.
```

### 4. 권한 선언 확인
다음 권한들이 앱에서 올바르게 선언되었는지 확인:

- ✅ `android.permission.CAMERA` (선택적)
- ✅ `android.permission.FLASHLIGHT` (선택적)
- ✅ `android.hardware.camera` (하드웨어 기능, 선택적)

### 5. 앱 내 개인정보처리방침 확인
앱 내에서 다음 경로로 개인정보처리방침에 접근 가능한지 확인:
**설정 > 개인정보 처리방침**

### 6. 데이터 보안 인증서 제출
**개인정보처리방침 및 데이터 보안 양식 작성 완료 후**:
1. "데이터 보안 양식 검토" 클릭
2. 모든 정보 확인 후 "제출" 클릭

### 7. 앱 업데이트 및 검토 요청
1. 새로운 AAB 파일 업로드: `app-release.aab`
2. 릴리스 노트에 개인정보처리방침 업데이트 내용 명시
3. 검토 요청

### 8. 일반적인 해결책

#### 문제가 지속되는 경우:
1. **앱 내 권한 요청 다이얼로그 확인**
   - 카메라 권한 요청 시 상세한 설명이 표시되는지 확인
   - 사용자가 "거부" 선택 시에도 앱이 정상 작동하는지 확인

2. **실제 개인정보처리방침 URL 제공**
   ```
   임시 개인정보처리방침 페이지:
   https://sites.google.com/view/smartyoram-privacy-policy
   ```

3. **앱 스토어 설명 업데이트**
   앱 설명에 개인정보 보호 관련 내용 추가:
   ```
   개인정보 보호:
   - 카메라는 QR 스캔 및 프로필 사진 등록 목적으로만 사용
   - 사용자 동의 없이 데이터 수집하지 않음
   - 제3자와 개인정보 공유하지 않음
   ```

### 9. 연락처 정보
**개인정보보호 담당자**: privacy@smartyoram.com

### 10. 체크리스트
앱 제출 전 다음 사항들을 확인하세요:

- [ ] Google Play Console 데이터 보안 섹션 완료
- [ ] 카메라 권한에 대한 상세 설명 작성
- [ ] 앱 내 개인정보처리방침 페이지 구현
- [ ] 권한 요청 시 명확한 설명 제공
- [ ] 사용자가 권한을 거부해도 앱 기본 기능 사용 가능
- [ ] AAB 파일에 모든 메타데이터 포함 확인

---

**참고**: Google Play Console 정책은 수시로 변경될 수 있으므로, 제출 전 최신 정책을 확인하시기 바랍니다.

**최종 업데이트**: 2024년 7월 30일
