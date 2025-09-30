import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../components/index.dart';

/// 관리자 권한 관련 유틸리티
class AdminPermissionUtils {
  static final AuthService _authService = AuthService();

  /// 현재 사용자가 관리자 권한을 가지고 있는지 확인
  static Future<bool> hasAdminAccess() async {
    final userResponse = await _authService.getCurrentUser();
    if (!userResponse.success || userResponse.data == null) {
      return false;
    }

    final user = userResponse.data!;
    return _isAdminRole(user.role);
  }

  /// 동기적으로 현재 사용자 권한 확인 (AuthService의 캐시된 사용자 사용)
  static bool hasAdminAccessSync() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return false;
    }
    return _isAdminRole(currentUser.role);
  }

  /// 관리자 역할 체크 헬퍼
  static bool _isAdminRole(String role) {
    return role == 'admin' ||
           role == 'church_admin' ||
           role == 'church_super_admin' ||
           role == 'community_admin' ||
           role == 'system_admin' ||
           role == 'super_admin';
  }

  /// 관리자 전용 화면 접근 시 권한 체크
  static Future<bool> checkAdminAccessWithDialog(BuildContext context) async {
    final hasAccess = await hasAdminAccess();

    if (!hasAccess && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AppDialog(
          title: '접근 권한 없음',
          content: const Text('관리자만 접근 가능한 기능입니다.'),
          actions: [
            AppButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }

    return hasAccess;
  }

  /// 현재 사용자의 role 반환
  static String? getCurrentUserRole() {
    final currentUser = _authService.currentUser;
    return currentUser?.role;
  }

  /// 현재 사용자 객체 반환
  static User? getCurrentUser() {
    return _authService.currentUser;
  }
}