import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
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
  PdfController? pdfController;

  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  Future<void> _initializePdf() async {
    if (widget.fileType == FileType.pdf) {
      try {
        // 로컬 파일이 있으면 로컬 파일을 사용, 없으면 URL에서 로드
        if (widget.localPath != null) {
          pdfController = PdfController(
            document: PdfDocument.openFile(widget.localPath!),
          );

          final document = await PdfDocument.openFile(widget.localPath!);
          final pageCount = document.pagesCount;
          setState(() {
            totalPages = pageCount;
          });
        } else if (widget.bulletin.fileUrl != null) {
          // URL에서 PDF 로드
          final cleanedUrl = FileTypeHelper.cleanUrl(widget.bulletin.fileUrl!);
          print('PDF URL 정리: ${widget.bulletin.fileUrl} -> $cleanedUrl');
          final data = await _downloadFile(cleanedUrl);
          pdfController = PdfController(
            document: PdfDocument.openData(data),
          );

          final document = await PdfDocument.openData(data);
          final pageCount = document.pagesCount;
          setState(() {
            totalPages = pageCount;
          });
        }
      } catch (e) {
        print('PDF 컸트롤러 초기화 실패: $e');
        // PDF 로드 실패 시 에러 상태로 설정
        setState(() {
          totalPages = 0;
        });
      }
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
    if (pdfController == null) {
      // totalPages가 0이면 에러 상태, 아니면 로딩 중
      if (totalPages == 0) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white54,
              ),
              SizedBox(height: 16),
              Text(
                'PDF를 불러올 수 없습니다',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'PDF를 불러오는 중...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PdfView(
          controller: pdfController!,
          onPageChanged: (page) {
            setState(() {
              currentPage = page;
            });
          },
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
        ),
        // 페이지 정보 표시
        Positioned(
          bottom: 100,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
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
