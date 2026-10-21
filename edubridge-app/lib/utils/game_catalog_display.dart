import '../l10n/generated/app_localizations.dart';
import 'game_catalog.dart';

/// Localized presentation leaves eligibility and canonical catalog values intact.
class GameCatalogDisplay {
  static String title(GameInfo game, AppLocalizations s) => switch (game.id) {
    'animal_sounds' => s.gameCatalogAnimalSoundsTitle,
    'matching' => s.gameCatalogMatchingTitle,
    'shapes' => s.gameCatalogShapesTitle,
    'colors_simple' => s.gameCatalogColorsSimpleTitle,
    'colors_symbols' => s.gameCatalogColorsSymbolsTitle,
    'numbers_count' => s.gameCatalogNumbersCountTitle,
    'numbers_math' => s.gameCatalogNumbersMathTitle,
    'visual_words' => s.gameCatalogVisualWordsTitle,
    'word_builder' => s.gameCatalogWordBuilderTitle,
    'sequence_simple' => s.gameCatalogSequenceSimpleTitle,
    'story_sequencer' => s.gameCatalogStorySequencerTitle,
    'logic_puzzle' => s.gameCatalogLogicPuzzleTitle,
    'audio_matching' => s.gameCatalogAudioMatchingTitle,
    'sign_language' => s.gameCatalogSignLanguageTitle,
    'quick_action' => s.gameCatalogQuickActionTitle,
    'rhythm' => s.gameCatalogRhythmTitle,
    'advanced_reading' => s.gameCatalogAdvancedReadingTitle,
    _ => game.title,
  };

  static String description(GameInfo game, AppLocalizations s) => switch (game.id) {
    'animal_sounds' => s.gameCatalogAnimalSoundsDescription,
    'matching' => s.gameCatalogMatchingDescription,
    'shapes' => s.gameCatalogShapesDescription,
    'colors_simple' => s.gameCatalogColorsSimpleDescription,
    'colors_symbols' => s.gameCatalogColorsSymbolsDescription,
    'numbers_count' => s.gameCatalogNumbersCountDescription,
    'numbers_math' => s.gameCatalogNumbersMathDescription,
    'visual_words' => s.gameCatalogVisualWordsDescription,
    'word_builder' => s.gameCatalogWordBuilderDescription,
    'sequence_simple' => s.gameCatalogSequenceSimpleDescription,
    'story_sequencer' => s.gameCatalogStorySequencerDescription,
    'logic_puzzle' => s.gameCatalogLogicPuzzleDescription,
    'audio_matching' => s.gameCatalogAudioMatchingDescription,
    'sign_language' => s.gameCatalogSignLanguageDescription,
    'quick_action' => s.gameCatalogQuickActionDescription,
    'rhythm' => s.gameCatalogRhythmDescription,
    'advanced_reading' => s.gameCatalogAdvancedReadingDescription,
    _ => game.description,
  };

  static String age(AgeGroup group, AppLocalizations s) => switch (group) {
    AgeGroup.preschool => s.gameCatalogPreschool,
    AgeGroup.primary => s.gameCatalogPrimary,
    AgeGroup.preparatory => s.gameCatalogPreparatory,
  };
}
