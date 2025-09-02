import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  }

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
        title: Text(_getTitle(), style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(AppSizes.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Obx(() {
                  if (_cameraController.isInitialized.value) {
                    // ## 추가: 현재 표정에 맞는 점수를 가져옴 ##
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
                    return CameraPreviewWidget(
                      controller: _cameraController.controller!,
                      isFaceDetected: _cameraController.isFaceDetected.value,
                      detectedFaces: _cameraController.detectedFaces,
                      score: score, // ## 추가: CameraPreviewWidget으로 score 전달 ##
                      neutralStateProvider: widget.expressionType == ExpressionType.neutral
                          ? (() => _cameraController.neutralState.value)
                          : null,
                      debugNeutral: widget.expressionType == ExpressionType.neutral
                          ? _cameraController.neutralDebugEnabled.value
                          : false,
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Column(
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
                  const SizedBox(height: AppSizes.md),
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
                    child: Text(_isTraining ? '훈련 중지' : '훈련 시작'),
                  ),
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
    _cameraController.stopStream();
    super.dispose();
  }
}