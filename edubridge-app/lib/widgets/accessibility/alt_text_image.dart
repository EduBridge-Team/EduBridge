import '../../l10n/l10n.dart';
import '../../utils/content_speech_language.dart';
// lib/widgets/adaptive/alt_text_image.dart
// صورة مع وصف نصي وصوتي
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_helper.dart';
import 'adaptive_wrapper.dart';

class AltTextImage extends StatelessWidget {
  final String imageUrl;
  final String altText;             // وصف مختصر
  final String? detailedDescription; // وصف مفصل
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? speechLanguageCode;

  const AltTextImage({
    super.key,
    required this.imageUrl,
    required this.altText,
    this.detailedDescription,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.speechLanguageCode,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        if (profile.textOnlyMode || TextOnlyScope.of(context)) {
          final description = profile.detailedAltText ? detailedDescription ?? altText : altText;
          return Text(description, style: TextStyle(fontSize: AdaptiveHelper.bodyFontSize));
        }
        void readDescription() {
          final text = profile.detailedAltText ? detailedDescription ?? altText : altText;
          AdaptiveHelper.speak(text, languageCode: ContentSpeechLanguage.resolve(text,
            override: speechLanguageCode, fallback: context.l10n.localeName));
        }
        final shouldDescribe = profile.detailedAltText || AdaptiveHelper.shouldReadOnTap;

        final imageWidget = Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          semanticLabel: altText,
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
          onTap: readDescription,
          child: Semantics(
            label: altText,
            excludeSemantics: true,
            image: true,
            onTap: readDescription,
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