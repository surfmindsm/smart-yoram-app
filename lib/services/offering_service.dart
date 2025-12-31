import 'dart:developer';
import '../models/offering.dart';
import 'supabase_service.dart';

class OfferingService {
  final SupabaseService _supabaseService = SupabaseService();

  // 헌금 내역 조회
  Future<List<Offering>> getOfferings({
    required int memberId,
    int? year,
    int? month,
    String sortOrder = 'desc',
  }) async {
    try {
      log('💰 헌금 내역 조회 시작 (Supabase)');
      log('💰 memberId: $memberId, year: $year, month: $month');

      dynamic query = _supabaseService.client
          .from('offerings')
          .select('*')
          .eq('member_id', memberId);

      // 연도 필터
      if (year != null) {
        final startDate = DateTime(year, 1, 1);
        final endDate = DateTime(year, 12, 31, 23, 59, 59);
        query = query
            .gte('offered_on', startDate.toIso8601String())
            .lte('offered_on', endDate.toIso8601String());
      }

      // 월 필터 (연도가 지정된 경우에만)
      if (year != null && month != null) {
        final startDate = DateTime(year, month, 1);
        final endDate = DateTime(
          year,
          month + 1,
          0,
          23,
          59,
          59,
        ); // 해당 월의 마지막 날
        query = query
            .gte('offered_on', startDate.toIso8601String())
            .lte('offered_on', endDate.toIso8601String());
      }

      // 정렬 (날짜 기준)
      query = query.order('offered_on', ascending: sortOrder == 'asc');

      final response = await query;

      log('💰 Supabase 응답: ${response.length}개 헌금 내역');

      final offerings = (response as List)
          .map((item) => Offering.fromJson(item as Map<String, dynamic>))
          .toList();

      log('💰 헌금 내역 ${offerings.length}개 조회 완료');
      return offerings;
    } catch (e) {
      log('❌ 헌금 내역 조회 오류: $e');
      throw Exception('헌금 내역을 불러올 수 없습니다: $e');
    }
  }

  // 헌금 총액 계산
  Future<double> getTotalAmount({
    required int memberId,
    int? year,
    int? month,
  }) async {
    try {
      final offerings = await getOfferings(
        memberId: memberId,
        year: year,
        month: month,
      );

      double total = offerings.fold(0.0, (sum, offering) => sum + offering.amount);
      log('💰 헌금 총액: $total원');
      return total;
    } catch (e) {
      log('❌ 헌금 총액 계산 오류: $e');
      throw Exception('헌금 총액을 계산할 수 없습니다: $e');
    }
  }

  // 특정 헌금 내역 조회
  Future<Offering> getOffering(int id) async {
    try {
      log('💰 헌금 내역 상세 조회 시작: ID $id');

      final response = await _supabaseService.client
          .from('offerings')
          .select('*')
          .eq('id', id)
          .single();

      final offering = Offering.fromJson(response);
      log('💰 헌금 내역 상세 조회 완료');
      return offering;
    } catch (e) {
      log('❌ 헌금 내역 조회 오류: $e');
      throw Exception('헌금 내역을 불러올 수 없습니다: $e');
    }
  }

  // 연도별 헌금 목록 조회 (그룹화)
  Future<Map<int, List<Offering>>> getOfferingsByYear(int memberId) async {
    try {
      final offerings = await getOfferings(memberId: memberId);

      // 연도별로 그룹화
      final Map<int, List<Offering>> groupedByYear = {};
      for (var offering in offerings) {
        final year = offering.year;
        if (!groupedByYear.containsKey(year)) {
          groupedByYear[year] = [];
        }
        groupedByYear[year]!.add(offering);
      }

      log('💰 연도별 헌금 그룹화 완료: ${groupedByYear.keys.length}개 연도');
      return groupedByYear;
    } catch (e) {
      log('❌ 연도별 헌금 그룹화 오류: $e');
      throw Exception('헌금 내역을 그룹화할 수 없습니다: $e');
    }
  }

  // 가용 연도 목록 조회
  Future<List<int>> getAvailableYears(int memberId) async {
    try {
      final offerings = await getOfferings(memberId: memberId);

      // 중복 제거 및 정렬
      final years = offerings.map((o) => o.year).toSet().toList()..sort((a, b) => b.compareTo(a));

      log('💰 가용 연도 목록: $years');
      return years;
    } catch (e) {
      log('❌ 가용 연도 목록 조회 오류: $e');
      throw Exception('연도 목록을 불러올 수 없습니다: $e');
    }
  }
}
