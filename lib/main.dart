import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'controllers/camera_controller.dart' as camera_ctrl;
import 'views/training_screen.dart';
import 'utils/constants.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 카메라 권한 요청
  await Permission.camera.request();

  // 사용 가능한 카메라 목록 가져오기
  final cameras = await availableCameras();

  // 전면 카메라 찾기
  CameraDescription? frontCamera;
  for (final camera in cameras) {
    if (camera.lensDirection == CameraLensDirection.front) {
      frontCamera = camera;
      break;
    }
  }

  // 전면 카메라가 없으면 첫 번째 카메라 사용
  final selectedCamera = frontCamera ?? cameras.first;

  runApp(MyApp(camera: selectedCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '스마트 표정 훈련기',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      home: TrainingScreen(camera: camera),
      debugShowCheckedModeBanner: false,
    );
  }
}
