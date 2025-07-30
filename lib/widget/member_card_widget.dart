import 'package:flutter/material.dart';
import '../models/church_member.dart';

/// 교인 정보를 표시하는 카드 위젯
class MemberCardWidget extends StatelessWidget {
  final ChurchMember member;
  final VoidCallback? onTap;
  final List<Widget>? actionButtons;
  final bool showDetails;

  const MemberCardWidget({
    super.key,
    required this.member,
    this.onTap,
    this.actionButtons,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 프로필 사진
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                child: member.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          member.photoUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.person, size: 30, color: Colors.grey[600]),
                        ),
                      )
                    : Icon(Icons.person, size: 30, color: Colors.grey[600]),
              ),
              
              const SizedBox(width: 16),
              
              // 멤버 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(member.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            member.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (showDetails) ...[
                      const SizedBox(height: 4),
                      Text(
                        member.position,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${member.district} • ${member.phone}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // 액션 버튼들
              if (actionButtons != null) ...actionButtons!,
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '출석':
        return Colors.green;
      case '이주':
        return Colors.orange;
      case '장기결석':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
