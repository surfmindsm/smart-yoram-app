/// 파일 타입을 정의하는 enum
enum FileType {
  pdf,    // PDF 파일
  image,  // 이미지 파일 (JPG, PNG 등)
  unknown // 알 수 없는 파일 타입
}

/// 파일 URL로부터 FileType을 판단하는 유틸리티 클래스
class FileTypeHelper {
  /// 파일 URL로부터 FileType을 반환
  static FileType getFileType(String? fileUrl) {
    if (fileUrl == null || fileUrl.isEmpty) return FileType.unknown;

    final lowerUrl = fileUrl.toLowerCase();
    
    // PDF 파일 확인 (contains 사용하여 URL 끝에 문자가 있어도 인식)
    if (lowerUrl.contains('.pdf')) {
      return FileType.pdf;
    }
    
    // 이미지 파일 확인
    if (lowerUrl.contains('.jpg') || 
        lowerUrl.contains('.jpeg') || 
        lowerUrl.contains('.png') ||
        lowerUrl.contains('.gif') ||
        lowerUrl.contains('.webp') ||
        lowerUrl.contains('.bmp')) {
      return FileType.image;
    }
    
    return FileType.unknown;
  }

  /// 이미지 파일인지 확인
  static bool isImageFile(String url) {
    return url.endsWith('.jpg') || 
           url.endsWith('.jpeg') || 
           url.endsWith('.png') || 
           url.endsWith('.gif') || 
           url.endsWith('.webp') ||
           url.endsWith('.bmp');
  }

  /// PDF 파일인지 확인
  static bool isPdfFile(String url) {
    return url.endsWith('.pdf');
  }

  /// 파일 확장자 반환
  static String getFileExtension(FileType fileType) {
    switch (fileType) {
      case FileType.pdf:
        return '.pdf';
      case FileType.image:
        return '.jpg';
      case FileType.unknown:
        return '';
    }
  }

  /// URL 정리 (끝에 붙은 불필요한 문자 제거)
  static String cleanUrl(String url) {
    // URL 끝에 붙은 '?' 또는 기타 문자 제거
    if (url.endsWith('?')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  /// PDF를 이미지로 변환하는 URL 생성 (Google Drive 방식)
  static String getPdfPreviewUrl(String pdfUrl) {
    final cleanedUrl = cleanUrl(pdfUrl);
    // Supabase 또는 다른 저장소의 PDF를 첫 페이지 이미지로 변환
    // 일단 참고: https://docs.google.com/viewer?url=YOUR_PDF_URL&embedded=true
    // 또는 PDF.js 사용: https://mozilla.github.io/pdf.js/web/viewer.html?file=YOUR_PDF_URL
    return 'https://docs.google.com/viewer?url=${Uri.encodeComponent(cleanedUrl)}&embedded=true';
  }
}
