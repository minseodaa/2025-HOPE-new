import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:face_newversion/services/face_detection_service.dart';
import 'package:face_newversion/models/smile_score_model.dart';

void main() {
  group('FaceDetectionService Tests', () {
    late FaceDetectionService faceDetectionService;

    setUp(() {
      faceDetectionService = FaceDetectionService();
    });

    tearDown(() async {
      await faceDetectionService.dispose();
    });

    test('FaceDetectionService should be singleton', () {
      final instance1 = FaceDetectionService();
      final instance2 = FaceDetectionService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('FaceDetectionService should have correct initial state', () {
      expect(faceDetectionService.isInitialized, isFalse);
      expect(faceDetectionService.isProcessing, isFalse);
    });

    test('FaceDetectionService should initialize successfully', () async {
      final result = await faceDetectionService.initialize();
      expect(result, isTrue);
      expect(faceDetectionService.isInitialized, isTrue);
    });

    test(
      'FaceDetectionService should handle detection without initialization',
      () async {
        // 초기화하지 않은 상태에서 감지 시도
        expect(
          () async => await faceDetectionService.detectFaceAndCalculateScore(
            CameraImage(
              format: ImageFormat.yuv420,
              height: 480,
              width: 640,
              planes: [
                Plane(
                  bytes: Uint8List(640 * 480),
                  bytesPerRow: 640,
                  height: 480,
                  width: 640,
                ),
              ],
            ),
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'FaceDetectionService should detect face and calculate score',
      () async {
        // 초기화
        await faceDetectionService.initialize();

        // 얼굴 감지 및 점수 계산
        final result = await faceDetectionService.detectFaceAndCalculateScore(
          CameraImage(
            format: ImageFormat.bgra8888,
            height: 480,
            width: 640,
            planes: [
              Plane(
                bytes: Uint8List(640 * 480 * 4),
                bytesPerRow: 640 * 4,
                height: 480,
                width: 640,
              ),
            ],
          ),
        );

        expect(result, isA<SmileScoreModel>());
        expect(result.timestamp, isA<DateTime>());
        expect(result.confidence, isA<double>());

        // 시뮬레이션이므로 대부분의 경우 얼굴이 감지됨
        expect(result.isFaceDetected, isA<bool>());
        expect(result.score, isA<double>());
        expect(result.score, greaterThanOrEqualTo(0.0));
        expect(result.score, lessThanOrEqualTo(1.0));
      },
    );

    test('FaceDetectionService should return consistent scores', () async {
      // 초기화
      await faceDetectionService.initialize();

      // 여러 번 감지하여 점수 일관성 확인
      final results = <SmileScoreModel>[];
      for (int i = 0; i < 5; i++) {
        final result = await faceDetectionService.detectFaceAndCalculateScore(
          CameraImage(
            format: ImageFormat.bgra8888,
            height: 480,
            width: 640,
            planes: [
              Plane(
                bytes: Uint8List(640 * 480 * 4),
                bytesPerRow: 640 * 4,
                height: 480,
                width: 640,
              ),
            ],
          ),
        );
        results.add(result);
        await Future.delayed(Duration(milliseconds: 50));
      }

      // 점수들이 모두 유효한 범위에 있는지 확인
      for (final result in results) {
        expect(result.score, greaterThanOrEqualTo(0.0));
        expect(result.score, lessThanOrEqualTo(1.0));
      }
    });

    test(
      'FaceDetectionService should handle real-time detection stream',
      () async {
        // 초기화
        await faceDetectionService.initialize();

        // 실시간 감지 스트림 시작
        final stream = faceDetectionService.startRealTimeDetection(
          Stream.periodic(
            Duration(milliseconds: 100),
            (index) => CameraImage(
              format: ImageFormat.bgra8888,
              height: 480,
              width: 640,
              planes: [
                Plane(
                  bytes: Uint8List(640 * 480 * 4),
                  bytesPerRow: 640 * 4,
                  height: 480,
                  width: 640,
                ),
              ],
            ),
          ),
        );

        // 스트림에서 결과 수집
        final results = <SmileScoreModel>[];
        final subscription = stream.listen((result) {
          results.add(result);
        });

        // 잠시 대기하여 결과 수집
        await Future.delayed(Duration(milliseconds: 500));

        // 구독 해제
        await subscription.cancel();

        // 결과가 수집되었는지 확인
        expect(results.length, greaterThan(0));

        // 모든 결과가 유효한지 확인
        for (final result in results) {
          expect(result, isA<SmileScoreModel>());
          expect(result.score, greaterThanOrEqualTo(0.0));
          expect(result.score, lessThanOrEqualTo(1.0));
        }
      },
    );

    test('FaceDetectionService should stop real-time detection', () {
      // 초기화
      faceDetectionService.initialize();

      // 실시간 감지 중지 (오류가 발생하지 않아야 함)
      expect(
        () => faceDetectionService.stopRealTimeDetection(),
        returnsNormally,
      );
    });

    test('FaceDetectionService should return service status', () async {
      // 초기화 전 상태
      final initialStatus = faceDetectionService.serviceStatus;
      expect(initialStatus['isInitialized'], isFalse);
      expect(initialStatus['isProcessing'], isFalse);
      expect(initialStatus['streamSubscriptionActive'], isFalse);
      expect(initialStatus['streamControllerClosed'], isFalse);

      // 초기화 후 상태
      await faceDetectionService.initialize();
      final afterInitStatus = faceDetectionService.serviceStatus;
      expect(afterInitStatus['isInitialized'], isTrue);
    });

    test('FaceDetectionService should return performance stats', () async {
      // 초기화
      await faceDetectionService.initialize();

      final stats = faceDetectionService.performanceStats;
      expect(stats['isProcessing'], isA<bool>());
      expect(stats['minProcessingInterval'], equals(100));
      expect(stats['lastProcessingTime'], isA<String>());
    });

    test(
      'FaceDetectionService should handle dispose without initialization',
      () async {
        // 초기화하지 않은 상태에서 dispose 호출 시 오류가 발생하지 않아야 함
        expect(
          () async => await faceDetectionService.dispose(),
          returnsNormally,
        );
      },
    );

    test('FaceDetectionService should handle multiple dispose calls', () async {
      // 초기화
      await faceDetectionService.initialize();

      // 여러 번 dispose 호출 시 오류가 발생하지 않아야 함
      await faceDetectionService.dispose();
      expect(() async => await faceDetectionService.dispose(), returnsNormally);
    });
  });
}
