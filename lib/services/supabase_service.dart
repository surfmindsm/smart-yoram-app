import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member.dart';
import '../models/user.dart' as app_user;

/// Supabase를 직접 사용하여 데이터를 조회하는 서비스
/// users 테이블과 members 테이블에서 실제 데이터를 가져옵니다.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// 모든 사용자 조회
  Future<List<app_user.User>> getUsers({
    int? limit,
    int? offset,
  }) async {
    try {
      final query = client.from('users').select('*');
      
      final response = await query;
      
      return (response as List)
          .map((userJson) => app_user.User.fromJson(userJson))
          .toList();
    } catch (e) {
      print('사용자 조회 오류: $e');
      return [];
    }
  }

  /// 특정 사용자 조회
  Future<app_user.User?> getUser(int userId) async {
    try {
      final response = await client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      return app_user.User.fromJson(response);
    } catch (e) {
      print('사용자 조회 오류: $e');
      return null;
    }
  }

  /// 현재 로그인한 사용자 조회
  Future<app_user.User?> getCurrentUser() async {
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return null;

      final response = await client
          .from('users')
          .select('*')
          .eq('email', currentUser.email!)
          .single();

      return app_user.User.fromJson(response);
    } catch (e) {
      print('현재 사용자 조회 오류: $e');
      return null;
    }
  }

  /// 모든 교인 조회
  Future<List<Member>> getMembers({
    int? limit,
    int? offset,
    String? search,
    String? memberStatus,
  }) async {
    try {
      final query = client.from('members').select('*');
      
      final response = await query;
      
      return (response as List)
          .map((memberJson) => Member.fromJson(memberJson))
          .toList();
    } catch (e) {
      print('교인 조회 오류: $e');
      return [];
    }
  }

  /// 특정 교인 조회
  Future<Member?> getMember(int memberId) async {
    try {
      final response = await client
          .from('members')
          .select('*')
          .eq('id', memberId)
          .single();

      return Member.fromJson(response);
    } catch (e) {
      print('교인 조회 오류: $e');
      return null;
    }
  }

  /// 활성 교인만 조회
  Future<List<Member>> getActiveMembers({int? limit}) async {
    return getMembers(
      memberStatus: 'active',
      limit: limit,
    );
  }

  /// 비활성 교인 조회
  Future<List<Member>> getInactiveMembers({int? limit}) async {
    return getMembers(
      memberStatus: 'inactive',
      limit: limit,
    );
  }

  /// 새 교인 등록
  Future<Member?> createMember(Map<String, dynamic> memberData) async {
    try {
      final response = await client
          .from('members')
          .insert(memberData)
          .select()
          .single();

      return Member.fromJson(response);
    } catch (e) {
      print('교인 등록 오류: $e');
      return null;
    }
  }

  /// 교인 정보 수정
  Future<Member?> updateMember(int memberId, Map<String, dynamic> memberData) async {
    try {
      final response = await client
          .from('members')
          .update(memberData)
          .eq('id', memberId)
          .select()
          .single();

      return Member.fromJson(response);
    } catch (e) {
      print('교인 정보 수정 오류: $e');
      return null;
    }
  }

  /// 교인 삭제
  Future<bool> deleteMember(int memberId) async {
    try {
      await client
          .from('members')
          .delete()
          .eq('id', memberId);
      
      return true;
    } catch (e) {
      print('교인 삭제 오류: $e');
      return false;
    }
  }

  /// 교인 통계 조회 (간단한 버전)
  Future<Map<String, int>> getMemberStatistics() async {
    try {
      final members = await getMembers();
      final activeMembers = members.where((m) => m.memberStatus == 'active').length;
      final inactiveMembers = members.where((m) => m.memberStatus == 'inactive').length;
      
      return {
        'total': members.length,
        'active': activeMembers,
        'inactive': inactiveMembers,
      };
    } catch (e) {
      print('교인 통계 조회 오류: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
      };
    }
  }

  /// 사용자별 권한 확인
  Future<String?> getUserRole(String? email) async {
    if (email == null) return null;
    
    try {
      final response = await client
          .from('users')
          .select('role')
          .eq('email', email)
          .single();

      return response['role'] as String?;
    } catch (e) {
      print('사용자 권한 조회 오류: $e');
      return null;
    }
  }
}
