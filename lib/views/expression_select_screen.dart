import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';

import '../models/expression_type.dart';
import '../utils/constants.dart';
import 'training_screen.dart';
import 'history_screen.dart';

class ExpressionSelectScreen extends StatelessWidget {
  final CameraDescription camera;

  const ExpressionSelectScreen({super.key, required this.camera});

  void _navigate(BuildContext context, ExpressionType type) {
    Get.to(() => TrainingScreen(camera: camera, expressionType: type));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '어떤 표정을 연습할까요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            ElevatedButton(
              onPressed: () => _navigate(context, ExpressionType.smile),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('웃는 표정 짓기 😊', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: AppSizes.md),
            ElevatedButton(
              onPressed: () => _navigate(context, ExpressionType.sad),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('슬픈 표정 짓기 😢', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: AppSizes.md),
            ElevatedButton(
              onPressed: () =>
                  _navigate(context, ExpressionType.angry), // ## 화난 표정 버튼 추가 ##
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('화난 표정 짓기 😠', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: AppSizes.md),
            ElevatedButton(
              onPressed: () => _navigate(context, ExpressionType.neutral),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('무표정 짓기 😐', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: AppSizes.xl),
            OutlinedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.textSecondary),
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('기록 보기', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
