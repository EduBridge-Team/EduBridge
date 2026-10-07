import 'package:flutter/material.dart';
import 'choice_learning_game.dart';

class ShapesGame extends StatelessWidget {
  const ShapesGame({super.key, required this.childName, required this.age});
  final String childName;
  final int age;
  @override
  Widget build(BuildContext context) => ChoiceLearningGame(
    topic: LearningTopic.shapes, childName: childName, age: age);
}
