/// 한글 초성 검색 유틸리티
class KoreanSearchUtil {
  // 한글 초성 목록
  static const List<String> _chosungs = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ',
    'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
  ];

  /// 한글 문자의 초성을 추출
  /// 예: '김' -> 'ㄱ', '박' -> 'ㅂ'
  static String? getChosung(String char) {
    if (char.isEmpty) return null;

    final code = char.codeUnitAt(0);

    // 한글 음절 범위: 0xAC00(가) ~ 0xD7A3(힣)
    if (code >= 0xAC00 && code <= 0xD7A3) {
      final chosungIndex = (code - 0xAC00) ~/ 588;
      return _chosungs[chosungIndex];
    }

    // 이미 초성인 경우
    if (_chosungs.contains(char)) {
      return char;
    }

    return null;
  }

  /// 문자열의 모든 문자를 초성으로 변환
  /// 예: '김현수' -> 'ㄱㅎㅅ'
  static String getChosungString(String text) {
    final result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final chosung = getChosung(text[i]);
      if (chosung != null) {
        result.write(chosung);
      } else {
        // 한글이 아닌 경우 원래 문자 유지
        result.write(text[i]);
      }
    }

    return result.toString();
  }

  /// 검색어가 초성인지 확인
  /// 예: 'ㄱㅎㅅ' -> true, '김현수' -> false, 'ㄱ현ㅅ' -> true (혼합도 초성 검색으로 간주)
  static bool isChosungQuery(String query) {
    if (query.isEmpty) return false;

    // 하나라도 초성이 포함되어 있으면 초성 검색으로 간주
    for (int i = 0; i < query.length; i++) {
      if (_chosungs.contains(query[i])) {
        return true;
      }
    }

    return false;
  }

  /// 초성 검색 매칭
  /// targetText에서 chosungQuery가 초성 패턴으로 매칭되는지 확인
  /// 예: matchChosung('김현수', 'ㄱㅎㅅ') -> true
  ///     matchChosung('김현수', 'ㄱㅎ') -> true (부분 매칭)
  ///     matchChosung('김현수', 'ㄱㅅ') -> false (연속되지 않음)
  static bool matchChosung(String targetText, String chosungQuery) {
    if (targetText.isEmpty || chosungQuery.isEmpty) return false;

    final targetChosung = getChosungString(targetText);

    // 초성으로 변환된 문자열에서 검색어가 포함되는지 확인
    return targetChosung.contains(chosungQuery);
  }

  /// 통합 검색 함수
  /// 일반 검색과 초성 검색을 모두 지원
  /// 예: search('김현수', 'ㄱㅎ') -> true (초성 검색)
  ///     search('김현수', '김현') -> true (일반 검색)
  ///     search('김현수', '현수') -> true (부분 검색)
  static bool search(String targetText, String query) {
    if (targetText.isEmpty || query.isEmpty) return false;

    final lowerTarget = targetText.toLowerCase();
    final lowerQuery = query.toLowerCase();

    // 1. 일반 부분 문자열 검색 (기본)
    if (lowerTarget.contains(lowerQuery)) {
      return true;
    }

    // 2. 초성 검색 (검색어에 초성이 포함된 경우)
    if (isChosungQuery(query)) {
      return matchChosung(targetText, query);
    }

    return false;
  }

  /// 여러 필드에서 검색
  /// 예: searchMultipleFields(['김현수', '010-1234-5678', '장로'], 'ㄱㅎ') -> true
  static bool searchMultipleFields(List<String> fields, String query) {
    if (query.isEmpty) return false;

    for (final field in fields) {
      if (search(field, query)) {
        return true;
      }
    }

    return false;
  }
}
