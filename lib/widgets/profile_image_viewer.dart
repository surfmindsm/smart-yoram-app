import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// 프로필 이미지를 전체 화면으로 보여주는 뷰어
class ProfileImageViewer extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackName;

  const ProfileImageViewer({
    super.key,
    this.imageUrl,
    this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? PhotoView(
                imageProvider: NetworkImage(imageUrl!),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black,
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackImage();
                },
              )
            : _buildFallbackImage(),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Center(
        child: Text(
          fallbackName != null && fallbackName!.isNotEmpty
              ? fallbackName![0]
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 80,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 프로필 이미지를 클릭 가능하게 만드는 헬퍼 함수
  static void show(
    BuildContext context, {
    String? imageUrl,
    String? fallbackName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileImageViewer(
          imageUrl: imageUrl,
          fallbackName: fallbackName,
        ),
      ),
    );
  }
}
