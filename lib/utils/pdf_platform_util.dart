import 'dart:io';
import 'package:flutter/material.dart';

// 플랫폼별 PDF 뷰어 import
import 'pdf_ios_viewer.dart';
import 'pdf_android_viewer.dart';

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
