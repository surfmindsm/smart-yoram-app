import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _testResult = '테스트를 시작하려면 버튼을 눌러주세요.';
  bool _isLoading = false;
  Color _resultColor = Colors.grey;

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'API 연결을 테스트 중입니다...';
      _resultColor = Colors.orange;
    });

    try {
      // Swagger 문서 페이지로 테스트 (더 확실한 엔드포인트)
      final docsResponse = await http.get(
        Uri.parse('https://packs-holds-marc-extended.trycloudflare.com/docs'),
        headers: {'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'},
      ).timeout(const Duration(seconds: 10));

      if (docsResponse.statusCode == 200) {
        setState(() {
          _testResult = '✅ API 서버 연결 성공!\n'
              '상태 코드: ${docsResponse.statusCode}\n'
              'Swagger 문서 접근 가능\n'
              'Base URL: ${ApiConfig.baseUrl}\n'
              'Docs URL: 정상 접근 가능';
          _resultColor = Colors.green;
        });
        return;
      }

      // Swagger docs가 안 되면 기본 API root 테스트
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl),
        headers: ApiConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _testResult = '✅ API 연결 성공!\n'
              '상태 코드: ${response.statusCode}\n'
              '서버 응답 시간: 정상\n'
              'Base URL: ${ApiConfig.baseUrl}';
          _resultColor = Colors.green;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _testResult = '⚠️ 404 오류 - 엔드포인트를 찾을 수 없음\n'
              '현재 URL: ${ApiConfig.baseUrl}\n'
              '해결방법:\n'
              '1. Base URL이 올바른지 확인\n'
              '2. API 서버가 실행 중인지 확인\n'
              '3. 네트워크 상태 확인\n'
              '\n올바른 URL 예시:\n'
              '- https://packs-holds-marc-extended.trycloudflare.com/docs (Swagger)\n'
              '- 서버 상태는 정상이지만 해당 경로가 없을 수 있음';
          _resultColor = Colors.orange;
        });
      } else {
        setState(() {
          _testResult = '⚠️ API 연결 실패\n'
              '상태 코드: ${response.statusCode}\n'
              '응답: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}';
          _resultColor = Colors.orange;
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ API 연결 오류\n'
            '오류 내용: $e\n'
            '\n확인사항:\n'
            '1. 인터넷 연결 확인\n'
            '2. 서버 상태 확인 (cloudflare tunnel 상태)\n'
            '3. Base URL 확인: ${ApiConfig.baseUrl}\n'
            '\n참고: cloudflare tunnel은 임시 URL이므로\n'
            '주기적으로 변경될 수 있습니다.';
        _resultColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSpecificEndpoint(String endpoint, String endpointName) async {
    setState(() {
      _isLoading = true;
      _testResult = '$endpointName 엔드포인트를 테스트 중입니다...';
      _resultColor = Colors.orange;
    });

    try {
      final fullUrl = ApiConfig.baseUrl + endpoint;
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: ApiConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        if (response.statusCode == 200) {
          _testResult = '$endpointName 테스트 결과:\n'
              '✅ 성공!\n'
              '상태 코드: ${response.statusCode}\n'
              '응답 길이: ${response.body.length} 바이트\n'
              'URL: $fullUrl';
          _resultColor = Colors.green;
        } else if (response.statusCode == 401) {
          _testResult = '$endpointName 테스트 결과:\n'
              '⚠️ 401 인증 필요\n'
              '상태 코드: ${response.statusCode}\n'
              '이는 정상적인 반응입니다.\n'
              '로그인 후 사용 가능한 엔드포인트입니다.\n'
              'URL: $fullUrl';
          _resultColor = Colors.orange;
        } else if (response.statusCode == 404) {
          _testResult = '$endpointName 테스트 결과:\n'
              '❌ 404 엔드포인트 없음\n'
              '상태 코드: ${response.statusCode}\n'
              'URL: $fullUrl\n'
              '해당 엔드포인트가 아직 구현되지 않았을 수 있습니다.';
          _resultColor = Colors.red;
        } else {
          _testResult = '$endpointName 테스트 결과:\n'
              '상태 코드: ${response.statusCode}\n'
              '응답 길이: ${response.body.length} 바이트\n'
              'URL: $fullUrl\n'
              '응답: ${response.body.length > 100 ? response.body.substring(0, 100) + "..." : response.body}';
          _resultColor = Colors.orange;
        }
      });
    } catch (e) {
      setState(() {
        _testResult = '$endpointName 테스트 오류:\n'
            '오류: $e\n'
            'URL: ${ApiConfig.baseUrl + endpoint}\n'
            '네트워크 연결 또는 서버 상태를 확인하세요.';
        _resultColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSwaggerDocs() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Swagger 문서 접근을 테스트 중입니다...';
      _resultColor = Colors.orange;
    });

    try {
      final docsResponse = await http.get(
        Uri.parse('https://packs-holds-marc-extended.trycloudflare.com/docs'),
        headers: {'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'},
      ).timeout(const Duration(seconds: 15));

      if (docsResponse.statusCode == 200) {
        setState(() {
          _testResult = '✅ Swagger 문서 접근 성공!\n'
              '상태 코드: ${docsResponse.statusCode}\n'
              'Content-Type: ${docsResponse.headers['content-type'] ?? 'N/A'}\n'
              '응답 길이: ${docsResponse.body.length} 바이트\n'
              'URL: https://packs-holds-marc-extended.trycloudflare.com/docs\n'
              '\n이것은 API 서버가 정상적으로 작동하고 있음을 의미합니다!';
          _resultColor = Colors.green;
        });
      } else {
        setState(() {
          _testResult = '⚠️ Swagger 문서 접근 실패\n'
              '상태 코드: ${docsResponse.statusCode}\n'
              'URL: https://packs-holds-marc-extended.trycloudflare.com/docs\n'
              '응답: ${docsResponse.body.length > 100 ? docsResponse.body.substring(0, 100) + "..." : docsResponse.body}';
          _resultColor = Colors.orange;
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Swagger 문서 접근 오류\n'
            '오류: $e\n'
            'URL: https://packs-holds-marc-extended.trycloudflare.com/docs\n'
            '\n가능한 원인:\n'
            '1. 인터넷 연결 문제\n'
            '2. Cloudflare Tunnel 망크 만료\n'
            '3. 서버 일시 중단\n'
            '\n참고: Cloudflare Tunnel URL은 임시이므로\n'
            '주기적으로 업데이트가 필요할 수 있습니다.';
        _resultColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 연결 테스트'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API 설정 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Base URL: ${ApiConfig.baseUrl}'),
                    Text('Swagger Docs: ${ApiConfig.swaggerDocsUrl}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Swagger 문서 직접 테스트
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSwaggerDocs,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.description),
              label: const Text('Swagger 문서 테스트'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 기본 연결 테스트
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testApiConnection,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_protected_setup),
              label: const Text('기본 API 연결 테스트'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 개별 엔드포인트 테스트 버튼들
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _testSpecificEndpoint(ApiConfig.members, '교인관리'),
                  child: const Text('교인관리'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _testSpecificEndpoint(ApiConfig.attendances, '출석관리'),
                  child: const Text('출석관리'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _testSpecificEndpoint(ApiConfig.calendar, '일정관리'),
                  child: const Text('일정관리'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _testSpecificEndpoint(ApiConfig.qrCodes, 'QR코드'),
                  child: const Text('QR코드'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 테스트 결과 표시
            Card(
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _resultColor, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _resultColor == Colors.green 
                              ? Icons.check_circle
                              : _resultColor == Colors.red 
                                  ? Icons.error
                                  : Icons.info,
                          color: _resultColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '테스트 결과',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _testResult,
                      style: TextStyle(
                        color: _resultColor,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 도움말
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          '테스트 가이드',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• ✅ 녹색: API 연결 성공\n'
                      '• ⚠️ 주황색: 서버 응답 있지만 확인 필요\n'
                      '• ❌ 빨간색: 연결 실패 또는 오류\n\n'
                      'API 문서는 Swagger Docs에서 확인할 수 있습니다.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
