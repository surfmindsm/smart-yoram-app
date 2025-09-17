import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import 'package:qr_flutter/qr_flutter.dart';
import '../models/member.dart' as MemberModel;
import '../models/qr_code.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';
import '../services/member_service.dart';
import '../services/qr_service.dart';
import '../services/attendance_service.dart';

class MemberCardScreen extends StatefulWidget {
  const MemberCardScreen({super.key});

  @override
  State<MemberCardScreen> createState() => _MemberCardScreenState();
}

class _MemberCardScreenState extends State<MemberCardScreen> {
  final AuthService _authService = AuthService();
  final MemberService _memberService = MemberService();
  final QRService _qrService = QRService();
  final AttendanceService _attendanceService = AttendanceService();
  
  MemberModel.Member? currentMember;
  QRCodeInfo? memberQRCode;
  bool isLoading = true;
  bool isLoadingQR = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentMember();
  }

  Future<void> _loadCurrentMember() async {
    setState(() => isLoading = true);
    
    try {
      // 현재 로그인된 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        throw Exception('로그인 정보를 찾을 수 없습니다');
      }
      
      final user = userResponse.data!;
      
      // 사용자에 해당하는 교인 정보 가져오기 (임시로 모든 교인 중 첫 번째 사용)
      final memberResponse = await _memberService.getMembers(limit: 1);
      if (!memberResponse.success || memberResponse.data == null || memberResponse.data!.isEmpty) {
        throw Exception('교인 정보를 찾을 수 없습니다');
      }
      
      currentMember = memberResponse.data!.first;
      
      // 교인의 QR 코드 가져오기
      await _loadMemberQRCode();
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('교인 정보 로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadMemberQRCode() async {
    if (currentMember == null) return;
    
    setState(() => isLoadingQR = true);
    
    try {
      final response = await _qrService.getMemberQRCodes(currentMember!.id);
      if (response.success && response.data != null && response.data!.isNotEmpty) {
        // 가장 최근만들어진 활성 QR 코드 사용
        memberQRCode = response.data!.where((qr) => qr.isActive).first;
      } else {
        // QR 코드가 없으면 새로 생성
        await _generateNewQRCode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR 코드 로드 실패: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => isLoadingQR = false);
    }
  }
  
  Future<void> _generateNewQRCode() async {
    if (currentMember == null) return;
    
    try {
      final response = await _qrService.generateQRCode(currentMember!.id);
      if (response.success && response.data != null) {
        memberQRCode = response.data;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR 코드 생성 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('교인증'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'download':
                  _downloadMemberCard();
                  break;
                case 'share':
                  _shareMemberCard();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('다운로드'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('공유'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentMember == null
              ? const Center(child: Text('교인 정보를 찾을 수 없습니다'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildMemberCard(),
                      const SizedBox(height: 30),
                      _buildQRCode(),
                      const SizedBox(height: 30),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMemberCard() {
    return Container(
      width: double.infinity,
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[700]!,
            Colors.blue[500]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 교회명
            const Text(
              '새로운 교회',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'CHURCH MEMBER CARD',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            
            const Spacer(),
            
            // 교인 정보
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 프로필 사진 영역
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                    image: currentMember!.fullProfilePhotoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(currentMember!.fullProfilePhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: currentMember!.fullProfilePhotoUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        )
                      : null,
                ),
                
                const SizedBox(width: 16),
                
                // 교인 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentMember!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (currentMember!.position != null)
                        Text(
                          currentMember!.position!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      if (currentMember!.district != null)
                        Text(
                          currentMember!.district!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // 하단 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MEMBER ID',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      currentMember!.id.toString().padLeft(6, '0'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                if (currentMember!.registrationDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'SINCE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${currentMember!.registrationDate!.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCode() {
    return Column(
      children: [
        const Text(
          'QR 출석 체크',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLoadingQR
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : memberQRCode != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: QrImageView(
                        data: memberQRCode!.code,
                        version: QrVersions.auto,
                        size: 168,
                        backgroundColor: Colors.white,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.qr_code,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'QR 코드 생성 실패',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _generateNewQRCode,
                            child: const Text('다시 생성'),
                          ),
                        ],
                      ),
                    ),
        ),
        const SizedBox(height: 12),
        const Text(
          '출석 체크 시 이 QR 코드를 스캔해 주세요',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showAttendanceHistory,
            icon: const Icon(Icons.history),
            label: const Text('출석 기록 보기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _downloadMemberCard,
                icon: const Icon(Icons.download),
                label: const Text('다운로드'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareMemberCard,
                icon: const Icon(Icons.share),
                label: const Text('공유'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAttendanceHistory() async {
    if (currentMember == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('출석 기록'),
        content: SizedBox(
          height: 300,
          width: 350,
          child: FutureBuilder<ApiResponse<List<AttendanceRecord>>>(
            future: _attendanceService.getMemberAttendanceRecords(
              currentMember!.id,
              limit: 10,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text('오류: ${snapshot.error}'),
                );
              }
              
              final response = snapshot.data;
              if (response == null || !response.success || response.data == null) {
                return const Center(
                  child: Text('출석 기록을 불러올 수 없습니다'),
                );
              }
              
              final records = response.data!;
              if (records.isEmpty) {
                return const Center(
                  child: Text('출석 기록이 없습니다'),
                );
              }
              
              return ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final isPresent = record.attendanceType == 'present' || record.attendanceType == 'attended';
                  
                  return ListTile(
                    leading: Icon(
                      isPresent ? Icons.check_circle : Icons.close,
                      color: isPresent ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      record.attendanceDate.toLocal().toString().split(' ')[0],
                    ),
                    subtitle: Text(
                      isPresent ? '출석' : '결석',
                    ),
                    trailing: Text(
                      record.createdAt.toLocal().toString().split(' ')[1].substring(0, 5),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _downloadMemberCard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('교인증이 다운로드되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareMemberCard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('교인증이 공유되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
