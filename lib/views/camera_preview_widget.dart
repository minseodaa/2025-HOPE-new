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

        // 얼굴 특징점 오버레이
        if (isFaceDetected &&
            detectedFaces != null &&
            detectedFaces!.isNotEmpty)
          ...detectedFaces!.map((face) => _buildFaceLandmarks(face)),

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

  Widget _buildFaceLandmarks(Face face) {
    return CustomPaint(
      painter: FaceLandmarksPainter(face),
      child: Container(width: double.infinity, height: double.infinity),
    );
  }
}

class FaceLandmarksPainter extends CustomPainter {
  final Face face;

  FaceLandmarksPainter(this.face);

  @override
  void paint(Canvas canvas, Size size) {
    // 얼굴 바운딩 박스 그리기
    _drawFaceBoundingBox(canvas, size);

    // 얼굴 특징점 그리기
    _drawLandmarks(canvas, size);

    // 디버깅: 얼굴 위치 정보 출력
    print('원본 얼굴 바운딩 박스: ${face.boundingBox}');
  }

  void _drawFaceBoundingBox(Canvas canvas, Size size) {
    final boundingBox = face.boundingBox;

    // ML Kit에서 받은 좌표는 픽셀 단위이므로 화면 크기에 맞게 스케일링
    final rect = Rect.fromLTWH(
      boundingBox.left * size.width / 537.0, // 카메라 해상도에 맞게 조정
      boundingBox.top * size.height / 720.0, // 카메라 해상도에 맞게 조정
      boundingBox.width * size.width / 537.0, // 카메라 해상도에 맞게 조정
      boundingBox.height * size.height / 720.0, // 카메라 해상도에 맞게 조정
    );

    // 바운딩 박스를 파란색 선으로 그리기
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(rect, borderPaint);

    // 바운딩 박스 중앙에 파란 점 그리기
    final centerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(rect.center.dx, rect.center.dy),
      10.0,
      centerPaint,
    );

    // 디버깅: 변환된 바운딩 박스 정보 출력
    print('변환된 바운딩 박스: $rect - 화면 크기: ${size.width}x${size.height}');
  }

  void _drawLandmarks(Canvas canvas, Size size) {
    // 모든 특징점을 노란색으로 그리기
    final landmarkPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    // 특징점 개수 디버깅
    print('얼굴 특징점 개수: ${face.landmarks.length}');

    for (final entry in face.landmarks.entries) {
      final landmark = entry.value;
      if (landmark != null) {
        final position = landmark.position;

        // ML Kit에서 받은 좌표는 이미 픽셀 단위이므로 화면 크기에 맞게 스케일링
        double x = position.x * size.width / 537.0; // 카메라 해상도에 맞게 조정
        double y = position.y * size.height / 720.0; // 카메라 해상도에 맞게 조정

        // 화면 범위 내에 있는지 확인
        if (x >= 0 && x <= size.width && y >= 0 && y <= size.height) {
          // 특징점 위치 디버깅
          print(
            '특징점 ${entry.key}: 원본(${position.x}, ${position.y}) -> 변환($x, $y) - 화면 크기: ${size.width}x${size.height}',
          );

          // 특징점 그리기
          canvas.drawCircle(
            Offset(x, y),
            8.0, // 크기를 적당하게
            landmarkPaint,
          );
        } else {
          print('특징점 ${entry.key}가 화면 범위를 벗어남: ($x, $y)');
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // 항상 다시 그리도록 설정 (실시간 업데이트를 위해)
    return true;
  }
}
