import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_yoram_app/resource/color_style.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/bulletin.dart';
import '../models/file_type.dart';

import '../resource/text_style.dart';

class BulletinFullscreenViewer extends StatefulWidget {
  final Bulletin bulletin;
  final String? localPath;
  final FileType fileType;

  const BulletinFullscreenViewer({
    super.key,
    required this.bulletin,
    required this.localPath,
    required this.fileType,
  });

  @override
  State<BulletinFullscreenViewer> createState() =>
      _BulletinFullscreenViewerState();
}

class _BulletinFullscreenViewerState extends State<BulletinFullscreenViewer> {
  bool isLoading = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    // PDF는 외부 앱에서 열기만 하므로 초기화 불필요
  }

  // HTTP 클라이언트를 사용하여 파일 다운로드
  Future<Uint8List> _downloadFile(String url) async {
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    final bytes = await response
        .fold<List<int>>(<int>[], (previous, chunk) => previous..addAll(chunk));
    return Uint8List.fromList(bytes);
  }

  Future<void> _saveToGallery() async {
    if (widget.fileType == FileType.pdf) {
      _showErrorSnackBar('PDF 파일은 갤러리에 저장할 수 없습니다');
      return;
    }

    try {
      // 권한 요청
      final permission = await Permission.photos.request();
      if (!permission.isGranted) {
        _showErrorSnackBar('갤러리 접근 권한이 필요합니다');
        return;
      }

      _showLoadingSnackBar('갤러리에 저장 중...');

      if (widget.bulletin.fileUrl != null) {
        final cleanedUrl = FileTypeHelper.cleanUrl(widget.bulletin.fileUrl!);
        final fileBytes = await _downloadFile(cleanedUrl);

        final result = await SaverGallery.saveImage(
          fileBytes,
          quality: 100,
          fileName:
              '주보_${widget.bulletin.title}_${DateTime.now().millisecondsSinceEpoch}',
          skipIfExists: false,
        );

        if (result.isSuccess) {
          _showSuccessSnackBar('갤러리에 저장되었습니다');
        } else {
          _showErrorSnackBar('갤러리 저장 실패: ${result.errorMessage}');
        }
      }
    } catch (e) {
      print('갤러리 저장 실패: $e');
      _showErrorSnackBar('갤러리 저장 중 오류가 발생했습니다');
    }
  }

  Future<void> _shareFile() async {
    try {
      if (widget.bulletin.fileUrl != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
            '${tempDir.path}/${widget.bulletin.title}_${DateTime.now().millisecondsSinceEpoch}${widget.fileType == FileType.pdf ? '.pdf' : '.jpg'}');

        final cleanedUrl = FileTypeHelper.cleanUrl(widget.bulletin.fileUrl!);
        final fileBytes = await _downloadFile(cleanedUrl);
        await tempFile.writeAsBytes(fileBytes);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: '${widget.bulletin.title} 주보를 공유합니다',
        );
      } else {
        await Share.share(
          '주보를 공유합니다: ${widget.bulletin.title}',
        );
      }
    } catch (e) {
      print('파일 공유 실패: $e');
      _showErrorSnackBar('공유 중 오류가 발생했습니다');
    }
  }

  Widget _buildPdfViewer() {
    if (widget.bulletin.fileUrl == null) {
      return Center(
        child: Text(
          'PDF 파일을 불러올 수 없습니다',
          style: AppTextStyle(color: AppColor.white).b2(),
        ),
      );
    }

    final cleanedUrl = FileTypeHelper.cleanUrl(widget.bulletin.fileUrl!);

    return Container(
      color: AppColor.background,
      child: SfPdfViewer.network(
        cleanedUrl,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          print('PDF 로드 실패: ${details.error}');
        },
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          print('PDF 로드 성공: ${details.document.pages.count} 페이지');
        },
      ),
    );
  }

  Widget _buildImageViewer() {
    if (widget.bulletin.fileUrl == null) {
      return const Center(
        child: Text('이미지를 불러올 수 없습니다'),
      );
    }

    final cleanedUrl = FileTypeHelper.cleanUrl(widget.bulletin.fileUrl!);

    return PhotoView(
      imageProvider: CachedNetworkImageProvider(cleanedUrl),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3.0,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('이미지를 불러올 수 없습니다'),
            const SizedBox(height: 8),
            Text('$error'),
          ],
        ),
      ),
    );
  }

  // 스낵바 헬퍼 메서드들
  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.secondary07,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.bulletin.title,
          style: AppTextStyle(color: AppColor.white).b2(),
        ),
        actions: [
          if (widget.fileType == FileType.image)
            IconButton(
              onPressed: _saveToGallery,
              icon: const Icon(Icons.download),
              tooltip: '갤러리에 저장',
            ),
          IconButton(
            onPressed: _shareFile,
            icon: const Icon(Icons.share),
            tooltip: '공유',
          ),
        ],
      ),
      body: widget.fileType == FileType.pdf
          ? _buildPdfViewer()
          : _buildImageViewer(),
    );
  }
}
