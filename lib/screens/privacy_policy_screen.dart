import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/index.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';

/// 개인정보처리방침 — 1.2.0 C 방향
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: material.IconButton(
          icon: Icon(Icons.chevron_left,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '개인정보처리방침',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        actions: [
          material.IconButton(
            icon: Icon(Icons.copy_outlined,
                color: NewAppColor.textSecondary, size: 21.sp),
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: _getPrivacyPolicyText()));
              AppToast.success(context, '개인정보처리방침이 클립보드에 복사되었습니다');
            },
          ),
        ],
        shape: Border(
          bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBodyCard(),
            SizedBox(height: 12.h),
            _buildContactCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NewAppColor.borderHair, width: 1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        _getPrivacyPolicyText(),
        style: TextStyle(
          color: NewAppColor.textBody,
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NewAppColor.borderHair, width: 1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '개인정보보호 담당자',
            style: TextStyle(
              color: NewAppColor.textStrong,
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 12.h),
          _buildContactRow(Icons.person_outline, '담당자', '개인정보보호 담당자'),
          SizedBox(height: 8.h),
          _buildContactRow(Icons.mail_outline, '이메일', 'surfmind.sm@gmail.com'),
          SizedBox(height: 8.h),
          _buildContactRow(Icons.phone_outlined, '전화', '010-6617-1875'),
          SizedBox(height: 12.h),
          Container(height: 1, color: NewAppColor.borderHair),
          SizedBox(height: 12.h),
          Text(
            '개인정보와 관련한 문의사항이 있으시면 언제든지 연락주시기 바랍니다.',
            style: TextStyle(
              color: NewAppColor.textTertiary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15.sp, color: NewAppColor.textTertiary),
        SizedBox(width: 9.w),
        SizedBox(
          width: 56.w,
          child: Text(
            label,
            style: TextStyle(
              color: NewAppColor.textTertiary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: NewAppColor.textBody,
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }

  String _getPrivacyPolicyText() {
    return '''
1. 개인정보처리방침 개요

Church Round (이하 "앱")은 사용자의 개인정보를 중요하게 생각하며, 「개인정보보호법」을 준수하고 있습니다. 본 개인정보처리방침은 앱에서 수집하는 개인정보의 항목, 수집 및 이용목적, 보유 및 이용기간, 파기절차 등에 관한 사항을 안내드립니다.

2. 수집하는 개인정보의 항목 및 수집방법

2.1 카메라 권한 (android.permission.CAMERA)
- 수집목적: QR 코드 스캔을 통한 출석 체크, 교회 행사 및 학습 활동 사진 촬영, 교인 프로필 사진 등록
- 수집방법: 사용자가 QR 스캔 기능 사용 시 권한 요청
- 보관기간: 사용자가 삭제 요청 시까지

2.2 기타 수집 정보
- 기본 정보: 이름, 연락처, 이메일 주소
- 교회 관련 정보: 교회명, 출석 기록, 봉사 부서
- 기기 정보: 기기 식별자, 앱 버전, 운영체제 정보

3. 개인정보의 수집 및 이용목적

3.1 필수 수집 정보
- 회원 가입 및 본인 확인
- 교인 관리 및 교회 행정 업무
- 출석 체크 및 참여 활동 기록
- 교회 공지사항 및 행사 안내

3.2 선택적 수집 정보
- 맞춤형 서비스 제공
- 서비스 개선 및 신규 서비스 개발
- 통계 분석 및 시장 조사

4. 개인정보의 보유 및 이용기간

- 회원 탈퇴 시까지 보유
- 관련 법령에 의한 의무 보존 기간이 있는 경우 해당 기간
- 사용자가 삭제를 요청하는 경우 즉시 삭제

5. 개인정보의 파기절차 및 파기방법

5.1 파기절차
- 개인정보 보유기간 만료 시 30일 이내 파기
- 사용자 삭제 요청 시 즉시 파기
- 법적 의무 보존 기간 종료 시 즉시 파기

5.2 파기방법
- 전자적 파일: 복구 불가능한 방법으로 삭제
- 종이 문서: 분쇄 또는 소각

6. 개인정보의 안전성 확보조치

- 개인정보 암호화 저장
- 접근권한 관리 및 접근통제 시스템 운영
- 개인정보 취급 직원 최소화 및 교육 실시
- 보안프로그램 설치 및 갱신
- 개인정보 접근 기록 보관 및 위조·변조 방지

7. 개인정보 자동 수집 장치의 설치·운영 및 거부

앱은 사용자의 사용 패턴 분석을 위해 다음과 같은 기술을 사용할 수 있습니다:
- 앱 사용 통계 (Google Analytics)
- 오류 보고 (Firebase Crashlytics)

사용자는 이러한 기능을 앱 설정에서 거부할 수 있습니다.

8. 개인정보 처리의 위탁

현재 외부 업체에 개인정보 처리를 위탁하고 있지 않습니다. 향후 위탁이 필요한 경우 사전 동의를 구하겠습니다.

9. 정보주체의 권리·의무 및 그 행사방법

9.1 정보주체의 권리
- 개인정보 처리 현황 통지 요구
- 개인정보 열람 요구
- 개인정보 정정·삭제 요구
- 개인정보 처리 정지 요구

9.2 권리 행사 방법
- 서면, 전화, 이메일을 통한 요청
- 앱 내 설정 메뉴를 통한 직접 처리
- 개인정보보호 담당자에게 직접 연락

10. 개인정보보호 담당자

담당자: 개인정보보호 담당자
이메일: surfmind.sm@gmail.com
전화: 010-6617-1875

11. 개인정보처리방침 변경

본 개인정보처리방침은 법령·정책 또는 보안기술의 변경에 따라 내용의 추가·삭제 및 수정이 있을 시에는 변경사항의 시행 7일 전부터 공지사항을 통하여 고지할 것입니다.

12. 기타

본 개인정보처리방침은 2024년 7월 30일부터 적용됩니다.
''';
  }
}
