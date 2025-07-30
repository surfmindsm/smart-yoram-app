// 위젯 오류 수정을 위한 임시 스크립트
// 이 파일은 컴파일 오류 수정 후 삭제할 예정입니다.

/* 
주요 수정 패턴:

1. CommonDialog.error() → AlertDialog로 변경
2. StatCard에 color 파라미터 추가
3. EmptyStateWidget의 message → title로 변경  
4. CustomFormField의 labelText → label로 변경
5. IconData → Icon() 위젯으로 변경
6. CustomDropdownField에서 prefixIcon 제거

수정해야 할 파일들:
- family_management_screen.dart
- sms_management_screen.dart  
- excel_management_screen.dart
- statistics_dashboard_screen.dart

각 파일에서 다음 패턴들을 찾아 수정:

StatCard( → StatCard( + color: Colors.적절한색상,
message: → title:
labelText: → label:
Icons.아이콘명 → const Icon(Icons.아이콘명)
CommonDialog.error( → AlertDialog( + 전체 구조 변경
prefixIcon: (CustomDropdownField에서) → 제거
*/

void main() {
  print('이 스크립트는 위젯 오류 수정 가이드입니다.');
  print('각 파일을 수동으로 수정해야 합니다.');
}
