import 'package:flutter/material.dart';
import '../domain/game_player.dart';
import '../../../utils/game_catalog.dart';
import '../../../games/advanced_reading_game.dart';
import '../../../games/audio_matching_game.dart';
import '../../../games/colors_game.dart';
import '../../../games/logic_puzzle_game.dart';
import '../../../games/matching_game.dart';
import '../../../games/math_race_game.dart';
import '../../../games/numbers_game.dart';
import '../../../games/quick_action_game.dart';
import '../../../games/rhythm_game.dart';
import '../../../games/sequence_game.dart';
import '../../../games/shapes_game.dart';
import '../../../games/sign_language_game.dart';
import '../../../games/story_sequencer_game.dart';
import '../../../games/symbols_game.dart';
import '../../../games/visual_words_game.dart';
import '../../../games/word_builder_game.dart';

class GameScreenFactory {
  GameScreenFactory._();

  static String canonicalId(String id) => const {
    'audio': 'audio_matching', 'colors': 'colors_simple',
    'symbols': 'colors_symbols', 'numbers': 'numbers_count',
    'math': 'numbers_math', 'sequence': 'sequence_simple',
    'story': 'story_sequencer', 'sign': 'sign_language', 'quick': 'quick_action',
  }[id] ?? id;

  static GameInfo? info(String id) {
    for (final game in kGameCatalog) {
      if (game.id == canonicalId(id)) return game;
    }
    return null;
  }

  static Widget? build(String id, GamePlayer player) {
    Widget? screen;
    switch (canonicalId(id)) {
      case 'animal_sounds':
      case 'audio_matching':
        screen = AudioMatchingGame(childName: player.name);
        break;
      case 'matching':
        screen = MatchingGame(childName: player.name);
        break;
      case 'shapes':
        screen = ShapesGame(childName: player.name, age: player.age);
        break;
      case 'colors_simple':
        screen = ColorsGame(childName: player.name);
        break;
      case 'colors_symbols':
        screen = SymbolsGame(childName: player.name);
        break;
      case 'numbers_count':
        screen = NumbersGame(childName: player.name);
        break;
      case 'numbers_math':
        screen = MathRaceGame(childName: player.name, age: player.age);
        break;
      case 'visual_words':
        screen = VisualWordsGame(childName: player.name, age: player.age);
        break;
      case 'word_builder':
        screen = WordBuilderGame(childName: player.name, age: player.age);
        break;
      case 'sequence_simple':
        screen = SequenceGame(childName: player.name);
        break;
      case 'story_sequencer':
        screen = StorySequencerGame(childName: player.name, age: player.age);
        break;
      case 'logic_puzzle':
        screen = LogicPuzzleGame(childName: player.name);
        break;
      case 'sign_language':
        screen = SignLanguageGame(childName: player.name);
        break;
      case 'quick_action':
        screen = QuickActionGame(childName: player.name);
        break;
      case 'rhythm':
        screen = RhythmGame(childName: player.name);
        break;
      case 'advanced_reading':
        screen = AdvancedReadingGame(childName: player.name);
        break;
    }

    return screen;
  }
}
