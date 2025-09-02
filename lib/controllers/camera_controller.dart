import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/neutral_config.dart';
import '../models/neutral_state.dart';
import '../services/neutral_detector.dart';

class AppCameraController extends GetxController {
  CameraController? _controller;
  CameraDescription? _camera;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
      enableTracking: true,
      minFaceSize: 0.15,
    ),
  );

  final RxBool isInitialized = false.obs;
  final RxBool isStreaming = false.obs;
  final RxBool hasPermission = false.obs;
  final RxBool isFaceDetected = false.obs;
  final RxDouble smileScore = 0.0.obs;
  final RxDouble sadScore = 0.0.obs;
  final RxDouble angryScore = 0.0.obs; // ## 1. angryScore 변수 추가 ##
  final RxString activeExpression = 'smile'.obs;
  final RxString errorMessage = ''.obs;
  final RxList<Face> detectedFaces = <Face>[].obs;

  final NeutralDetector _neutralDetector = NeutralDetector();
  final Rx<NeutralState> neutralState = NeutralState.initial().obs;
  final RxBool neutralDebugEnabled = (NeutralConfig.debugPanelEnabled).obs;
  final RxDouble neutralScore = 0.0.obs;

  CameraController? get controller => _controller;
  FaceDetector get faceDetector => _faceDetector;

  @override
  void onInit() {
    super.onInit();
    _checkPermission();
    _neutralDetector.onNeutralSuccess = (s) {
      print(
        'Neutral success! hold=${s.metrics.holdSeconds.toStringAsFixed(1)}s',
      );
    };
  }

  @override
  void onClose() {
    _disposeController();
    _faceDetector.close();
    super.onClose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    hasPermission.value = status.isGranted;

    if (!hasPermission.value) {
      final result = await Permission.camera.request();
      hasPermission.value = result.isGranted;
    }
  }

  Future<void> initializeCamera(CameraDescription camera) async {
    try {
      await _checkPermission();
      if (!hasPermission.value) {
        errorMessage.value = '카메라 권한이 필요합니다';
        return;
      }
      _camera = camera;
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await _controller!.initialize();
      isInitialized.value = true;
      errorMessage.value = '';
      print('카메라 초기화 성공: ${camera.name}');
      neutralState.value = NeutralState.initial();
      neutralScore.value = 0.0;
    } catch (e) {
      errorMessage.value = '카메라 초기화에 실패했습니다: $e';
      isInitialized.value = false;
      print('카메라 초기화 실패: $e');
    }
  }

  Future<void> startStream() async {
    if (!isInitialized.value || _controller == null) {
      errorMessage.value = '카메라가 초기화되지 않았습니다';
      return;
    }
    try {
      _neutralDetector.resetCalibration();
      await _controller!.startImageStream(_processImage);
      isStreaming.value = true;
      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = '스트림 시작에 실패했습니다: $e';
      isStreaming.value = false;
    }
  }

  Future<void> stopStream() async {
    if (_controller != null && isStreaming.value) {
      try {
        await _controller!.stopImageStream();
        isStreaming.value = false;
        isFaceDetected.value = false;
        detectedFaces.clear();
        smileScore.value = 0.0;
        sadScore.value = 0.0; // sadScore 초기화 추가
        angryScore.value = 0.0; // ## 4. angryScore 초기화 추가 ##
        neutralState.value = NeutralState.initial();
        neutralScore.value = 0.0;
      } catch (e) {
        errorMessage.value = '스트림 중지에 실패했습니다: $e';
      }
    }
  }

  Future<void> _processImage(CameraImage image) async {
    try {
      final InputImage? inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        isFaceDetected.value = true;
        detectedFaces.value = faces;
        _updateExpressionScores(faces.first);
        _neutralDetector.feed(faces.first);
        neutralState.value = _neutralDetector.state;
        _updateNeutralScore();
      } else {
        isFaceDetected.value = false;
        detectedFaces.clear();
        smileScore.value = 0.0;
        sadScore.value = 0.0;
        angryScore.value = 0.0; // ## 얼굴 미감지 시 angryScore 초기화 ##
        neutralState.value = neutralState.value.copyWith(
          phase: NeutralPhase.idle,
          metrics: neutralState.value.metrics.copyWith(holdSeconds: 0.0),
        );
        neutralScore.value = 0.0;
      }
    } catch (e) {
      print('이미지 처리 오류: $e');
      errorMessage.value = '이미지 처리 중 오류가 발생했습니다: $e';
    }
  }

  void _updateNeutralScore() {
    final double score = (1.0 - smileScore.value).clamp(0.0, 1.0);
    neutralScore.value = score;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_camera == null) return null;
    final camera = _camera!;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _calculateSmileScore(Face face) {
    smileScore.value = face.smilingProbability?.clamp(0.0, 1.0) ?? 0.0;
  }

  // ## 수정: 슬픈 표정 점수 계산 로직 추가 ##
  void _calculateSadScore(Face face) {
    // 입 주변 랜드마크 위치 가져오기
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    // 랜드마크가 없으면 점수 계산 불가
    if (leftMouth == null || rightMouth == null || bottomMouth == null) {
      sadScore.value = 0.0;
      return;
    }

    // 1. 입꼬리가 아랫입술 중앙보다 얼마나 내려갔는지 계산
    // y 좌표는 아래로 갈수록 값이 커집니다.
    final mouthCornerY = (leftMouth.y + rightMouth.y) / 2.0;
    final bottomMouthY = bottomMouth.y;

    // 얼굴 크기에 따라 정규화하여 일관된 값 얻기
    final droop = (mouthCornerY - bottomMouthY) / (face.boundingBox.height * 0.1);
    final droopScore = droop.clamp(0.0, 1.0);

    // 2. 웃음기가 없을수록 슬픔 점수 증가
    final smileProb = face.smilingProbability ?? 0.0;
    final noSmileScore = 1.0 - smileProb;

    // 3. 두 점수를 가중 평균하여 최종 점수 계산
    final finalScore = (droopScore * 0.7 + noSmileScore * 0.3);

    // 점수 변화를 더 분명하게 하기 위해 가중치를 곱하고 0.0 ~ 1.0 사이로 조정
    sadScore.value = (finalScore * 1.5).clamp(0.0, 1.0);
  }


  void _calculateAngryScore(Face face) {
    final double? leftEyeOpen = face.leftEyeOpenProbability;
    final double? rightEyeOpen = face.rightEyeOpenProbability;
    final double? smilingProb = face.smilingProbability;

    if (leftEyeOpen == null || rightEyeOpen == null || smilingProb == null) {
      angryScore.value = 0.0;
      return;
    }
    final avgEyeOpenProb = (leftEyeOpen + rightEyeOpen) / 2.0;
    final eyeScore = 1.0 - avgEyeOpenProb;
    final mouthScore = 1.0 - smilingProb;
    final finalScore = (eyeScore * 0.7 + mouthScore * 0.3);
    angryScore.value = (finalScore * 1.2).clamp(0.0, 1.0);
  }

  void _updateExpressionScores(Face face) {
    _calculateSmileScore(face);
    _calculateSadScore(face);
    _calculateAngryScore(face);
  }

  void setActiveExpression(String expression) {
    activeExpression.value = expression;
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    isInitialized.value = false;
    isStreaming.value = false;
  }

  void clearError() {
    errorMessage.value = '';
  }
}