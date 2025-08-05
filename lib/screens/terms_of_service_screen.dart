import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('서비스 이용약관'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // 이용약관 텍스트 복사
              Clipboard.setData(ClipboardData(text: _getTermsOfServiceText()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('서비스 이용약관이 클립보드에 복사되었습니다')),
              );
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 정보

            const SizedBox(height: 20),

            // 본문 내용
            Text(
              _getTermsOfServiceText(),
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // 연락처 정보
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '문의 및 연락처',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '새생명교회\n'
                    '주소: 서울시 강남구\n'
                    '전화: 02-123-4567\n'
                    '이메일: info@newlife-church.org',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTermsOfServiceText() {
    return '''제1조 (목적)
본 약관은 새생명교회(이하 "교회")가 제공하는 Smart Yoram 모바일 애플리케이션(이하 "서비스") 이용과 관련하여 교회와 이용자 간의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.

제2조 (정의)
본 약관에서 사용하는 용어의 정의는 다음과 같습니다.
1. "서비스"란 교회가 제공하는 Smart Yoram 모바일 애플리케이션을 통해 제공되는 모든 서비스를 의미합니다.
2. "이용자"란 본 약관에 따라 서비스를 이용하는 교인 및 방문자를 의미합니다.
3. "교인"이란 새생명교회에 등록된 모든 교인을 의미합니다.
4. "계정"이란 이용자가 서비스 이용을 위해 등록한 개인정보를 의미합니다.

제3조 (약관의 효력 및 변경)
1. 본 약관은 서비스 화면에 게시하거나 기타의 방법으로 이용자에게 공지함으로써 효력이 발생합니다.
2. 교회는 필요에 따라 관련 법령을 위배하지 않는 범위에서 본 약관을 개정할 수 있습니다.
3. 약관이 변경되는 경우 교회는 변경된 약관을 적용하고자 하는 날로부터 최소 7일 이전에 공지합니다.

제4조 (서비스의 제공)
교회는 다음과 같은 서비스를 제공합니다.
1. 교회 공지사항 및 주보 열람 서비스
2. 교인 출석 관리 서비스
3. 교인 정보 관리 서비스
4. 가족 관계 관리 서비스
5. 교회 행사 및 일정 안내 서비스
6. SMS 발송 서비스
7. 교회 통계 및 현황 조회 서비스
8. 기타 교회가 필요하다고 인정하는 서비스

제5조 (서비스 이용 신청 및 승인)
1. 서비스 이용을 희망하는 자는 교회에서 요구하는 정보를 제공하여 이용신청을 해야 합니다.
2. 교회는 다음 각 호에 해당하는 경우 이용신청을 거부할 수 있습니다.
   - 실명이 아니거나 타인의 명의를 이용한 경우
   - 허위의 정보를 기재하거나 교회가 제시하는 내용을 기재하지 않은 경우
   - 관련 법령에 위배되거나 사회의 안녕질서 및 미풍양속을 저해할 목적으로 신청한 경우

제6조 (이용자의 의무)
1. 이용자는 다음 행위를 하여서는 안 됩니다.
   - 신청 또는 변경 시 허위 내용의 등록
   - 타인의 정보 도용
   - 교회가 게시한 정보의 변경
   - 교회가 정한 정보 이외의 정보(컴퓨터 프로그램 등) 등의 송신 또는 게시
   - 교회 기타 제3자의 저작권 등 지적재산권에 대한 침해
   - 교회 기타 제3자의 명예를 손상시키거나 업무를 방해하는 행위
   - 외설 또는 폭력적인 메시지, 화상, 음성, 기타 공서양속에 반하는 정보를 서비스에 공개 또는 게시하는 행위

제7조 (서비스의 중단)
1. 교회는 컴퓨터 등 정보통신설비의 보수점검, 교체 및 고장, 통신의 두절 등의 사유가 발생한 경우에는 서비스의 제공을 일시적으로 중단할 수 있습니다.
2. 교회는 제1항의 사유로 서비스의 제공이 중단된 것에 대하여 이용자 또는 제3자가 입은 손해에 대해 배상하지 않습니다.

제8조 (개인정보보호)
교회는 이용자의 개인정보를 보호하기 위해 개인정보처리방침을 수립하여 시행하고 있으며, 관련 법령에 따라 이용자의 개인정보를 보호합니다.

제9조 (면책조항)
1. 교회는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다.
2. 교회는 이용자의 귀책사유로 인한 서비스 이용의 장애에 대하여는 책임을 지지 않습니다.
3. 교회는 이용자가 서비스를 이용하여 기대하는 수익을 얻지 못하거나 상실한 것에 대하여는 책임을 지지 않습니다.

제10조 (분쟁해결)
1. 교회는 이용자가 제기하는 정당한 의견이나 불만을 반영하고 그 피해를 보상처리하기 위하여 피해보상처리기구를 설치·운영합니다.
2. 서비스 이용으로 발생한 분쟁에 대해 소송이 제기될 경우 교회의 소재지를 관할하는 법원을 관할 법원으로 합니다.

제11조 (기타)
1. 본 약관은 대한민국의 법률에 따라 규율되고 해석됩니다.
2. 본 약관에서 정하지 아니한 사항과 본 약관의 해석에 관하여는 관련법령 또는 상관례에 따릅니다.

부 칙
본 약관은 2024년 1월 1일부터 시행합니다.''';
  }
}
