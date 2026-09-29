// lib/widgets/skeletons.dart
// ═══════════════════════════════════════════════════════════
//  Skeleton Loaders موحّدة
//  - بديل أنيق للـ CircularProgressIndicator
//  - تُظهر شكل المحتوى قبل وصوله (إحساس سرعة)
//  - تحترم reducedAnimations (للكفيف والتوحد)
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../theme.dart';

// ═══════════════════════════════════════════════════════════
//  بلوك Skeleton أساسي
// ═══════════════════════════════════════════════════════════
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 12,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final profile = AccessibilityService.instance.profile.value;

    // ═══ احترام reducedAnimations (للتوحد والكفيف) ═══
    if (profile.reducedAnimations ||
        profile.type == DisabilityType.blind) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: c.line.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * t, 0),
              end: Alignment(1.0 + 2 * t, 0),
              colors: [
                c.line.withValues(alpha: 0.3),
                c.line.withValues(alpha: 0.7),
                c.line.withValues(alpha: 0.3),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Skeleton بطاقة طفل (لولي الأمر والمعلم)
// ═══════════════════════════════════════════════════════════
class ChildCardSkeleton extends StatelessWidget {
  const ChildCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── الرأس: أفاتار + اسم + شارة ───
          Row(
            children: [
              const SkeletonBox(width: 52, height: 52, radius: 26),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 16),
                    SizedBox(height: 6),
                    SkeletonBox(width: 90, height: 12),
                  ],
                ),
              ),
              const SkeletonBox(width: 70, height: 24, radius: 12),
            ],
          ),
          const SizedBox(height: 16),

          // ─── الأزرار (3) ───
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 44)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 44)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 44)),
            ],
          ),
          const SizedBox(height: 8),

          // ─── زر "أفعال أخرى" ───
          const SkeletonBox(height: 44),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Skeleton بطاقة محادثة
// ═══════════════════════════════════════════════════════════
class ConversationSkeleton extends StatelessWidget {
  const ConversationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 48, height: 48, radius: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 130, height: 15),
                SizedBox(height: 6),
                SkeletonBox(width: 200, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkeletonBox(width: 50, height: 12),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Skeleton بطاقة درس
// ═══════════════════════════════════════════════════════════
class LessonCardSkeleton extends StatelessWidget {
  const LessonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 46, height: 46, radius: 14),
              const SizedBox(width: 12),
              const Expanded(
                child: SkeletonBox(width: 180, height: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonBox(height: 12),
          const SizedBox(height: 6),
          const SkeletonBox(width: 220, height: 12),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Skeleton بطاقة واجب
// ═══════════════════════════════════════════════════════════
class HomeworkCardSkeleton extends StatelessWidget {
  const HomeworkCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: SkeletonBox(width: 150, height: 16)),
              SizedBox(width: 8),
              SkeletonBox(width: 70, height: 22, radius: 10),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonBox(height: 12),
          const SizedBox(height: 6),
          const SkeletonBox(width: 180, height: 12),
          const SizedBox(height: 12),
          const SkeletonBox(height: 44),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Skeleton قائمة عامة (بسيطة)
// ═══════════════════════════════════════════════════════════
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: itemCount,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: const [
            SkeletonBox(width: 44, height: 44, radius: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 14),
                  SizedBox(height: 6),
                  SkeletonBox(width: 90, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}