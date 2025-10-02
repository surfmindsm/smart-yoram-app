import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

/// 파일 업로드 컴포넌트
class FileUploadField extends StatefulWidget {
  final Function(List<File>) onFilesChanged;
  final int maxFiles;
  final int maxFileSizeMB;

  const FileUploadField({
    super.key,
    required this.onFilesChanged,
    this.maxFiles = 5,
    this.maxFileSizeMB = 5,
  });

  @override
  State<FileUploadField> createState() => _FileUploadFieldState();
}

class _FileUploadFieldState extends State<FileUploadField> {
  final List<File> _files = [];
  final ImagePicker _imagePicker = ImagePicker();

  // 파일 선택
  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        final newFiles = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();

        // 파일 개수 확인
        if (_files.length + newFiles.length > widget.maxFiles) {
          _showError('최대 ${widget.maxFiles}개까지 업로드 가능합니다.');
          return;
        }

        // 파일 크기 확인
        for (final file in newFiles) {
          final fileSizeMB = file.lengthSync() / (1024 * 1024);
          if (fileSizeMB > widget.maxFileSizeMB) {
            _showError(
                '${_getFileName(file)} 파일이 ${widget.maxFileSizeMB}MB를 초과합니다.');
            return;
          }
        }

        setState(() {
          _files.addAll(newFiles);
        });
        widget.onFilesChanged(_files);
      }
    } catch (e) {
      _showError('파일 선택 중 오류가 발생했습니다.');
    }
  }

  // 카메라로 사진 촬영
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        final file = File(photo.path);

        // 파일 개수 확인
        if (_files.length >= widget.maxFiles) {
          _showError('최대 ${widget.maxFiles}개까지 업로드 가능합니다.');
          return;
        }

        // 파일 크기 확인
        final fileSizeMB = file.lengthSync() / (1024 * 1024);
        if (fileSizeMB > widget.maxFileSizeMB) {
          _showError('파일 크기가 ${widget.maxFileSizeMB}MB를 초과합니다.');
          return;
        }

        setState(() {
          _files.add(file);
        });
        widget.onFilesChanged(_files);
      }
    } catch (e) {
      _showError('사진 촬영 중 오류가 발생했습니다.');
    }
  }

  // 파일 삭제
  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
    widget.onFilesChanged(_files);
  }

  // 파일명 추출
  String _getFileName(File file) {
    return file.path.split('/').last;
  }

  // 파일 크기 포맷팅
  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // 파일 아이콘
  IconData _getFileIcon(File file) {
    final extension = _getFileName(file).split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  // 에러 메시지 표시
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: NewAppColor.danger600,
      ),
    );
  }

  // 파일 선택 방법 다이얼로그
  void _showFilePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: NewAppColor.primary600),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickFiles();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: NewAppColor.primary600),
              title: const Text('사진 촬영'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.folder, color: NewAppColor.primary600),
              title: const Text('파일 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickFiles();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const figmaStyles = FigmaTextStyles();

    return Column(
      children: [
        // 드래그 앤 드롭 영역 (모바일에서는 탭)
        GestureDetector(
          onTap: _showFilePickerDialog,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: NewAppColor.neutral200,
                width: 1,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48.w,
                  color: NewAppColor.neutral400,
                ),
                SizedBox(height: 12.h),
                Text(
                  '파일을 업로드하려면 클릭하세요',
                  style: figmaStyles.body2.copyWith(
                    color: NewAppColor.neutral600,
                    fontFamily: 'Pretendard Variable',
                    letterSpacing: -0.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'PDF, JPG, PNG, DOC (최대 ${widget.maxFiles}개, 각 ${widget.maxFileSizeMB}MB 이하)',
                  style: figmaStyles.captionText1.copyWith(
                    color: NewAppColor.neutral500,
                    fontFamily: 'Pretendard Variable',
                    letterSpacing: -0.30,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_files.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Text(
                    '${_files.length}개 파일 선택됨',
                    style: figmaStyles.body2.copyWith(
                      color: NewAppColor.primary600,
                      fontFamily: 'Pretendard Variable',
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 선택된 파일 목록
        if (_files.isNotEmpty) ...[
          SizedBox(height: 16.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _files.length,
            separatorBuilder: (context, index) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final file = _files[index];
              return Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: NewAppColor.neutral100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(file),
                      size: 24.w,
                      color: NewAppColor.primary600,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFileName(file),
                            style: figmaStyles.body2.copyWith(
                              color: NewAppColor.neutral900,
                              fontFamily: 'Pretendard Variable',
                              letterSpacing: -0.35,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _getFileSize(file),
                            style: figmaStyles.captionText1.copyWith(
                              color: NewAppColor.neutral500,
                              fontFamily: 'Pretendard Variable',
                              letterSpacing: -0.30,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20.w,
                        color: NewAppColor.danger600,
                      ),
                      onPressed: () => _removeFile(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
