import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';

import '../utils/constants.dart';
import 'expression_select_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  final CameraDescription camera;

  const HomeScreen({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => Get.offAllNamed('/login'),
            label: const Text(''), //로그아웃
            icon: const Icon(Icons.logout, size: 18),
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(title: '훈련모드'),
            const SizedBox(height: AppSizes.md),
            InkWell(
              onTap: () => Get.to(() => ExpressionSelectScreen(camera: camera)),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Ink(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.textTertiary.withOpacity(0.2),
                  ),
                ),
                child: _WeekCalendar(initialDate: DateTime.now()),
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            _SectionHeader(title: '훈련기록'),
            const SizedBox(height: AppSizes.md),
            _BigCard(
              icon: Icons.bar_chart_rounded,
              title: '훈련기록 보기',
              subtitle: '리스트로 최근 기록을 확인해요',
              onTap: () => Get.to(() => const HistoryScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 3, width: 140, color: AppColors.textPrimary),
      ],
    );
  }
}

class _WeekCalendar extends StatefulWidget {
  final DateTime initialDate;

  const _WeekCalendar({required this.initialDate});

  @override
  State<_WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<_WeekCalendar> {
  late DateTime _focused;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _focused = _stripTime(widget.initialDate);
    _selected = _focused;
  }

  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfWeek(DateTime d) {
    final int delta = d.weekday % 7; // Sun=7 -> 0
    return _stripTime(d.subtract(Duration(days: delta)));
  }

  void _changeWeek(int deltaWeeks) {
    setState(() {
      _focused = _focused.add(Duration(days: 7 * deltaWeeks));
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = _startOfWeek(_focused);
    final days = List<DateTime>.generate(
      7,
      (i) => start.add(Duration(days: i)),
    );
    final monthLabel = DateFormat('y년 M월', 'ko').format(_focused);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              monthLabel,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => _changeWeek(-1),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => _changeWeek(1),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Dow('일'),
            _Dow('월'),
            _Dow('화'),
            _Dow('수'),
            _Dow('목'),
            _Dow('금'),
            _Dow('토'),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: days.map((d) {
            final bool isSelected = _selected == d;
            return Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color.fromARGB(255, 0, 106, 255).withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Dow extends StatelessWidget {
  final String text;
  const _Dow(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BigCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Ink(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(width: AppSizes.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
