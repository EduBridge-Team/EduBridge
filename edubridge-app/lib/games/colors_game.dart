import 'package:flutter/material.dart';
import 'choice_learning_game.dart';

class ColorsGame extends StatelessWidget {
  const ColorsGame({super.key, required this.childName});
  final String childName;
  @override
  Widget build(BuildContext context) => ChoiceLearningGame(
    topic: LearningTopic.colors, childName: childName);
}
