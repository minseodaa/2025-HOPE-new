import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';

/// Training API client
/// - GET    /training/sessions                 → fetchSessions()
/// - POST   /training/sessions                 → startSession()
/// - GET    /training/sessions/{sid}           → fetchSessionDetail()
/// - POST   /training/sessions/{sid}/sets      → saveSet()      (이미지 제외)
/// - PUT    /training/sessions/{sid}           → closeSession()
class TrainingApiService {
  final http.Client _client;
  TrainingApiService({http.Client? client}) : _client = client ?? http.Client();

  // ---------------------- Helpers ----------------------

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (query == null || query.isEmpty) return base;

    final qp = <String, String>{};
    query.forEach((k, v) {
      if (v == null) return;
      final s = '$v';
      if (s.isEmpty) return;
      qp[k] = s;
    });
    return base.replace(queryParameters: qp);
  }

  Future<Map<String, String>> _headers({bool forceRefresh = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken(forceRefresh);
      return {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
    } catch (_) {
      return {'Content-Type': 'application/json'};
    }
  }

  void _ok(String m) => print('\x1B[32m[OK] $m\x1B[0m');
  void _err(String m) => print('\x1B[31m[ERR] $m\x1B[0m');
  void _401() => print('\x1B[33m[401] retry with fresh token\x1B[0m');

  // ---------------------- Endpoints ----------------------

  /// 세션 목록 조회
  /// 응답 스키마(스웨거): { "sessions": [...], "nextPageToken": "..." }
  Future<Map<String, dynamic>> fetchSessions({
    String? expr, // neutral | smile | angry | sad
    String? status, // ongoing | completed
    DateTime? from, // ISO8601
    DateTime? to, // ISO8601
    int pageSize = 20, // default 20
    String? pageToken,
  }) async {
    final url = _uri('/training/sessions', {
      if (expr != null) 'expr': expr,
      if (status != null) 'status': status,
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
      'pageSize': pageSize,
      if (pageToken != null) 'pageToken': pageToken,
    });

    var res = await _client
        .get(url, headers: await _headers())
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) {
      _401();
      res = await _client
          .get(url, headers: await _headers(forceRefresh: true))
          .timeout(const Duration(seconds: 20));
    }

    if (res.statusCode == 200) {
      _ok('fetchSessions 200');
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        // 혹시 서버가 다른 키명으로 내려주면 호환 처리
        decoded.putIfAbsent('sessions', () => decoded['items'] ?? const []);
        decoded.putIfAbsent('nextPageToken', () => decoded['nextToken']);
        return decoded;
      }
      // 배열만 내려오는 경우 호환
      return {'sessions': decoded, 'nextPageToken': null};
    }

    _err('fetchSessions ${res.statusCode} ${res.body}');
    throw Exception('세션 목록 실패 (${res.statusCode})');
  }

  /// 새로운 훈련 세션 시작
  /// req: { "expr": "smile" }
  /// res: { "sid": "..." }
  Future<String> startSession(String expr) async {
    final url = _uri('/training/sessions');
    final body = jsonEncode({'expr': expr});

    var res = await _client
        .post(url, headers: await _headers(), body: body)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) {
      _401();
      res = await _client
          .post(url, headers: await _headers(forceRefresh: true), body: body)
          .timeout(const Duration(seconds: 20));
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final sid = (map['sid'] ?? map['id'])?.toString();
      if (sid == null || sid.isEmpty) {
        _err('startSession: missing sid. body=${res.body}');
        throw Exception('세션 시작 실패(응답 sid 없음)');
      }
      _ok('startSession sid=$sid');
      return sid;
    }

    _err('startSession ${res.statusCode} ${res.body}');
    throw Exception('세션 시작 실패 (${res.statusCode})');
  }

  /// 세트 저장 (이미지 제외)
  /// frames는 정확히 15개, 각 원소는 { "키": {"x": number, "y": number}, ... }
  /// res 예시: { "score": 67.8, "lastFrameImage": "string" }
  Future<void> saveSet({
    required String sid,
    required double score,
    required List<Map<String, Map<String, num>>> frames,
  }) async {
    // 방어적 길이 보정: 서버 검증이 15프레임을 기대
    final fixed = List<Map<String, Map<String, num>>>.from(frames);
    while (fixed.length < 15) {
      fixed.add(
        fixed.isNotEmpty
            ? fixed.last
            : {
                'noop': {'x': 0, 'y': 0},
              },
      );
    }
    if (fixed.length > 15) fixed.removeRange(15, fixed.length);

    final url = _uri('/training/sessions/$sid/sets');
    final body = jsonEncode({'score': score, 'frames': fixed});

    var res = await _client
        .post(url, headers: await _headers(), body: body)
        .timeout(const Duration(seconds: 25));

    if (res.statusCode == 401) {
      _401();
      res = await _client
          .post(url, headers: await _headers(forceRefresh: true), body: body)
          .timeout(const Duration(seconds: 25));
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      _ok('saveSet ${res.statusCode}');
      return;
    }

    _err('saveSet ${res.statusCode} ${res.body}');
    throw Exception('세트 저장 실패 (${res.statusCode})');
  }

  /// 세션 상세 조회
  /// res: { "session": { ... , "sets": [ ... ] } }
  Future<Map<String, dynamic>> fetchSessionDetail(String sid) async {
    final url = _uri('/training/sessions/$sid');

    var res = await _client
        .get(url, headers: await _headers())
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) {
      _401();
      res = await _client
          .get(url, headers: await _headers(forceRefresh: true))
          .timeout(const Duration(seconds: 20));
    }

    if (res.statusCode == 200) {
      _ok('fetchSessionDetail 200');
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    _err('fetchSessionDetail ${res.statusCode} ${res.body}');
    throw Exception('세션 상세 실패 (${res.statusCode})');
  }

  /// 세션 마감 (최종 점수 계산)
  /// req: { "summary": "..." }  // finalScore는 서버가 계산하면 생략
  /// res: { "finalScore": number, "setsCount": number }
  Future<Map<String, dynamic>> closeSession({
    required String sid,
    String? summary,
    double? finalScore,
  }) async {
    final url = _uri('/training/sessions/$sid');
    final body = jsonEncode({
      if (summary != null) 'summary': summary,
      if (finalScore != null) 'finalScore': finalScore,
    });

    var res = await _client
        .put(url, headers: await _headers(), body: body)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) {
      _401();
      res = await _client
          .put(url, headers: await _headers(forceRefresh: true), body: body)
          .timeout(const Duration(seconds: 20));
    }

    if (res.statusCode == 200) {
      _ok('closeSession 200');
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    _err('closeSession ${res.statusCode} ${res.body}');
    throw Exception('세션 마감 실패 (${res.statusCode})');
  }
}
