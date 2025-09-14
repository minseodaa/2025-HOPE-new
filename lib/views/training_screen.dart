import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../controllers/camera_controller.dart' as camera_ctrl;
import '../utils/constants.dart';
import '../models/expression_type.dart';
import 'camera_preview_widget.dart';
import 'score_display_widget.dart';
import 'feedback_widget.dart';
import 'training_result_screen.dart';

// API
import '../services/training_api_service.dart';

enum _SessionPhase { idle, training, rest, done }

class TrainingScreen extends StatefulWidget {
  final CameraDescription camera;
  final ExpressionType expressionType;

  const TrainingScreen({
    super.key,
    required this.camera,
    this.expressionType = ExpressionType.smile,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late camera_ctrl.AppCameraController _cameraController;
  bool _isTraining = false;
  Timer? _timer;
  int _remainingSeconds = 0;
  int _currentSet = 1;
  final int _totalSets = 3;
  _SessionPhase _phase = _SessionPhase.idle;
  bool _navigatedToResult = false;

  // --- API 연동 ---
  final _api = TrainingApiService();
  String? _sid;
  bool _saving = false;

  // 세트당 15프레임 좌표 버퍼 (각 프레임은 {키:{x,y}} 맵)
  final List<Map<String, Map<String, num>>> _framePoints = [];

  void _showInfo(String text, {Color bg = const Color(0xFF323232)}) {
    Get.snackbar(
      text,
      '',
      snackPosition: SnackPosition.TOP,
      backgroundColor: bg.withOpacity(0.95),
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    _cameraController = Get.put(camera_ctrl.AppCameraController());
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraController.initializeCamera(widget.camera);
    if (_cameraController.isInitialized.value) {
      await _cameraController.startStream();
    }
  }

  // 현재 점수
  double _currentScore() {
    switch (widget.expressionType) {
      case ExpressionType.smile:
        return _cameraController.smileScore.value;
      case ExpressionType.sad:
        return _cameraController.sadScore.value;
      case ExpressionType.angry:
        return _cameraController.angryScore.value;
      case ExpressionType.neutral:
        return _cameraController.neutralScore.value;
    }
  }

  // === 핵심 변경: Landmark → 서버 키 정확 매핑 ===
  // 서버가 요구하는 키셋:
  // bottomMouth, leftMouth, rightMouth, leftEye, rightEye, leftCheek, rightCheek, noseBase
  Map<String, Map<String, num>> _extractPoints() {
    final faces = _cameraController.detectedFaces; // List<Face>
    if (faces.isEmpty) {
      // 최소 형식으로 채워 검증 통과 (프레임은 반드시 1개 이상 포인트)
      return {'noop': {'x': 0, 'y': 0}};
    }
    final f = faces.first;

    Map<String, Map<String, num>> out = {};

    // landmark helper
    Map<String, Map<String, num>> lm(String key, FaceLandmarkType t) {
      final landmark = f.landmarks[t];
      if (landmark == null) return {};
      final p = landmark.position;
      return {key: {'x': p.x, 'y': p.y}};
    }

    // 1) Landmark로 1:1 매핑
    out.addAll(lm('bottomMouth', FaceLandmarkType.bottomMouth));
    out.addAll(lm('leftMouth',   FaceLandmarkType.leftMouth));
    out.addAll(lm('rightMouth',  FaceLandmarkType.rightMouth));
    out.addAll(lm('leftEye',     FaceLandmarkType.leftEye));
    out.addAll(lm('rightEye',    FaceLandmarkType.rightEye));
    out.addAll(lm('leftCheek',   FaceLandmarkType.leftCheek));
    out.addAll(lm('rightCheek',  FaceLandmarkType.rightCheek));
    out.addAll(lm('noseBase',    FaceLandmarkType.noseBase));

    // 2) 일부 기기/환경에서 landmark가 비는 경우 대비: contour로 보완(평균점)
    Map<String, Map<String, num>> fromOffsetsAvg(String key, FaceContourType t) {
      final pts = f.contours[t]?.points;
      if (pts == null || pts.isEmpty) return {};
      double sx = 0, sy = 0;
      for (final p in pts) { sx += p.x; sy += p.y; }
      final n = pts.length;
      return {key: {'x': sx / n, 'y': sy / n}};
    }

    out.putIfAbsent('leftEye',  () => fromOffsetsAvg('leftEye',  FaceContourType.leftEye)['leftEye']  ?? {});
    out.putIfAbsent('rightEye', () => fromOffsetsAvg('rightEye', FaceContourType.rightEye)['rightEye'] ?? {});
    // 입술 보완: 위/아래 윤곽 평균
    if (!out.containsKey('bottomMouth')) {
      final c1 = f.contours[FaceContourType.lowerLipBottom]?.points ?? const [];
      final c2 = f.contours[FaceContourType.lowerLipTop]?.points    ?? const [];
      final pts = [...c1, ...c2];
      if (pts.isNotEmpty) {
        double sx = 0, sy = 0;
        for (final p in pts) { sx += p.x; sy += p.y; }
        final n = pts.length;
        out['bottomMouth'] = {'x': sx / n, 'y': sy / n};
      }
    }

    if (out.isEmpty) out['noop'] = {'x': 0, 'y': 0};
    return out;
  }

  Future<void> _ensureServerSession() async {
    if (_sid != null) return;
    try {
      _sid = await _api.startSession(widget.expressionType.name);
    } catch (e) {
      _showInfo('세션 시작 실패: $e', bg: AppColors.error);
    }
  }

  void _toggleTraining() async {
    setState(() {
      _isTraining = !_isTraining;
    });
    if (_isTraining) {
      await _ensureServerSession();

      _cameraController.setSessionActive(true);
      _cameraController.setSessionRest(false);
      if (_phase == _SessionPhase.idle || _phase == _SessionPhase.done) {
        _currentSet = 1;
        _phase = _SessionPhase.training;
        _remainingSeconds = 15;
        _framePoints.clear();
      }
      _navigatedToResult = false;
      _showInfo('훈련 시작 - $_currentSet세트/$_totalSets세트 (15초)', bg: AppColors.accent);
      _startTimer();
    } else {
      _cameraController.setSessionActive(false);
      _cameraController.setSessionRest(false);
      _stopTimer();
      _showInfo('훈련 중지', bg: AppColors.error);
      if (_sid != null) {
        try { await _api.closeSession(sid: _sid!, summary: 'stopped'); } catch (_) {}
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 1초에 한 번 좌표 샘플 확보(훈련 중에만)
      if (_phase == _SessionPhase.training) {
        _framePoints.add(_extractPoints());
      }

      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds -= 1;
        if (_remainingSeconds <= 0) _advancePhase();
      });
    });
  }

  void _stopTimer() { _timer?.cancel(); _timer = null; }

  Future<void> _saveCurrentSet() async {
    if (_sid == null || _saving) return;
    _saving = true;
    try {
      // 길이 보정: 정확히 15프레임
      final frames = List<Map<String, Map<String, num>>>.from(_framePoints);
      while (frames.length < 15) {
        frames.add(frames.isNotEmpty ? frames.last : {'noop': {'x': 0, 'y': 0}});
      }
      if (frames.length > 15) frames.removeRange(15, frames.length);

      await _api.saveSet(
        sid: _sid!,
        score: _currentScore(),
        frames: frames,
      );
    } catch (e) {
      _showInfo('세트 저장 실패: $e', bg: AppColors.error);
    } finally {
      _saving = false;
    }
  }

  void _advancePhase() async {
    if (_phase == _SessionPhase.training) {
      // 세트 저장
      await _saveCurrentSet();

      if (_currentSet < _totalSets) {
        _phase = _SessionPhase.rest;
        _remainingSeconds = 10;
        _cameraController.setSessionRest(true);
        _showInfo('휴식 (10초)', bg: AppColors.warning);
      } else {
        _phase = _SessionPhase.done;
        _isTraining = false;
        _stopTimer();
        _cameraController.setSessionActive(false);
        _cameraController.setSessionRest(false);

        // 세션 마감
        if (_sid != null) {
          try {
            await _api.closeSession(
              sid: _sid!,
              summary: 'completed',
            );
          } catch (e) {
            _showInfo('세션 마감 실패: $e', bg: AppColors.error);
          }
        }

        final double finalScore = _currentScore();
        _showInfo('훈련 완료! 수고하셨어요 👍', bg: AppColors.success);
        if (mounted && !_navigatedToResult) {
          _navigatedToResult = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Get.off(() => TrainingResultScreen(
              expressionType: widget.expressionType,
              finalScore: finalScore,
            ));
          });
        }
      }
    } else if (_phase == _SessionPhase.rest) {
      _currentSet += 1;
      _phase = _SessionPhase.training;
      _remainingSeconds = 15;
      _cameraController.setSessionRest(false);
      _framePoints.clear(); // 다음 세트 수집을 위해 리셋
      _showInfo('훈련 재개 - $_currentSet세트/$_totalSets세트 (15초)', bg: AppColors.accent);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _getTitle() {
    switch (widget.expressionType) {
      case ExpressionType.smile:   return '웃는 표정 훈련';
      case ExpressionType.sad:     return '슬픈 표정 훈련';
      case ExpressionType.angry:   return '화난 표정 훈련';
      case ExpressionType.neutral: return '무표정 유지 훈련';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getTitle(),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.only(left: AppSizes.md, right: AppSizes.md, top: AppSizes.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Obx(() {
                  if (_cameraController.isInitialized.value) {
                    final score = _currentScore();

                    String? label;
                    switch (_phase) {
                      case _SessionPhase.training: label = '훈련'; break;
                      case _SessionPhase.rest:     label = '휴식'; break;
                      case _SessionPhase.idle:
                      case _SessionPhase.done:     label = '중지'; break;
                    }
                    String? big = (_remainingSeconds > 0 && _remainingSeconds <= 5)
                        ? _remainingSeconds.toString() : null;

                    return CameraPreviewWidget(
                      controller: _cameraController.controller!,
                      isFaceDetected: _cameraController.isFaceDetected.value,
                      detectedFaces: _cameraController.detectedFaces,
                      score: score,
                      neutralStateProvider: widget.expressionType == ExpressionType.neutral
                          ? (() => _cameraController.neutralState.value)
                          : null,
                      debugNeutral: widget.expressionType == ExpressionType.neutral
                          ? _cameraController.neutralDebugEnabled.value
                          : false,
                      setsCount: _currentSet,
                      timerText: _formatTime(_remainingSeconds),
                      sessionLabel: label,
                      bigCountdownText: big,
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                }),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(AppSizes.md),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(() {
                      final score = _currentScore();
                      return ScoreDisplayWidget(
                        score: score,
                        isTraining: _isTraining,
                        expressionType: widget.expressionType,
                      );
                    }),
                    const SizedBox(height: AppSizes.sm),
                    Obx(() {
                      final score = _currentScore();
                      return FeedbackWidget(
                        isFaceDetected: _cameraController.isFaceDetected.value,
                        score: score,
                        isTraining: _isTraining,
                        expressionType: widget.expressionType,
                      );
                    }),
                    const SizedBox(height: AppSizes.lg),
                    ElevatedButton(
                      onPressed: _toggleTraining,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: Text(_isTraining ? '훈련 중지' : '훈련 시작'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopTimer();
    _cameraController.stopStream();
    super.dispose();
  }
}