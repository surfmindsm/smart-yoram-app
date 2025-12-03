import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../resource/text_style_new.dart';
import '../resource/color_style_new.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // 알림 설정 상태
  String selectedSound = '알림음';
  bool chatNotifications = true;
  bool likeNotifications = true;
  bool churchNewsNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: NewAppColor.neutral800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '알림 설정',
          style: FigmaTextStyles()
              .headline4
              .copyWith(color: NewAppColor.neutral800),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 알림음 설정 섹션
          _buildSectionHeader('알림음 설정'),
          _buildNavigationTile(
            title: '알림음',
            subtitle: selectedSound,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSoundScreen(
                    selectedSound: selectedSound,
                  ),
                ),
              );
              if (result != null) {
                setState(() {
                  selectedSound = result;
                });
              }
            },
          ),
          Divider(height: 1, color: NewAppColor.neutral200),

          // 서비스별 푸시 알림 섹션
          _buildSectionHeader('서비스별 푸시 알림'),
          _buildSwitchTile(
            title: '채팅',
            subtitle: '새로운 채팅 메시지 알림을 받습니다',
            value: chatNotifications,
            onChanged: (value) {
              setState(() {
                chatNotifications = value;
              });
            },
          ),
          _buildSwitchTile(
            title: '좋아요',
            subtitle: '내 게시글에 좋아요를 받으면 알림을 받습니다',
            value: likeNotifications,
            onChanged: (value) {
              setState(() {
                likeNotifications = value;
              });
            },
          ),
          _buildSwitchTile(
            title: '교회 소식',
            subtitle: '교회 공지사항 및 소식 알림을 받습니다',
            value: churchNewsNotifications,
            onChanged: (value) {
              setState(() {
                churchNewsNotifications = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
      child: Text(
        title,
        style: FigmaTextStyles().body3.copyWith(
              color: NewAppColor.neutral800,
            ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral900,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: FigmaTextStyles().caption1.copyWith(
                          color: NewAppColor.neutral600,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Icon(
              Icons.chevron_right,
              color: NewAppColor.neutral400,
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: FigmaTextStyles().caption1.copyWith(
                        color: NewAppColor.neutral600,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: NewAppColor.primary600,
            activeTrackColor: NewAppColor.primary200,
            inactiveThumbColor: NewAppColor.neutral400,
            inactiveTrackColor: NewAppColor.neutral200,
          ),
        ],
      ),
    );
  }
}

// 알림음 선택 화면
class NotificationSoundScreen extends StatefulWidget {
  final String selectedSound;

  const NotificationSoundScreen({
    super.key,
    required this.selectedSound,
  });

  @override
  State<NotificationSoundScreen> createState() =>
      _NotificationSoundScreenState();
}

class _NotificationSoundScreenState extends State<NotificationSoundScreen> {
  late String _selectedSound;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final Map<String, String> _sounds = {
    '알림음': 'assets/sounds/알림음.mp3',
    '피아노': 'assets/sounds/피아노.mp3',
    '실로폰': 'assets/sounds/실로폰.mp3',
    '멜로디': 'assets/sounds/멜로디.mp3',
    '뾰로롱': 'assets/sounds/뾰로롱.mp3',
    '물방울': 'assets/sounds/물방울.mp3',
    '휘파람': 'assets/sounds/휘파람.mp3',
    '상승': 'assets/sounds/상승.mp3',
    '신호': 'assets/sounds/신호.mp3',
    '놀이터': 'assets/sounds/놀이터.mp3',
    '뭐해뭐해': 'assets/sounds/뭐해뭐해.mp3',
    '사랑해': 'assets/sounds/사랑해.mp3',
    '야': 'assets/sounds/야.mp3',
    '자니': 'assets/sounds/자니.mp3',
    '알림음 없음': '',
  };

  @override
  void initState() {
    super.initState();
    _selectedSound = widget.selectedSound;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String soundPath) async {
    if (soundPath.isEmpty) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer
          .play(AssetSource(soundPath.replaceFirst('assets/', '')));
    } catch (e) {
      print('알림음 재생 실패: $e');
      // 파일이 없어도 앱이 크래시되지 않도록 에러를 무시
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 시 선택된 알림음 반환
        Navigator.pop(context, _selectedSound);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: NewAppColor.primary600,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () {
              // 뒤로가기 버튼 클릭 시 선택된 알림음 반환
              Navigator.pop(context, _selectedSound);
            },
          ),
          title: Text(
            '알림음 선택',
            style: FigmaTextStyles().headline4.copyWith(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: ListView.builder(
          itemCount: _sounds.length,
          itemBuilder: (context, index) {
            final soundName = _sounds.keys.elementAt(index);
            final soundPath = _sounds[soundName]!;
            final isSelected = soundName == _selectedSound;

            return InkWell(
              onTap: () async {
                // 알림음 미리듣기
                await _playSound(soundPath);

                // 선택된 알림음 표시
                setState(() {
                  _selectedSound = soundName;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: NewAppColor.neutral200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        soundName,
                        style: FigmaTextStyles().body2.copyWith(
                              color: isSelected
                                  ? NewAppColor.primary600
                                  : NewAppColor.neutral900,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        color: NewAppColor.primary600,
                        size: 24.w,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
