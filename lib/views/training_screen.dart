import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:camera/camera.dart';

import '../controllers/camera_controller.dart' as camera_ctrl;
import '../utils/constants.dart';
import '../models/expression_type.dart';
import 'camera_preview_widget.dart';
import 'score_display_widget.dart';
import 'feedback_widget.dart';
import 'training_log_screen.dart'; // training_log_screen.dart 대신 TrainingResultScreen을 사용한다고 가정

// TrainingResultScreen이 training_log_screen.dart로 이름이 변경되었다고 가정하고 import 경로 수정
// 만약 파일명이 다르다면 이 부분을 실제 파일명으로 수정해주세요.
// 예: import 'training_log_screen.dart';

// 임시 TrainingResultScreen 클래스 (실제 파일이 있을 경우 이 부분은 삭제)
class TrainingResultScreen extends StatelessWidget {
  final ExpressionType expressionType;
  final double finalScore;
  final int totalSets;

  const TrainingResultScreen({
    super.key,
    required this.expressionType,
    required this.finalScore,
    required this.totalSets
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("훈련 결과")),
      body: Center(
        child: Text(
          '훈련 완료!\n표정: $expressionType\n점수: ${(finalScore * 100).toStringAsFixed(1)}%',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


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

  void _toggleTraining() {
    setState(() {
      _isTraining = !_isTraining;
    });
    if (_isTraining) {
      _cameraController.setSessionActive(true);
      _cameraController.setSessionRest(false);
      if (_phase == _SessionPhase.idle || _phase == _SessionPhase.done) {
        _currentSet = 1;
        _phase = _SessionPhase.training;
        _remainingSeconds = 15;
      }
      _navigatedToResult = false;
      _showInfo('훈련 시작 - $_currentSet세트/$_totalSets세트 (15초)', bg: AppColors.accent);
      _startTimer();
    } else {
      _cameraController.setSessionActive(false);
      _cameraController.setSessionRest(false);
      _stopTimer();
      _showInfo('훈련 중지', bg: AppColors.error);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds -= 1;
        }
        if (_remainingSeconds <= 0) {
          _advancePhase();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _advancePhase() {
    if (_phase == _SessionPhase.training) {
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
        _showInfo('훈련 완료! 수고하셨어요 👍', bg: AppColors.success);
        // 결과 화면으로 이동
        final double finalScore;
        switch (widget.expressionType) {
          case ExpressionType.smile:
            finalScore = _cameraController.smileScore.value;
            break;
          case ExpressionType.sad:
            finalScore = _cameraController.sadScore.value;
            break;
          case ExpressionType.angry:
            finalScore = _cameraController.angryScore.value;
            break;
          case ExpressionType.neutral:
            finalScore = _cameraController.neutralScore.value;
            break;
        }
        if (mounted && !_navigatedToResult) {
          _navigatedToResult = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            // Get.to()를 사용하여 페이지 이동
            Get.to(() => TrainingResultScreen(
              expressionType: widget.expressionType,
              finalScore: finalScore,
              totalSets: _totalSets,
            ));
          });
        }
      }
    } else if (_phase == _SessionPhase.rest) {
      _currentSet += 1;
      _phase = _SessionPhase.training;
      _remainingSeconds = 15;
      _cameraController.setSessionRest(false);
      _showInfo('훈련 재개 - $_currentSet세트/$_totalSets세트 (15초)', bg: AppColors.accent);
    }
  }

  String _formatTime(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    final String mm = m.toString().padLeft(2, '0');
    final String ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _getTitle() {
    switch (widget.expressionType) {
      case ExpressionType.smile:
        return '웃는 표정 훈련';
      case ExpressionType.sad:
        return '슬픈 표정 훈련';
      case ExpressionType.angry:
        return '화난 표정 훈련';
      case ExpressionType.neutral:
        return '무표정 유지 훈련';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(color: AppColors.textPrimary),
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
              margin: const EdgeInsets.only(
                left: AppSizes.md,
                right: AppSizes.md,
                top: AppSizes.md,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Obx(() {
                  if (_cameraController.isInitialized.value) {
                    final double score;
                    switch (widget.expressionType) {
                      case ExpressionType.smile:
                        score = _cameraController.smileScore.value;
                        break;
                      case ExpressionType.sad:
                        score = _cameraController.sadScore.value;
                        break;
                      case ExpressionType.angry:
                        score = _cameraController.angryScore.value;
                        break;
                      case ExpressionType.neutral:
                        score = _cameraController.neutralScore.value;
                        break;
                    }
                    String? label;
                    switch (_phase) {
                      case _SessionPhase.training:
                        label = '훈련';
                        break;
                      case _SessionPhase.rest:
                        label = '휴식';
                        break;
                      case _SessionPhase.idle:
                      case _SessionPhase.done:
                        label = '중지';
                        break;
                    }
                    String? big;
                    if (_remainingSeconds > 0 && _remainingSeconds <= 5) {
                      big = _remainingSeconds.toString();
                    }
                    return CameraPreviewWidget(
                      controller: _cameraController.controller!,
                      isFaceDetected: _cameraController.isFaceDetected.value,
                      detectedFaces: _cameraController.detectedFaces,
                      score: score,
                      neutralStateProvider:
                      widget.expressionType == ExpressionType.neutral
                          ? (() => _cameraController.neutralState.value)
                          : null,
                      debugNeutral:
                      widget.expressionType == ExpressionType.neutral
                          ? _cameraController.neutralDebugEnabled.value
                          : false,
                      setsCount: _currentSet,
                      timerText: _formatTime(_remainingSeconds),
                      sessionLabel: label,
                      bigCountdownText: big,
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }),
              ),
            ),
          ),
          // ## 수정: 하단 UI 영역 ##
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(AppSizes.md),
              child: SingleChildScrollView( // ## 추가: 스크롤 가능하도록 변경
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // ## 추가: 가운데 정렬
                  children: [
                    Obx(() {
                      final double score;
                      switch (widget.expressionType) {
                        case ExpressionType.smile:
                          score = _cameraController.smileScore.value;
                          break;
                        case ExpressionType.sad:
                          score = _cameraController.sadScore.value;
                          break;
                        case ExpressionType.angry:
                          score = _cameraController.angryScore.value;
                          break;
                        case ExpressionType.neutral:
                          score = _cameraController.neutralScore.value;
                          break;
                      }
                      return ScoreDisplayWidget(
                        score: score,
                        isTraining: _isTraining,
                        expressionType: widget.expressionType,
                      );
                    }),
                    const SizedBox(height: AppSizes.sm),
                    Obx(() {
                      final double score;
                      switch (widget.expressionType) {
                        case ExpressionType.smile:
                          score = _cameraController.smileScore.value;
                          break;
                        case ExpressionType.sad:
                          score = _cameraController.sadScore.value;
                          break;
                        case ExpressionType.angry:
                          score = _cameraController.angryScore.value;
                          break;
                        case ExpressionType.neutral:
                          score = _cameraController.neutralScore.value;
                          break;
                      }
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
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                      child: Text(_isTraining ? '훈련 중지' : '훈련 시작'),
                    ),
                    // const Spacer(), // ## 삭제: Spacer 제거
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