import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Category {
  final String id;
  String name;
  Color color;
  IconData icon;

  Category({
    String? id,
    required this.name,
    required this.color,
    required this.icon,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'icon': icon.codePoint,
      'fontFamily': icon.fontFamily,
      'fontPackage': icon.fontPackage,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
      icon: IconData(
        map['icon'],
        fontFamily: map['fontFamily'],
        fontPackage: map['fontPackage'],
      ),
    );
  }

  Category copyWith({
    String? name,
    Color? color,
    IconData? icon,
  }) {
    return Category(
      id: this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
} 