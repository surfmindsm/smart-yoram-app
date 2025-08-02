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
    
    if (isImageFile(lowerUrl)) {
      return FileType.image;
    } else if (isPdfFile(lowerUrl)) {
      return FileType.pdf;
    } else {
      return FileType.unknown;
    }
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
}
