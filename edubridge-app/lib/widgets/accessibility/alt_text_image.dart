// lib/widgets/adaptive/alt_text_image.dart
// صورة مع وصف نصي وصوتي
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_helper.dart';

class AltTextImage extends StatelessWidget {
  final String imageUrl;
  final String altText;             // وصف مختصر
  final String? detailedDescription; // وصف مفصل
  final double? width;
  final double? height;
  final BoxFit fit;

  const AltTextImage({
    super.key,
    required this.imageUrl,
    required this.altText,
    this.detailedDescription,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        final shouldDescribe = profile.detailedAltText ||
            profile.type == DisabilityType.blind ||
            profile.autoReadOnTap;

        final imageWidget = Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.broken_image)),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: width,
              height: height,
              color: Colors.grey.shade100,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        );

        if (!shouldDescribe) return imageWidget;

        return GestureDetector(
          onTap: () {
            final description = detailedDescription ?? altText;
            AdaptiveHelper.speak(description);
          },
          child: Semantics(
            label: altText,
            image: true,
            child: Stack(
              children: [
                imageWidget,
                // شارة "وصف"
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.record_voice_over,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}