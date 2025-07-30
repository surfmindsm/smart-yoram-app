import 'package:flutter/material.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _isScanning = false;
  String? _scannedCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR 코드 스캔'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR 스캔 영역 (실제 구현시 qr_code_scanner 패키지 사용)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: const Center(
              child: Text(
                'QR 스캐너 영역\n(qr_code_scanner 패키지 필요)',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // 스캔 가이드 오버레이
          Container(
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: QRScanOverlayPainter(),
            ),
          ),
          
          // 하단 정보 패널
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'QR 코드를 카메라에 비춰주세요',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '출석 체크용 QR 코드를 스캔해주세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_scannedCode != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(height: 8),
                          Text('스캔 완료: $_scannedCode'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showMyQR,
                          icon: const Icon(Icons.qr_code),
                          label: const Text('내 QR 보기'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isScanning ? null : _startScan,
                          icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
                          label: Text(_isScanning ? '스캔 중지' : '스캔 시작'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
    });
    
    // TODO: 실제 QR 스캔 구현
    // 임시로 3초 후 스캔 완료로 시뮬레이션
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scannedCode = 'ATTENDANCE_${DateTime.now().millisecondsSinceEpoch}';
        });
        
        _showAttendanceResult();
      }
    });
  }

  void _toggleFlash() {
    // TODO: 플래시 토글 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('플래시 토글 기능은 추후 구현 예정입니다')),
    );
  }

  void _showMyQR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyQRCodeScreen(),
      ),
    );
  }

  void _showAttendanceResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('출석 완료'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('출석 체크가 완료되었습니다.'),
            SizedBox(height: 8),
            Text(
              '오늘도 예배에 참석해주셔서 감사합니다!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class QRScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final scanAreaRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 50),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // 전체 배경을 어둡게
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 스캔 영역만 투명하게
    paint.blendMode = BlendMode.clear;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanAreaRect, const Radius.circular(16)),
      paint,
    );

    // 스캔 가이드 모서리 그리기
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;
    
    // 좌상단
    canvas.drawLine(
      Offset(scanAreaRect.left, scanAreaRect.top + cornerLength),
      Offset(scanAreaRect.left, scanAreaRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.left, scanAreaRect.top),
      Offset(scanAreaRect.left + cornerLength, scanAreaRect.top),
      cornerPaint,
    );

    // 우상단
    canvas.drawLine(
      Offset(scanAreaRect.right - cornerLength, scanAreaRect.top),
      Offset(scanAreaRect.right, scanAreaRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.right, scanAreaRect.top),
      Offset(scanAreaRect.right, scanAreaRect.top + cornerLength),
      cornerPaint,
    );

    // 좌하단
    canvas.drawLine(
      Offset(scanAreaRect.left, scanAreaRect.bottom - cornerLength),
      Offset(scanAreaRect.left, scanAreaRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.left, scanAreaRect.bottom),
      Offset(scanAreaRect.left + cornerLength, scanAreaRect.bottom),
      cornerPaint,
    );

    // 우하단
    canvas.drawLine(
      Offset(scanAreaRect.right - cornerLength, scanAreaRect.bottom),
      Offset(scanAreaRect.right, scanAreaRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.right, scanAreaRect.bottom),
      Offset(scanAreaRect.right, scanAreaRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MyQRCodeScreen extends StatelessWidget {
  const MyQRCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 QR 코드'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '김성도',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '○○교회 | 일반교인',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    
                    // QR 코드 영역 (실제 구현시 qr_flutter 패키지 사용)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code, size: 80, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'QR 코드\n(qr_flutter 패키지 필요)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    const Text(
                      '출석 체크시 이 QR 코드를 스캔해주세요',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: QR 코드 저장 기능
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR 코드 저장 기능은 추후 구현 예정입니다')),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('저장'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: QR 코드 공유 기능
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR 코드 공유 기능은 추후 구현 예정입니다')),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('공유'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
