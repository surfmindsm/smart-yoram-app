import '../services/supabase_service.dart';

/// 교회학교 관련 데이터 구조 확인용 스크립트
/// 사용법: 앱 내에서 호출하여 콘솔 로그 확인
class MemberDataChecker {
  static Future<void> checkMemberData() async {
    final supabase = SupabaseService().client;

    try {
      print('📊 ===== 교회학교 데이터 구조 확인 시작 =====\n');

      // members 테이블에서 교회학교 관련 데이터 조회 (position_category 제외 - 컬럼 없음)
      final response = await supabase
          .from('members')
          .select('name, position_main, position_detail, department, age_group, birthdate')
          .limit(500);

      print('✅ 전체 조회된 교인 수: ${response.length}\n');

      // 부서별 분류
      final Map<String, int> departmentCount = {};
      final Map<String, int> ageGroupCount = {};
      final Map<String, int> positionMainCount = {};
      final Map<String, int> positionDetailCount = {};

      for (var member in response) {
        final dept = member['department']?.toString() ?? 'null';
        final ageGroup = member['age_group']?.toString() ?? 'null';
        final posMain = member['position_main']?.toString() ?? 'null';
        final posDetail = member['position_detail']?.toString() ?? 'null';

        departmentCount[dept] = (departmentCount[dept] ?? 0) + 1;
        ageGroupCount[ageGroup] = (ageGroupCount[ageGroup] ?? 0) + 1;
        positionMainCount[posMain] = (positionMainCount[posMain] ?? 0) + 1;
        positionDetailCount[posDetail] = (positionDetailCount[posDetail] ?? 0) + 1;
      }

      print('📋 === Department (부서) 분포 ===');
      departmentCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..forEach((entry) {
          print('  ${entry.key.padRight(20)}: ${entry.value}명');
        });

      print('\n📋 === Position Main (주 직분) 분포 ===');
      positionMainCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..forEach((entry) {
          print('  ${entry.key.padRight(20)}: ${entry.value}명');
        });

      print('\n📋 === Position Detail (상세 직분) 분포 ===');
      positionDetailCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..forEach((entry) {
          print('  ${entry.key.padRight(20)}: ${entry.value}명');
        });

      print('\n📋 === Age Group (연령대) 분포 ===');
      ageGroupCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..forEach((entry) {
          print('  ${entry.key.padRight(20)}: ${entry.value}명');
        });

      // 교회학교 관련 샘플 데이터 출력 (position_main = 'CHURCH_SCHOOL')
      print('\n👶 === 교회학교(position_main=CHURCH_SCHOOL) 샘플 (최대 20명) ===');
      final churchSchoolSamples = response
          .where((m) => m['position_main'] == 'CHURCH_SCHOOL')
          .take(20)
          .toList();

      if (churchSchoolSamples.isEmpty) {
        print('  ⚠️ position_main=CHURCH_SCHOOL 데이터 없음');
      } else {
        for (int i = 0; i < churchSchoolSamples.length; i++) {
          final m = churchSchoolSamples[i];
          print('  ${i + 1}. ${m['name']?.toString().padRight(10)} - dept: ${m['department']}, age_group: ${m['age_group']}, pos_detail: ${m['position_detail']}');
        }
      }

      // CHILDREN 부서 데이터 (department에 '부' 포함)
      print('\n🏫 === Department에 "부"가 포함된 교인 샘플 (최대 20명) ===');
      final schoolDeptSamples = response
          .where((m) {
            final dept = m['department']?.toString() ?? '';
            return dept.contains('부') || dept.contains('교회학교');
          })
          .take(20)
          .toList();

      if (schoolDeptSamples.isEmpty) {
        print('  ⚠️ Department에 "부" 포함 데이터 없음');
      } else {
        for (int i = 0; i < schoolDeptSamples.length; i++) {
          final m = schoolDeptSamples[i];
          print('  ${i + 1}. ${m['name']?.toString().padRight(10)} - dept: ${m['department']}, age_group: ${m['age_group']}, pos_main: ${m['position_main']}, pos_detail: ${m['position_detail']}');
        }
      }

      print('\n✅ ===== 데이터 구조 확인 완료 =====\n');

    } catch (e, stackTrace) {
      print('❌ 데이터 조회 실패: $e');
      print('스택 트레이스: $stackTrace');
    }
  }
}
