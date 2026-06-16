import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import '../components/index.dart';
import '../resource/text_style_new.dart';
import '../resource/color_style_new.dart';
import '../services/notification_settings_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 알림 설정 화면 — 1.2.0 C 방향
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  String selectedSound = '알림음';
  bool chatNotifications = true;
  bool likeNotifications = true;
  bool churchNewsNotifications = true;
  bool churchMessageNotifications = true;
  bool _isLoading = true;

  final _settingsService = NotificationSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final chat = await _settingsService.getChatNotifications();
      final like = await _settingsService.getLikeNotifications();
      final news = await _settingsService.getChurchNewsNotifications();
      final message = await _settingsService.getChurchMessageNotifications();
      final sound = await _settingsService.getNotificationSound();

      setState(() {
        chatNotifications = chat;
        likeNotifications = like;
        churchNewsNotifications = news;
        churchMessageNotifications = message;
        selectedSound = sound;
        _isLoading = false;
      });
    } catch (e) {
      print('알림 설정 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: NewAppColor.canvasAlt,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        leading: material.IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 26.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '알림 설정',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 18.sp,
              ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: NewAppColor.skyPrimary),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('알림음 설정'),
                  SizedBox(height: 8.h),
                  _buildCard([
                    _buildNavRow(
                      icon: LucideIcons.music,
                      title: '알림음',
                      value: selectedSound,
                      onTap: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationSoundScreen(
                              selectedSound: selectedSound,
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() => selectedSound = result);
                          await _settingsService.setNotificationSound(result);
                        }
                      },
                    ),
                  ]),
                  SizedBox(height: 20.h),
                  _buildSectionHeader('서비스별 푸시 알림'),
                  SizedBox(height: 8.h),
                  _buildCard([
                    _buildSwitchRow(
                      icon: LucideIcons.messageCircle,
                      iconBg: NewAppColor.skyTint,
                      iconFg: NewAppColor.skyDeep,
                      title: '채팅',
                      description: '새로운 채팅 메시지 알림을 받습니다',
                      value: chatNotifications,
                      onChanged: (value) async {
                        setState(() => chatNotifications = value);
                        await _settingsService.setChatNotifications(value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchRow(
                      icon: LucideIcons.heart,
                      iconBg: NewAppColor.dangerBg,
                      iconFg: NewAppColor.danger700,
                      title: '좋아요',
                      description: '내 게시글에 좋아요를 받으면 알림을 받습니다',
                      value: likeNotifications,
                      onChanged: (value) async {
                        setState(() => likeNotifications = value);
                        await _settingsService.setLikeNotifications(value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchRow(
                      icon: LucideIcons.megaphone,
                      iconBg: NewAppColor.warningBg,
                      iconFg: NewAppColor.warning700,
                      title: '교회 소식',
                      description: '교회 공지사항 및 소식 알림을 받습니다',
                      value: churchNewsNotifications,
                      onChanged: (value) async {
                        setState(() => churchNewsNotifications = value);
                        await _settingsService.setChurchNewsNotifications(value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchRow(
                      icon: LucideIcons.mailOpen,
                      iconBg: NewAppColor.successBg,
                      iconFg: NewAppColor.success700,
                      title: '교회 메시지',
                      description: '관리자 커스텀 메시지 알림을 받습니다',
                      value: churchMessageNotifications,
                      onChanged: (value) async {
                        setState(() => churchMessageNotifications = value);
                        await _settingsService
                            .setChurchMessageNotifications(value);
                      },
                    ),
                  ]),
                  SizedBox(height: 20.h),
                  _buildHint(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          color: NewAppColor.textTertiary,
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: NewAppColor.borderHair,
      margin: EdgeInsets.symmetric(horizontal: 14.w),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: NewAppColor.skyTint,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: NewAppColor.skyDeep, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: NewAppColor.textStrong,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: NewAppColor.textTertiary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(width: 4.w),
              Icon(LucideIcons.chevronRight,
                  color: NewAppColor.iconFaint, size: 19.sp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconBg,
    required Color iconFg,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconFg, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: NewAppColor.textStrong,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: TextStyle(
                    color: NewAppColor.textTertiary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          AppSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        '시스템 알림이 꺼져 있으면 앱 내 설정과 관계없이 알림이 전달되지 않을 수 있어요.',
        style: TextStyle(
          color: NewAppColor.textTertiary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
          height: 1.55,
        ),
      ),
    );
  }
}

/// 알림음 선택 화면 — 1.2.0 C 방향
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _selectedSound);
        return false;
      },
      child: Scaffold(
        backgroundColor: NewAppColor.canvasAlt,
        appBar: AppBar(
          backgroundColor: NewAppColor.canvasAlt,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleSpacing: 0,
          leading: material.IconButton(
            icon: Icon(LucideIcons.chevronLeft,
                color: NewAppColor.textStrong, size: 26.sp),
            onPressed: () => Navigator.pop(context, _selectedSound),
          ),
          title: Text(
            '알림음 선택',
            style: FigmaTextStyles().subtitle1.copyWith(
                  color: NewAppColor.textStrong,
                  fontSize: 18.sp,
                ),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 12.h),
                child: Text(
                  '항목을 누르면 미리 듣고 선택할 수 있어요.',
                  style: TextStyle(
                    color: NewAppColor.textTertiary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                    height: 1.55,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: NewAppColor.borderHair, width: 1),
                ),
                child: Column(
                  children: List.generate(_sounds.length, (index) {
                    final soundName = _sounds.keys.elementAt(index);
                    final soundPath = _sounds[soundName]!;
                    final isSelected = soundName == _selectedSound;
                    final isLast = index == _sounds.length - 1;
                    final isSilent = soundPath.isEmpty;

                    return Column(
                      children: [
                        Material(
                          color: isSelected
                              ? NewAppColor.skyTint.withOpacity(0.45)
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              if (!isSilent) await _playSound(soundPath);
                              setState(() => _selectedSound = soundName);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 14.h),
                              child: Row(
                                children: [
                                  // 라디오 인디케이터
                                  Container(
                                    width: 20.w,
                                    height: 20.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? NewAppColor.skyPrimary
                                            : NewAppColor.borderStrong,
                                        width: isSelected ? 5.5 : 1.5,
                                      ),
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 14.w),
                                  // 사운드 이름
                                  Expanded(
                                    child: Row(
                                      children: [
                                        if (isSilent) ...[
                                          Icon(
                                            LucideIcons.volumeX,
                                            size: 16.sp,
                                            color: NewAppColor.textTertiary,
                                          ),
                                          SizedBox(width: 6.w),
                                        ],
                                        Flexible(
                                          child: Text(
                                            soundName,
                                            style: TextStyle(
                                              color: NewAppColor.textStrong,
                                              fontSize: 14.5.sp,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              fontFamily: 'Pretendard',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 미리듣기 아이콘 (소리 있는 경우만)
                                  if (!isSilent)
                                    Container(
                                      width: 32.w,
                                      height: 32.w,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? NewAppColor.skyPrimary
                                            : NewAppColor.borderSoft,
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        LucideIcons.play,
                                        size: 18.sp,
                                        color: isSelected
                                            ? Colors.white
                                            : NewAppColor.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            height: 1,
                            color: NewAppColor.borderHair,
                            margin: EdgeInsets.only(left: 50.w, right: 14.w),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
