import 'package:flutter/material.dart';

enum GameType {
  classic,
  quiz,
  memory,  // Futur
}

class GameMode {
  final String id;
  final GameType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String routeName;

  const GameMode({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.routeName,
  });
}