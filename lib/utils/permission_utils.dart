import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  /// 카메라 권한을 요청하고 개인정보처리방침 안내를 표시합니다.
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    // 처음 요청하는 경우 개인정보처리방침 안내
    if (status.isDenied) {
      final shouldRequest = await _showPrivacyPolicyDialog(context);
      if (!shouldRequest) {
        return false;
      }
    }
    
    // 권한 요청
    final result = await Permission.camera.request();
    
    if (result.isGranted) {
      return true;
    } else if (result.isPermanentlyDenied) {
      // 영구적으로 거부된 경우 설정으로 이동 안내
      await _showSettingsDialog(context);
      return false;
    }
    
    return false;
  }
  
  /// 개인정보처리방침과 권한 사용 목적을 안내하는 다이얼로그
  static Future<bool> _showPrivacyPolicyDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.camera, color: Colors.blue),
            SizedBox(width: 8),
            Text('카메라 권한 요청'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '개인정보처리방침',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Smart Yoram 앱에서 카메라 권한이 필요한 이유:',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• QR 코드 스캔: 교회 출석 체크를 위해 QR 코드를 스캔합니다'),
                    Text('• 행사 사진: 교회 행사 및 활동 기록을 위해 사진을 촬영합니다'),
                    Text('• 프로필 사진: 개인 프로필 등록을 위해 사진을 촬영합니다'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                '개인정보 보호 정책:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text('• 촬영된 사진은 사용자 동의 하에만 저장됩니다'),
              Text('• 수집된 정보는 교회 관리 목적으로만 사용됩니다'),
              Text('• 개인정보는 안전하게 암호화되어 저장됩니다'),
              Text('• 사용자는 언제든지 개인정보 삭제를 요청할 수 있습니다'),
              SizedBox(height: 12),
              Text(
                '위 내용에 동의하시면 \'허용\'을 선택해주세요.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('거부'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('허용'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// 설정으로 이동을 안내하는 다이얼로그
  static Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.settings, color: Colors.orange),
            SizedBox(width: 8),
            Text('권한 설정 필요'),
          ],
        ),
        content: const Text(
          '카메라 권한이 필요합니다.\n\n'
          '설정 > 앱 권한 > 카메라에서 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }
  
  /// 권한 상태를 확인합니다.
  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }
  
  /// 권한 상태 설명을 반환합니다.
  static String getPermissionStatusDescription(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '권한이 허용되었습니다';
      case PermissionStatus.denied:
        return '권한이 거부되었습니다';
      case PermissionStatus.restricted:
        return '권한이 제한되었습니다';
      case PermissionStatus.limited:
        return '권한이 제한적으로 허용되었습니다';
      case PermissionStatus.permanentlyDenied:
        return '권한이 영구적으로 거부되었습니다. 설정에서 변경해주세요';
      default:
        return '권한 상태를 확인할 수 없습니다';
    }
  }
}
