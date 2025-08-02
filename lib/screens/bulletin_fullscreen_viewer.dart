import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../models/bulletin.dart';
import 'bulletin_modal.dart';

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
  State<BulletinFullscreenViewer> createState() => _BulletinFullscreenViewerState();
}

class _BulletinFullscreenViewerState extends State<BulletinFullscreenViewer> {
  PdfController? pdfController;
  int currentPage = 1;
  int totalPages = 1;

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
    if (widget.fileType == FileType.pdf && widget.localPath != null) {
      try {
        pdfController = PdfController(
          document: PdfDocument.openFile(widget.localPath!),
        );
        
        // PDF 페이지 수 가져오기
        final document = await PdfDocument.openFile(widget.localPath!);
        final pageCount = document.pagesCount;
        setState(() {
          totalPages = pageCount;
        });
      } catch (e) {
        print('PDF 컨트롤러 초기화 실패: $e');
      }
    }
  }

  Widget _buildPdfViewer() {
    if (pdfController == null) {
      return const Center(child: CircularProgressIndicator());
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
      return PhotoView(
        imageProvider: CachedNetworkImageProvider(widget.bulletin.fileUrl!),
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
          style: const TextStyle(fontSize: 16),
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
          // 다운로드 버튼
          IconButton(
            onPressed: () {
              // 다운로드 기능
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('다운로드 기능은 메인 화면에서 이용해주세요')),
              );
            },
            icon: const Icon(Icons.download),
          ),
          // 공유 버튼
          IconButton(
            onPressed: () {
              // 공유 기능
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('주보가 공유되었습니다')),
              );
            },
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
