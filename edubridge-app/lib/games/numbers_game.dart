import 'package:flutter/material.dart';
import 'choice_learning_game.dart';

class NumbersGame extends StatelessWidget {
  const NumbersGame({super.key, required this.childName});
  final String childName;
  @override
  Widget build(BuildContext context) => ChoiceLearningGame(
    topic: LearningTopic.numbers, childName: childName);
}
