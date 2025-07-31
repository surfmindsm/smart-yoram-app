import 'package:flutter/material.dart';
import '../models/bulletin.dart';
import '../services/bulletin_service.dart';
import '../widget/widgets.dart';

class BulletinScreen extends StatefulWidget {
  const BulletinScreen({super.key});

  @override
  State<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends State<BulletinScreen> {
  final BulletinService _bulletinService = BulletinService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Bulletin> allBulletins = [];
  List<Bulletin> filteredBulletins = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBulletins();
    _searchController.addListener(_filterBulletins);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBulletins() async {
    setState(() => isLoading = true);
    
    try {
      print('🔍 BULLETIN_SCREEN: 주보 목록 로드 시작');
      final response = await _bulletinService.getBulletins(limit: 50);
      
      if (response.success && response.data != null) {
        print('🔍 BULLETIN_SCREEN: API 호출 성공 - ${response.data!.length}개 주보 로드');
        allBulletins = response.data!;
        filteredBulletins = List.from(allBulletins);
      } else {
        print('🔍 BULLETIN_SCREEN: API 호출 실패 - ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('주보 정보 로드 실패: ${response.message}')),
          );
        }
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      print('🔍 BULLETIN_SCREEN: 예외 발생 - $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주보 정보 로드 실패: $e')),
        );
      }
    }
  }



  void _filterBulletins() {
    String query = _searchController.text.toLowerCase();
    
    setState(() {
      filteredBulletins = allBulletins.where((bulletin) {
        return bulletin.title.toLowerCase().contains(query) ||
               (bulletin.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '주보',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색창
          if (_searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '주보 제목이나 내용을 검색하세요',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          
          // 주보 목록
          Expanded(
            child: isLoading
                ? const LoadingWidget()
                : filteredBulletins.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.description_outlined,
                        title: '주보가 없습니다',
                        subtitle: '아직 등록된 주보가 없습니다',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBulletins,
                        child: ListView.builder(
                          itemCount: filteredBulletins.length,
                          itemBuilder: (context, index) {
                            final bulletin = filteredBulletins[index];
                            return _buildBulletinCard(bulletin);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "bulletin_fab",
        onPressed: _showAddBulletinDialog,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBulletinCard(Bulletin bulletin) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _viewBulletin(bulletin),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목과 날짜
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      bulletin.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      _formatDate(bulletin.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 설명
              if (bulletin.description != null)
                Text(
                  bulletin.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: 12),
              
              // 파일 정보 및 액션 버튼
              Row(
                children: [
                  Icon(
                    bulletin.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    bulletin.fileType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (bulletin.fileSize != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      _formatFileSize(bulletin.fileSize!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // 액션 버튼들
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 20),
                        onPressed: () => _viewBulletin(bulletin),
                        tooltip: '보기',
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, size: 20),
                        onPressed: () => _downloadBulletin(bulletin),
                        tooltip: '다운로드',
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: () => _shareBulletin(bulletin),
                        tooltip: '공유',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}.${date.day}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주보 검색'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '검색어를 입력하세요',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('검색'),
          ),
        ],
      ),
    );
  }

  void _viewBulletin(Bulletin bulletin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bulletin.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('날짜: ${_formatDate(bulletin.date)}'),
            if (bulletin.description != null) ...[
              const SizedBox(height: 8),
              Text('설명: ${bulletin.description}'),
            ],
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('주보 미리보기'),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadBulletin(bulletin);
            },
            child: const Text('다운로드'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadBulletin(Bulletin bulletin) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${bulletin.title} 다운로드 중...'),
          action: SnackBarAction(
            label: '취소',
            onPressed: () {},
          ),
        ),
      );

      final response = await _bulletinService.downloadBulletin(bulletin.id);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${bulletin.title} 다운로드 완료')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('다운로드 실패: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e')),
        );
      }
    }
  }

  void _shareBulletin(Bulletin bulletin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주보 공유'),
        content: Text('${bulletin.title}을 공유하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('주보가 공유되었습니다')),
              );
            },
            child: const Text('공유'),
          ),
        ],
      ),
    );
  }

  void _showAddBulletinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주보 추가'),
        content: const Text('주보 추가 기능은 관리자 권한이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
