import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 상수 정의
class AppConstants {
  // 앱 정보
  static const String appName = '스마트 표정 훈련기';
  static const String appVersion = '1.0.0';
  
  // 훈련 관련 상수
  static const String defaultTrainingTopic = '웃는 표정 학습';
  static const int minTrainingDurationSeconds = 30;
  static const int maxTrainingDurationMinutes = 60;
  
  // 점수 관련 상수
  static const double minSmileScore = 0.0;
  static const double maxSmileScore = 1.0;
  static const double highScoreThreshold = 0.8; // 80%
  static const double mediumScoreThreshold = 0.6; // 60%
  static const double lowScoreThreshold = 0.3; // 30%
  
  // 애니메이션 관련 상수
  static const Duration scoreAnimationDuration = Duration(milliseconds: 500);
  static const Duration feedbackAnimationDuration = Duration(milliseconds: 300);
  static const Duration transitionAnimationDuration = Duration(milliseconds: 250);
  
  // UI 관련 상수
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;
  
  // 카메라 관련 상수
  static const double cameraAspectRatio = 3 / 4;
  static const int cameraFrameRate = 30;
  static const int cameraResolution = 720;
  
  // 피드백 메시지
  static const Map<String, String> feedbackMessages = {
    'high': '완벽한 미소예요! 🎉',
    'medium': '지금 잘 웃고 있어요! 😊',
    'low': '더 웃으세요! 😄',
    'noFace': '얼굴이 카메라에 보이지 않아요.',
    'error': '오류가 발생했습니다. 다시 시도해주세요.',
  };
  
  // 에러 메시지
  static const Map<String, String> errorMessages = {
    'cameraPermission': '카메라 권한이 필요합니다.',
    'cameraInit': '카메라를 초기화할 수 없습니다.',
    'faceDetection': '얼굴 감지에 실패했습니다.',
    'network': '네트워크 연결을 확인해주세요.',
    'unknown': '알 수 없는 오류가 발생했습니다.',
  };
  
  // 색상 관련 상수
  static const int primaryColorValue = 0xFF2196F3;
  static const int secondaryColorValue = 0xFF4CAF50;
  static const int accentColorValue = 0xFFFF9800;
  static const int errorColorValue = 0xFFF44336;
  static const int successColorValue = 0xFF4CAF50;
  static const int warningColorValue = 0xFFFF9800;
  
  // 파일 경로
  static const String sessionDataPath = 'sessions';
  static const String settingsDataPath = 'settings';
  
  // 설정 키
  static const String keyFirstLaunch = 'first_launch';
  static const String keyCameraPermission = 'camera_permission';
  static const String keyTrainingHistory = 'training_history';
  static const String keyUserPreferences = 'user_preferences';
  
  // 기본값
  static const bool defaultFirstLaunch = true;
  static const bool defaultCameraPermission = false;
  static const List<String> defaultTrainingHistory = [];
  static const Map<String, dynamic> defaultUserPreferences = {
    'soundEnabled': true,
    'vibrationEnabled': true,
    'autoSave': true,
    'darkMode': false,
  };
}

/// 훈련 주제 상수
class TrainingTopics {
  static const String smileTraining = '웃는 표정 학습';
  static const String expressionTraining = '표정 표현 학습';
  static const String confidenceTraining = '자신감 표현 학습';
  static const String communicationTraining = '소통 표정 학습';
  
  static const List<String> allTopics = [
    smileTraining,
    expressionTraining,
    confidenceTraining,
    communicationTraining,
  ];
}

/// 애니메이션 곡선 상수
class AnimationCurves {
  static const curveEaseInOut = Curves.easeInOut;
  static const curveEaseIn = Curves.easeIn;
  static const curveEaseOut = Curves.easeOut;
  static const curveBounceOut = Curves.bounceOut;
  static const curveElasticOut = Curves.elasticOut;
} 