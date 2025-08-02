import 'dart:io';
import 'package:flutter/material.dart';

// 플랫폼별 조건부 import
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:flutter_pdfview/flutter_pdfview.dart' as pdfview;

/// 플랫폼별 PDF 뷰어 위젯을 제공하는 유틸리티 클래스
class PdfPlatformUtil {
  /// 현재 플랫폼에 맞는 PDF 뷰어 위젯을 반환합니다.
  static Widget buildPdfViewer({
    required String? localPath,
    Function(int page, int total)? onPageChanged,
    Function(int total)? onDocumentLoaded,
  }) {
    if (Platform.isIOS) {
      return IosPdfViewer(
        localPath: localPath,
        onPageChanged: onPageChanged,
        onDocumentLoaded: onDocumentLoaded,
      );
    } else if (Platform.isAndroid) {
      return AndroidPdfViewer(
        localPath: localPath,
        onPageChanged: onPageChanged,
        onDocumentLoaded: onDocumentLoaded,
      );
    } else {
      return const Center(
        child: Text('지원하지 않는 플랫폼입니다.'),
      );
    }
  }
}

/// iOS용 PDF 뷰어 (pdfx 사용)
class IosPdfViewer extends StatefulWidget {
  final String? localPath;
  final Function(int page, int total)? onPageChanged;
  final Function(int total)? onDocumentLoaded;

  const IosPdfViewer({
    super.key,
    required this.localPath,
    this.onPageChanged,
    this.onDocumentLoaded,
  });

  @override
  State<IosPdfViewer> createState() => _IosPdfViewerState();
}

class _IosPdfViewerState extends State<IosPdfViewer> {
  pdfx.PdfController? pdfController;
  int currentPage = 1;
  int totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  void _initializePdf() async {
    if (widget.localPath != null) {
      try {
        final documentFuture = pdfx.PdfDocument.openFile(widget.localPath!);
        pdfController = pdfx.PdfController(document: documentFuture);
        
        // 문서가 로드된 후 페이지 수 가져오기
        final document = await documentFuture;
        totalPages = document.pagesCount;
        
        // 문서 로드 완료 콜백
        if (widget.onDocumentLoaded != null) {
          widget.onDocumentLoaded!(totalPages);
        }
        
        setState(() {});
      } catch (e) {
        print('PDF 로드 실패: $e');
      }
    }
  }

  void _onPageChanged(int page) {
    currentPage = page;
    if (widget.onPageChanged != null) {
      widget.onPageChanged!(page, totalPages);
    }
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (pdfController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return pdfx.PdfView(
      controller: pdfController!,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
    );
  }
}

/// Android용 PDF 뷰어 (flutter_pdfview 사용)
class AndroidPdfViewer extends StatefulWidget {
  final String? localPath;
  final Function(int page, int total)? onPageChanged;
  final Function(int total)? onDocumentLoaded;

  const AndroidPdfViewer({
    super.key,
    required this.localPath,
    this.onPageChanged,
    this.onDocumentLoaded,
  });

  @override
  State<AndroidPdfViewer> createState() => _AndroidPdfViewerState();
}

class _AndroidPdfViewerState extends State<AndroidPdfViewer> {
  late pdfview.PDFViewController pdfViewController;
  int currentPage = 0;
  int totalPages = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.localPath == null) {
      return const Center(child: Text('PDF 파일을 찾을 수 없습니다.'));
    }

    return pdfview.PDFView(
      filePath: widget.localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageSnap: true,
      onRender: (pages) {
        totalPages = pages ?? 0;
        if (widget.onDocumentLoaded != null) {
          widget.onDocumentLoaded!(totalPages);
        }
      },
      onViewCreated: (pdfview.PDFViewController controller) {
        pdfViewController = controller;
      },
      onPageChanged: (page, total) {
        currentPage = page ?? 0;
        totalPages = total ?? 0;
        if (widget.onPageChanged != null) {
          widget.onPageChanged!(currentPage + 1, totalPages);
        }
      },
      onError: (error) {
        print('PDF 뷰어 오류: $error');
      },
    );
  }
}
