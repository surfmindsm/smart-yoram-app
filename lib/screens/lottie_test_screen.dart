import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Lottie 애니메이션 미리보기 테스트 화면
class LottieTestScreen extends StatefulWidget {
  const LottieTestScreen({super.key});

  @override
  State<LottieTestScreen> createState() => _LottieTestScreenState();
}

class _LottieTestScreenState extends State<LottieTestScreen> {
  // 모든 Lottie 파일 목록
  final List<String> lottieFiles = [
    'assets/lottie/Spinner01.json',
    'assets/lottie/Spinner02.json',
    'assets/lottie/Spinner03.json',
    'assets/lottie/Spinner04.json',
    'assets/lottie/loading.json',
    'assets/lottie/loading_0.json',
    'assets/lottie/loading_1.json',
    'assets/lottie/loading_2.json',
    'assets/lottie/loading_4.json',
    'assets/lottie/loading_5.json',
    'assets/lottie/loading_white.json',
    'assets/lottie/splash.json',
    'assets/lottie/free_talk.json',
    'assets/lottie/loading_6.json',
    'assets/lottie/spinner05.json',
    'assets/lottie/spinner06.json',
    'assets/lottie/star.json',
    'assets/lottie/star2.json',
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Lottie 애니메이션 테스트 (${_currentIndex + 1}/${lottieFiles.length})',
          style: TextStyle(fontSize: 16.sp),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 현재 파일 이름 표시
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            color: Colors.grey[100],
            child: Column(
              children: [
                Text(
                  lottieFiles[_currentIndex].split('/').last,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  lottieFiles[_currentIndex],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Lottie 애니메이션 표시 영역
          Expanded(
            child: Center(
              child: Lottie.asset(
                lottieFiles[_currentIndex],
                width: 200.w,
                height: 200.h,
                fit: BoxFit.contain,
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200.w,
                    height: 200.h,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.circleAlert,
                          size: 48.sp,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            '이 Lottie 파일을 로드할 수 없습니다',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.red[900],
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            error.toString(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.red[700],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 크기 조절 버전들
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '다양한 크기로 미리보기:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSizePreview('작음', 50.w),
                    _buildSizePreview('중간', 80.w),
                    _buildSizePreview('큰', 120.w),
                  ],
                ),
              ],
            ),
          ),

          // 네비게이션 버튼
          Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentIndex > 0
                        ? () {
                            setState(() {
                              _currentIndex--;
                            });
                          }
                        : null,
                    icon: const Icon(LucideIcons.arrowLeft),
                    label: const Text('이전'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentIndex < lottieFiles.length - 1
                        ? () {
                            setState(() {
                              _currentIndex++;
                            });
                          }
                        : null,
                    icon: const Icon(LucideIcons.arrowRight),
                    label: const Text('다음'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizePreview(String label, double size) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Lottie.asset(
            lottieFiles[_currentIndex],
            fit: BoxFit.contain,
            repeat: true,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                LucideIcons.circleAlert,
                size: size * 0.4,
                color: Colors.red,
              );
            },
          ),
        ),
      ],
    );
  }
}
