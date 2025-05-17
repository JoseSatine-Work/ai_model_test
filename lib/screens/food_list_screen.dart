import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:model_test/models/food_item.dart';

class FoodListScreen extends StatelessWidget {
  final Stream<List<FoodItem>> foodItemsStream;

  const FoodListScreen({
    super.key,
    required this.foodItemsStream,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food History'),
      ),
      body: StreamBuilder<List<FoodItem>>(
        stream: foodItemsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final foodItems = snapshot.data ?? [];

          if (foodItems.isEmpty) {
            return const Center(child: Text('No food items found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: foodItems.length,
            itemBuilder: (context, index) {
              final foodItem = foodItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (foodItem.name != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            foodItem.name!,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Food image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: foodItem.imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Food details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timestamp   
                                Text(
                                  DateFormat('MMM d, y - hh:mm a').format(foodItem.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Nutrition info
                                _buildNutritionInfo('Protein', '${foodItem.protein.toStringAsFixed(1)}g'),
                                const SizedBox(height: 4),
                                _buildNutritionInfo('Fat', '${foodItem.fat.toStringAsFixed(1)}g'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNutritionInfo(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Text(value),
      ],
    );
  }
}
