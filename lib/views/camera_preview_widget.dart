import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../utils/constants.dart';
import '../models/neutral_state.dart';
import '../painters/face_overlay.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final bool isFaceDetected;
  final dynamic detectedFaces;
  final NeutralState Function()? neutralStateProvider;
  final bool debugNeutral;

  // ## 병합: 점수 파라미터 (버전 1) ##
  final double score;

  // ## 병합: 타이머 및 세션 정보 파라미터 (버전 2) ##
  final int? setsCount;
  final String? timerText;
  final String? sessionLabel; // '훈련', '휴식', '중지'
  final String? bigCountdownText; // 마지막 5초 카운트 표시용

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.isFaceDetected,
    this.detectedFaces,
    this.neutralStateProvider,
    this.debugNeutral = false,
    this.score = 0.0,
    this.setsCount,
    this.timerText,
    this.sessionLabel,
    this.bigCountdownText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ## 수정: FittedBox를 사용하여 화면을 꽉 채우도록 변경 ##
        if (controller.value.isInitialized)
          SizedBox.expand( // Stack의 모든 공간을 차지하도록 함
            child: ClipRect( // FittedBox가 확대시킨 위젯의 바깥 부분을 잘라냄
              child: FittedBox(
                fit: BoxFit.cover, // 자식의 비율을 유지하면서 부모에 꽉 채움 (가장 중요!)
                child: SizedBox(
                  // 카메라 영상의 원본 비율대로 크기를 지정
                  width: controller.value.previewSize!.height,
                  height: controller.value.previewSize!.width,
                  child: CameraPreview(controller),
                ),
              ),
            ),
          ),

        // 얼굴 특징점 오버레이
        if (isFaceDetected &&
            detectedFaces != null &&
            detectedFaces!.isNotEmpty)
          CustomPaint(
            painter: FaceLandmarksPainter(
              facesProvider: () {
                try {
                  if (detectedFaces is List<Face>) {
                    return detectedFaces as List<Face>;
                  }
                  if (detectedFaces is Iterable) {
                    return List<Face>.from(detectedFaces as Iterable);
                  }
                } catch (_) {}
                return const <Face>[];
              },
              imageSize: controller.value.previewSize ?? const Size(0, 0),
              cameraLensDirection: controller.description.lensDirection,
              score: score, // ## 병합: 점수 전달 (버전 1) ##
              repaint: controller,
            ),
            child: const SizedBox.expand(),
          ),

        // 무표정 가이드/디버그 오버레이
        if (isFaceDetected &&
            detectedFaces != null &&
            detectedFaces!.isNotEmpty)
          CustomPaint(
            painter: FaceOverlayPainter(
              facesProvider: () {
                try {
                  if (detectedFaces is List<Face>) {
                    return detectedFaces as List<Face>;
                  }
                  if (detectedFaces is Iterable) {
                    return List<Face>.from(detectedFaces as Iterable);
                  }
                } catch (_) {}
                return const <Face>[];
              },
              imageSize: controller.value.previewSize ?? const Size(0, 0),
              cameraLensDirection: controller.description.lensDirection,
              neutralStateProvider: neutralStateProvider,
              debugEnabled: debugNeutral,
              repaint: controller,
            ),
            child: const SizedBox.expand(),
          ),

        // ## 병합: 좌상단 세트 수 표시 (버전 2) ##
        if (setsCount != null)
          Positioned(
            top: AppSizes.md,
            left: AppSizes.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.accent.withOpacity(0.6)),
              ),
              child: Text(
                '세트 $setsCount',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // ## 병합: 우상단 타이머 표시 (버전 2) ##
        if (timerText != null)
          Positioned(
            top: AppSizes.md,
            right: AppSizes.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                timerText!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // ## 병합: 상단 중앙 세션 상태 라벨 (버전 2) ##
        if (sessionLabel != null)
          Positioned(
            top: AppSizes.md,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  sessionLabel!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

        // ## 병합: 중앙 큰 카운트다운 (버전 2) ##
        if (bigCountdownText != null && bigCountdownText!.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                alignment: Alignment.center,
                color: Colors.black.withOpacity(0.15),
                child: Text(
                  bigCountdownText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 96,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black54,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 얼굴 감지 오버레이
        if (!isFaceDetected)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.face_retouching_off,
                    size: 64,
                    color: AppColors.error,
                  ),
                  SizedBox(height: AppSizes.md),
                  Text(
                    '얼굴이 감지되지 않았어요',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // 얼굴 감지 표시 (타이머가 있을 때 위치 조정)
        if (isFaceDetected)
          Positioned(
            top: timerText != null ? (AppSizes.md + 36) : AppSizes.md,
            right: AppSizes.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.face, color: AppColors.surface, size: 16),
                  SizedBox(width: AppSizes.xs),
                  Text(
                    AppStrings.faceDetected,
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class FaceLandmarksPainter extends CustomPainter {
  final List<Face> Function() facesProvider;
  final Size imageSize;
  final CameraLensDirection cameraLensDirection;
  final double score;

  FaceLandmarksPainter({
    required this.facesProvider,
    required this.imageSize,
    required this.cameraLensDirection,
    required this.score,
    Listenable? repaint,
  }) : super(repaint: repaint);

  Color _getLandmarkColor(double score) {
    if (score >= AppConstants.highScoreThreshold) {
      return Colors.greenAccent;
    } else if (score >= AppConstants.mediumScoreThreshold) {
      return Colors.yellowAccent;
    } else {
      return Colors.redAccent;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final faces = facesProvider();
    if (faces.isEmpty || imageSize.width == 0 || imageSize.height == 0) return;

    final double imageWidth = imageSize.height;
    final double imageHeight = imageSize.width;
    final double scale = (size.width / imageWidth) > (size.height / imageHeight)
        ? (size.width / imageWidth)
        : (size.height / imageHeight);
    final double scaledWidth = imageWidth * scale;
    final double scaledHeight = imageHeight * scale;
    final double dx = (size.width - scaledWidth) / 2.0;
    final double dy = (size.height - scaledHeight) / 2.0;

    final landmarkPaint = Paint()
      ..color = _getLandmarkColor(score)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final contourPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;


    for (final face in faces) {
      final Rect raw = face.boundingBox;
      double left = dx + raw.left * scale;
      double top = dy + raw.top * scale;
      double width = raw.width * scale;
      double height = raw.height * scale;
      if (cameraLensDirection == CameraLensDirection.front) {
        left = dx + (scaledWidth - (raw.left + raw.width) * scale);
      }
      final Rect screenRect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRect(screenRect, borderPaint);

      for (final contour in face.contours.values) {
        if (contour == null) continue;
        for (final point in contour.points) {
          double sx = dx + point.x * scale;
          double sy = dy + point.y * scale;
          if (cameraLensDirection == CameraLensDirection.front) {
            sx = dx + (scaledWidth - point.x * scale);
          }
          if (sx < 0 || sy < 0 || sx > size.width || sy > size.height) continue;
          canvas.drawCircle(Offset(sx, sy), 2.0, contourPaint);
        }
      }

      for (final entry in face.landmarks.entries) {
        final landmark = entry.value;
        if (landmark == null) continue;
        double sx = dx + landmark.position.x * scale;
        double sy = dy + landmark.position.y * scale;
        if (cameraLensDirection == CameraLensDirection.front) {
          sx = dx + (scaledWidth - landmark.position.x * scale);
        }
        if (sx < 0 || sy < 0 || sx > size.width || sy > size.height) continue;
        canvas.drawCircle(Offset(sx, sy), 4.0, landmarkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FaceLandmarksPainter oldDelegate) {
    return false;
  }
}