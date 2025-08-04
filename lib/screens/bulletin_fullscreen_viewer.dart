import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:pdfx/pdfx.dart'; // Android 호환성 문제로 비활성화
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';

import 'package:permission_handler/permission_handler.dart';
import '../models/bulletin.dart';
import '../models/file_type.dart';
import '../resource/color_style.dart';
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
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = true;
  bool hasError = false;
  String? _localPdfPath; // 로컬에 다운로드된 PDF 파일 경로
  // PdfController? pdfController; // pdfx 컨트롤러 (iOS용) - Android 호환성 문제로 비활성화

  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  @override
  void dispose() {
    // pdfController?.dispose(); // PDF 컨트롤러 비활성화
    super.dispose();
  }

  Future<void> _initializePdf() async {
    if (widget.fileType != FileType.pdf) {
      setState(() {
        isLoading = false;
        hasError = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      String? pdfPath;

      if (widget.localPath != null) {
        // 이미 로컬 파일이 있는 경우
        pdfPath = widget.localPath;
        _localPdfPath = pdfPath;
        print('📱 PDF: 로컬 파일 사용 - $pdfPath');
      } else if (widget.bulletin.fileUrl != null) {
        // 네트워크에서 다운로드 후 로컬에 저장
        final cleanedUrl = FileTypeHelper.cleanUrl(widget.bulletin.fileUrl!);
        print('📱 PDF: URL에서 다운로드 시작 - $cleanedUrl');
        
        // 임시 디렉토리 얻기
        final tempDir = await getTemporaryDirectory();
        final fileName = 'bulletin_${widget.bulletin.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final localFile = File('${tempDir.path}/$fileName');
        
        // PDF 파일 다운로드
        final bytes = await _downloadFile(cleanedUrl);
        await localFile.writeAsBytes(bytes);
        
        pdfPath = localFile.path;
        _localPdfPath = pdfPath;
        print('📱 PDF: 다운로드 완료 - $pdfPath');
      }

      if (pdfPath != null && File(pdfPath).existsSync()) {
        // PDF 컸트롤러 비활성화로 인한 수정
        setState(() {
          isLoading = false;
          hasError = false;
        });
        print('📱 PDF: 초기화 완료');
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        print('📱 PDF: 파일을 찾을 수 없음');
      }
    } catch (e) {
      print('📱 PDF: 초기화 오류 - $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<Uint8List> _downloadFile(String url) async {
    try {
      final response = await HttpClient().getUrl(Uri.parse(url));
      final request = await response.close();
      final bytes = await request
          .fold<List<int>>(<int>[], (prev, element) => prev..addAll(element));
      return Uint8List.fromList(bytes);
    } catch (e) {
      print('파일 다운로드 실패: $e');
      rethrow;
    }
  }

  // 파일 다운로드 및 갤러리 저장 기능
  Future<void> _downloadToGallery() async {
    try {
      // 권한 요청
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          _showErrorSnackBar('갤러리 접근 권한이 필요합니다');
          return;
        }
      }

      _showLoadingSnackBar('다운로드 중...');

      Uint8List? fileBytes;
      String fileName =
          '${widget.bulletin.title}_${DateTime.now().millisecondsSinceEpoch}';

      if (widget.localPath != null) {
        // 로컬 파일이 있는 경우
        final file = File(widget.localPath!);
        fileBytes = await file.readAsBytes();
      } else if (widget.bulletin.fileUrl != null) {
        // URL에서 다운로드
        final cleanedUrl = FileTypeHelper.cleanUrl(widget.bulletin.fileUrl!);
        print('다운로드 URL 정리: ${widget.bulletin.fileUrl} -> $cleanedUrl');
        fileBytes = await _downloadFile(cleanedUrl);
      } else {
        _showErrorSnackBar('다운로드할 파일을 찾을 수 없습니다');
        return;
      }

      // 파일 확장자 결정
      String extension = widget.fileType == FileType.pdf ? '.pdf' : '.jpg';
      fileName += extension;

      // 임시 파일 생성
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(fileBytes);

      // 갤러리에 저장
      final result = await SaverGallery.saveFile(
        filePath: tempFile.path,
        fileName: fileName,
        skipIfExists: false,
      );

      if (result.isSuccess) {
        _showSuccessSnackBar('갤러리에 저장되었습니다');
      } else {
        _showErrorSnackBar('저장 실패: ${result.errorMessage ?? "알 수 없는 오류"}');
      }
    } catch (e) {
      print('갤러리 저장 실패: $e');
      _showErrorSnackBar('저장 중 오류가 발생했습니다');
    }
  }

  // 파일 공유 기능
  Future<void> _shareFile() async {
    try {
      _showLoadingSnackBar('공유 준비 중...');

      if (widget.localPath != null) {
        // 로컬 파일 공유
        await Share.shareXFiles(
          [XFile(widget.localPath!)],
          text: '${widget.bulletin.title} 주보를 공유합니다',
        );
      } else if (widget.bulletin.fileUrl != null) {
        // URL 공유 또는 임시 파일 생성해서 공유
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
            '${tempDir.path}/${widget.bulletin.title}_${DateTime.now().millisecondsSinceEpoch}${widget.fileType == FileType.pdf ? '.pdf' : '.jpg'}');

        final cleanedUrl = FileTypeHelper.cleanUrl(widget.bulletin.fileUrl!);
        print('공유 URL 정리: ${widget.bulletin.fileUrl} -> $cleanedUrl');
        final fileBytes = await _downloadFile(cleanedUrl);
        await tempFile.writeAsBytes(fileBytes);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: '${widget.bulletin.title} 주보를 공유합니다',
        );
      } else {
        // URL만 공유
        await Share.share(
          '주보를 공유합니다: ${widget.bulletin.title} 주보: ${widget.bulletin.fileUrl ?? ""}',
        );
      }
    } catch (e) {
      print('파일 공유 실패: $e');
      _showErrorSnackBar('공유 중 오류가 발생했습니다');
    }
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

  Widget _buildPdfViewer() {
    // Android 호환성 문제로 인해 외부 PDF 뷰어로 열기
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  size: 64,
                  color: Colors.white70,
                ),
                const SizedBox(height: 16),
                const Text(
                  'PDF 문서',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '아래 버튼을 눌러 외부 앱에서 PDF를 열어보세요',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = widget.localPath ?? widget.bulletin.fileUrl!;
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('외부 앱에서 열기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
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

  Widget _buildImageViewer() {
    if (widget.localPath != null) {
      return PhotoView(
        imageProvider: FileImage(File(widget.localPath!)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3.0,
        initialScale: PhotoViewComputedScale.contained,
        heroAttributes: PhotoViewHeroAttributes(tag: widget.bulletin.id),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      );
    } else if (widget.bulletin.fileUrl != null) {
      final cleanedUrl = FileTypeHelper.cleanUrl(widget.bulletin.fileUrl!);
      print('이미지 URL 정리: ${widget.bulletin.fileUrl} -> $cleanedUrl');
      return PhotoView(
        imageProvider: CachedNetworkImageProvider(cleanedUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3.0,
        initialScale: PhotoViewComputedScale.contained,
        heroAttributes: PhotoViewHeroAttributes(tag: widget.bulletin.id),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Text(
            '이미지를 불러올 수 없습니다',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      return const Center(
        child: Text(
          '이미지를 불러올 수 없습니다',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.bulletin.title,
          style: AppTextStyle(color: AppColor.white).h2(),
        ),
        actions: [
          // 줌 리셋 버튼 (이미지인 경우)
          if (widget.fileType == FileType.image)
            IconButton(
              onPressed: () {
                // PhotoView는 자체적으로 줌 리셋 기능이 있음
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('더블 탭으로 줌을 조절할 수 있습니다'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.zoom_out_map),
            ),
          // // 다운로드 버튼
          // IconButton(
          //   onPressed: _downloadToGallery,
          //   icon: const Icon(Icons.download),
          // ),
          // 공유 버튼
          IconButton(
            onPressed: _shareFile,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SafeArea(
        child: widget.fileType == FileType.pdf
            ? _buildPdfViewer()
            : _buildImageViewer(),
      ),
    );
  }
}

// FileType enum은 bulletin_modal.dart에서 import하여 사용
