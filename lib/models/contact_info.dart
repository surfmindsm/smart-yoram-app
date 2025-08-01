import 'package:flutter/material.dart';

class ContactInfo {
  final String name;
  final String phone;
  final String position;
  final String initial;
  final Color color;

  ContactInfo({
    required this.name,
    required this.phone,
    required this.position,
    required this.initial,
    required this.color,
  });

  @override
  String toString() {
    return 'ContactInfo{name: $name, phone: $phone, position: $position}';
  }
}
