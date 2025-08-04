import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart' as pdfview;

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
