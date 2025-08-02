import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/bulletin.dart';
import '../services/bulletin_service.dart';
import '../widget/widgets.dart';

class BulletinModal extends StatefulWidget {
  final Bulletin bulletin;

  const BulletinModal({
    super.key,
    required this.bulletin,
  });

  @override
  State<BulletinModal> createState() => _BulletinModalState();
}

class _BulletinModalState extends State<BulletinModal> {
  final BulletinService _bulletinService = BulletinService();
  String? localPath;
  bool isLoading = false;
  String? errorMessage;
  FileType fileType = FileType.unknown;
  PdfController? pdfController;

  @override
  void initState() {
    super.initState();
    _initializeFile();
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  Future<void> _initializeFile() async {
    if (widget.bulletin.fileUrl == null) {
      setState(() {
        errorMessage = '주보 파일이 없습니다.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 파일 타입 확인
      String url = widget.bulletin.fileUrl!;
      if (url.toLowerCase().contains('.pdf')) {
        fileType = FileType.pdf;
      } else if (url.toLowerCase().contains('.jpg') || 
                 url.toLowerCase().contains('.jpeg') || 
                 url.toLowerCase().contains('.png')) {
        fileType = FileType.image;
      }

      // PDF의 경우 PdfController 초기화
      if (fileType == FileType.pdf) {
        await _initializePdfController();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = '파일을 불러오는데 실패했습니다: $e';
      });
    }
  }

  Future<void> _initializePdfController() async {
    try {
      await _downloadPdfFile();
      if (localPath != null) {
        pdfController = PdfController(
          document: PdfDocument.openFile(localPath!),
        );
      }
    } catch (e) {
      throw Exception('PDF Controller 초기화 실패: $e');
    }
  }

  Future<void> _downloadPdfFile() async {
    try {
      final response = await http.get(Uri.parse(widget.bulletin.fileUrl!));
      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/bulletin_${widget.bulletin.id}.pdf');
      
      await file.writeAsBytes(bytes, flush: true);
      localPath = file.path;
    } catch (e) {
      throw Exception('PDF 다운로드 실패: $e');
    }
  }

  Future<void> _downloadFile() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await _bulletinService.downloadBulletin(widget.bulletin.id.toString());
      
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('다운로드가 완료되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: ${response.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드 실패: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildFilePreview() {
    if (isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('주보를 불러오는 중...'),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeFile,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    switch (fileType) {
      case FileType.pdf:
        return _buildPdfPreview();
      case FileType.image:
        return _buildImagePreview();
      default:
        return _buildDefaultPreview();
    }
  }

  Widget _buildPdfPreview() {
    if (pdfController == null) {
      return const SizedBox(
        height: 400,
        child: Center(child: Text('PDF 파일을 준비 중입니다.')),
      );
    }

    return Container(
      height: 500,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: PdfView(
          controller: pdfController!,
          onDocumentError: (error) {
            setState(() {
              errorMessage = 'PDF 로딩 오류: $error';
            });
          },
          onPageChanged: (page) {
            // 페이지 변경 시 처리
          },
          backgroundDecoration: BoxDecoration(
            color: Colors.grey[100],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(widget.bulletin.fileUrl!),
          backgroundDecoration: BoxDecoration(
            color: Colors.grey[100],
          ),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2.0,
          loadingBuilder: (context, event) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    '이미지를 불러올 수 없습니다.',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultPreview() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              '미리보기를 지원하지 않는 파일 형식입니다.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '다운로드하여 확인해주세요.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bulletin.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(widget.bulletin.date),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            
            // 내용
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildFilePreview(),
              ),
            ),
            
            // 버튼들
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _downloadFile,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(isLoading ? '다운로드 중...' : '다운로드'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // 공유 기능 구현
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('주보가 공유되었습니다')),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('공유'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum FileType {
  pdf,
  image,
  unknown,
}
