import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/index.dart';
import '../models/models.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';

class UpdateDialog extends StatelessWidget {
  final VersionCheckResult versionCheckResult;

  const UpdateDialog({
    super.key,
    required this.versionCheckResult,
  });

  Future<void> _openStore(BuildContext context) async {
    final storeUrl = versionCheckResult.versionInfo?.storeUrl;
    if (storeUrl == null || storeUrl.isEmpty) {
      if (context.mounted) {
        AppToast.show(
          context,
          '스토어 URL을 찾을 수 없습니다.',
          type: ToastType.error,
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(storeUrl);
      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          AppToast.show(
            context,
            '스토어를 열 수 없습니다.',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      print('❌ UPDATE_DIALOG: Failed to open store: $e');
      if (context.mounted) {
        AppToast.show(
          context,
          '스토어를 열 수 없습니다: $e',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForceUpdate = versionCheckResult.isForceUpdate;

    return WillPopScope(
      // 강제 업데이트일 경우 뒤로가기 막기
      onWillPop: () async => !isForceUpdate,
      child: AppDialog(
        title: isForceUpdate ? '업데이트 필요' : '새 버전 출시',
        dismissible: !isForceUpdate, // 강제 업데이트일 경우 X 버튼 숨김
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 업데이트 메시지
            Text(
              versionCheckResult.updateMessage,
              style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral800,
                  ),
            ),
            SizedBox(height: 16.h),

            // 버전 정보
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: NewAppColor.neutral100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '현재 버전',
                        style: FigmaTextStyles().caption1.copyWith(
                              color: NewAppColor.neutral600,
                            ),
                      ),
                      Text(
                        versionCheckResult.currentVersion,
                        style: FigmaTextStyles().caption1.copyWith(
                              color: NewAppColor.neutral900,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '최신 버전',
                        style: FigmaTextStyles().caption1.copyWith(
                              color: NewAppColor.neutral600,
                            ),
                      ),
                      Text(
                        versionCheckResult.versionInfo?.latestVersion ?? '-',
                        style: FigmaTextStyles().caption1.copyWith(
                              color: NewAppColor.primary600,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 강제 업데이트 경고
            if (isForceUpdate) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: NewAppColor.danger100,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: NewAppColor.danger300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: NewAppColor.danger600,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '필수 업데이트입니다',
                        style: FigmaTextStyles().caption1.copyWith(
                              color: NewAppColor.danger700,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // 선택적 업데이트는 나중에 하기 버튼 제공
          if (!isForceUpdate)
            AppButton(
              onPressed: () => Navigator.pop(context),
              variant: ButtonVariant.ghost,
              child: const Text('나중에'),
            ),

          // 업데이트 버튼
          AppButton(
            onPressed: () => _openStore(context),
            variant: isForceUpdate ? ButtonVariant.primary : ButtonVariant.primary,
            child: const Text('업데이트'),
          ),
        ],
      ),
    );
  }
}

/// 버전 체크 결과를 보여주는 헬퍼 함수
Future<void> showUpdateDialogIfNeeded(
  BuildContext context,
  VersionCheckResult result,
) async {
  if (!result.needsUpdate) {
    print('✅ UPDATE_DIALOG: No update needed');
    return;
  }

  if (!context.mounted) return;

  print('ℹ️ UPDATE_DIALOG: Showing update dialog');
  print('   Update type: ${result.updateType}');
  print('   Current version: ${result.currentVersion}');
  print('   Latest version: ${result.versionInfo?.latestVersion}');

  await showDialog(
    context: context,
    // 강제 업데이트일 경우 바깥 영역 터치 막기
    barrierDismissible: !result.isForceUpdate,
    builder: (context) => UpdateDialog(
      versionCheckResult: result,
    ),
  );
}
