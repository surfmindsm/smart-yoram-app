import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// import 'package:pdfx/pdfx.dart' as pdfx; // 안드로이드 빌드 오류로 인해 주석처리

/// iOS용 PDF 뷰어 (WebView fallback 사용)
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
  late WebViewController webViewController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            // 문서 로드 완료 콜백 (임시로 1페이지로 설정)
            if (widget.onDocumentLoaded != null) {
              widget.onDocumentLoaded!(1);
            }
          },
        ),
      );
    
    if (widget.localPath != null) {
      // PDF 파일을 WebView로 로드
      webViewController.loadFile(widget.localPath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.localPath == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('로드할 PDF 파일이 없습니다.'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: webViewController),
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
