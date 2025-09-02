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
  final double score;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.isFaceDetected,
    this.detectedFaces,
    this.neutralStateProvider,
    this.debugNeutral = false,
    this.score = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      // ## 수정: Stack의 정렬 기준을 중앙으로 설정 ##
      alignment: Alignment.center,
      children: [
        // ## 수정: FittedBox를 사용하여 화면을 꽉 채우도록 변경 ##
        if (controller.value.isInitialized)
          ClipRect( // FittedBox가 확대시킨 위젯의 바깥 부분을 잘라냅니다.
            child: FittedBox(
              fit: BoxFit.cover, // виджет을 부모 위젯에 꽉 채웁니다 (비율 유지, 일부 잘릴 수 있음).
              child: SizedBox(
                // 카메라 영상의 원본 크기(가로/세로 전환)로 SizedBox를 만듭니다.
                width: controller.value.previewSize!.height,
                height: controller.value.previewSize!.width,
                child: CameraPreview(controller),
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
              score: score,
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

        // 얼굴 감지 표시
        if (isFaceDetected)
          Positioned(
            top: AppSizes.md,
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

// FaceLandmarksPainter 클래스는 변경사항 없습니다.
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