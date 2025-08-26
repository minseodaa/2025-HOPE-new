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
  int _elapsedSeconds = 0;

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
      _elapsedSeconds = 0;
      _cameraController.resetNeutralSets();
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds += 1;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatElapsed(int seconds) {
    final int mm = seconds ~/ 60;
    final int ss = seconds % 60;
    final String mmStr = mm.toString().padLeft(2, '0');
    final String ssStr = ss.toString().padLeft(2, '0');
    return '$mmStr:$ssStr';
  }

  // ## 제목을 switch문으로 변경하여 angry 추가 ##
  String _getTitle() {
    switch (widget.expressionType) {
      case ExpressionType.smile:
        return '스마트 표정 훈련기';
      case ExpressionType.sad:
        return '슬픈 표정 진척도';
      case ExpressionType.angry:
        return '화난 표정 진척도';
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
                    return CameraPreviewWidget(
                      controller: _cameraController.controller!,
                      isFaceDetected: _cameraController.isFaceDetected.value,
                      detectedFaces: _cameraController.detectedFaces,
                      neutralStateProvider:
                          widget.expressionType == ExpressionType.neutral
                          ? (() => _cameraController.neutralState.value)
                          : null,
                      debugNeutral:
                          widget.expressionType == ExpressionType.neutral
                          ? _cameraController.neutralDebugEnabled.value
                          : false,
                      setsCount: _cameraController.neutralSets.value,
                      timerText: _formatElapsed(_elapsedSeconds),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.only(
                left: AppSizes.md,
                right: AppSizes.md,
                bottom: AppSizes.md,
              ),
              child: Column(
                children: [
                  Obx(() {
                    // ## 점수를 switch문으로 변경하여 angry 추가 ##
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
                      expressionType:
                          widget.expressionType, // expressionType 전달
                    );
                  }),
                  Obx(() {
                    // ## FeedbackWidget에도 동일하게 적용 ##
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
                      score: score, // smileScore 대신 일반 score 전달
                      isTraining: _isTraining,
                      expressionType:
                          widget.expressionType, // expressionType 전달
                    );
                  }),

                  ElevatedButton(
                    onPressed: _toggleTraining,
                    child: Text(_isTraining ? '훈련 중지' : '훈련 시작'),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  const Spacer(),
                ],
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
