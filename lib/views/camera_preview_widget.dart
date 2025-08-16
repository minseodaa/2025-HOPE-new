import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../utils/constants.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final bool isFaceDetected;
  final dynamic detectedFaces; // RxList<Face> 또는 List<Face>를 받을 수 있도록

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.isFaceDetected,
    this.detectedFaces,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 카메라 프리뷰
        CameraPreview(controller),

        // 얼굴 특징점 오버레이 (단일 CustomPaint로 모든 얼굴 처리 + 카메라 프레임에 맞춰 repaint)
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

class FaceLandmarksPainter extends CustomPainter {
  final List<Face> Function() facesProvider;
  final Size imageSize;
  final CameraLensDirection cameraLensDirection;

  FaceLandmarksPainter({
    required this.facesProvider,
    required this.imageSize,
    required this.cameraLensDirection,
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final faces = facesProvider();
    if (faces.isEmpty || imageSize.width == 0 || imageSize.height == 0) return;

    // portrait에서 camera preview는 90도 회전된 좌표계를 갖는 경우가 많아 width/height를 스왑하여 스케일 계산
    final double previewWidth = imageSize.height;
    final double previewHeight = imageSize.width;
    final double scaleX = size.width / previewWidth;
    final double scaleY = size.height / previewHeight;

    final landmarkPaint = Paint()
      ..color = Colors.lightGreenAccent
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final face in faces) {
      // 바운딩 박스 변환 및 그리기
      final Rect raw = face.boundingBox;
      Rect rect = Rect.fromLTWH(
        raw.left * scaleX,
        raw.top * scaleY,
        raw.width * scaleX,
        raw.height * scaleY,
      );
      if (cameraLensDirection == CameraLensDirection.front) {
        rect = Rect.fromLTWH(
          size.width - rect.right,
          rect.top,
          rect.width,
          rect.height,
        );
      }
      canvas.drawRect(rect, borderPaint);

      // 랜드마크 그리기
      for (final entry in face.landmarks.entries) {
        final landmark = entry.value;
        if (landmark == null) continue;
        double x = landmark.position.x * scaleX;
        double y = landmark.position.y * scaleY;
        if (cameraLensDirection == CameraLensDirection.front) {
          x = size.width - x;
        }
        if (x < 0 || y < 0 || x > size.width || y > size.height) continue;
        canvas.drawCircle(Offset(x, y), 4.0, landmarkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FaceLandmarksPainter oldDelegate) {
    // repaint Listenable(controller)로 프레임마다 자동 갱신되므로 여기서는 false
    return false;
  }
}
