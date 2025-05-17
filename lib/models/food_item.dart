import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String imageUrl;
  final double protein;
  final double fat;
  final DateTime timestamp;
  final String? name;

  FoodItem({
    required this.id,
    required this.imageUrl,
    required this.protein,
    required this.fat,
    required this.timestamp,
    this.name,
  });

  factory FoodItem.fromMap(Map<String, dynamic> data, String id) {
    return FoodItem(
      id: id,
      imageUrl: data['imageUrl'] ?? '',
      protein: (data['protein'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      name: data['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'protein': protein,
      'fat': fat,
      'timestamp': Timestamp.fromDate(timestamp),
      if (name != null) 'name': name,
    };
  }
}
