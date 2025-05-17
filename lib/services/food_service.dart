import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:model_test/models/food_item.dart';

class FoodService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the 'food_items' collection
  CollectionReference<Map<String, dynamic>> get _foodItemsCollection => 
      _firestore.collection('food_items');

  // Add a new food item
  Future<void> addFoodItem({
    required String imagePath,
    required double protein,
    required double fat,
    String? name,
  }) async {
    try {
      // Upload image to Firebase Storage
      final String fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child('food_images/$fileName');
      final UploadTask uploadTask = storageRef.putFile(File(imagePath));
      final TaskSnapshot storageSnapshot = await uploadTask;
      final String imageUrl = await storageSnapshot.ref.getDownloadURL();

      // Add food item to Firestore
      await _foodItemsCollection.add({
        'imageUrl': imageUrl,
        'protein': protein,
        'fat': fat,
        'timestamp': FieldValue.serverTimestamp(),
        if (name != null) 'name': name,
      });
    } catch (e) {
      print('Error adding food item: $e');
      rethrow;
    }
  }

  // Get all food items as a stream
  Stream<List<FoodItem>> getFoodItems() {
    return _foodItemsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FoodItem.fromMap(doc.data(), doc.id))
            .toList());
  }
}
