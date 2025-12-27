import 'package:flutter/material.dart';

class Folder {
  final String id;
  final String name;
  final String? description;
  final Color color;
  final IconData icon;
  final int notesCount;
  final DateTime lastUpdated;

  const Folder({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.notesCount,
    required this.lastUpdated,
    this.description,
  });
}
