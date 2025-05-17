import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera/ScanFood.dart';
import 'screens/food_list_screen.dart';
import 'services/food_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// FoodItem import removed as it's not directly used in this file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

// Moved to after Firebase imports

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String appTitle = 'Food Calories Analyzer';
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(title: const Text(appTitle)),
        body: Column(
          children: [
            // Main content - takes all available space
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Add your main content widgets here
                    // Example:
                    // ImageSection(image: 'assets/example.jpg'),
                    // TextSection(description: 'Your description here'),
                    // Add some sample content to see the scrolling
                    Container(
                      height: 1000, // Just for testing - remove this in production
                      color: Colors.grey[200],
                      child: const Center(child: Text('Scrollable Content')),
                    ),
                  ],
                ),
              ),
            ),
            // Buttons at the bottom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: const ButtonSection(),
            ),
          ],
        ),
      ),
    );
  }
}

class ButtonSection extends StatelessWidget {
  const ButtonSection({super.key});

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ButtonWithText(color: color, icon: Icons.camera, label: 'Camera'),
          ButtonWithText(color: color, icon: Icons.list, label: 'List')
        ],
      ),
    );
  }
}

class ButtonWithText extends StatelessWidget {
  const ButtonWithText({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;
  
  // Function to handle button press
  Future<void> _onPressed(BuildContext context) async {
    if (label.toLowerCase() == 'camera') {
      try {
        // Get available cameras
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No cameras found on this device')),
            );
          }
          return;
        }
        final firstCamera = cameras.first;
        
        // Navigate to ScanFood screen
        if (context.mounted) {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (context) => ScanFood(camera: firstCamera),
            ),
          );

          // Handle the result when coming back from ScanFood screen
          if (result != null && context.mounted) {
            try {
              final foodService = FoodService();
              await foodService.addFoodItem(
                imagePath: result['imagePath'] ?? '',
                protein: result['protein'] ?? 0.0,
                fat: result['fat'] ?? 0.0,
                name: result['name'] ?? 'Unknown Food',
              );
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Food item saved!')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving food item: $e')),
                );
              }
            }
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error accessing camera: $e')),
          );
        }
      }
    } else if (label.toLowerCase() == 'list') {
      // Navigate to food list screen
      if (context.mounted) {
        final foodService = FoodService();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodListScreen(
              foodItemsStream: foodService.getFoodItems(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onPressed(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageSection extends StatelessWidget {
  const ImageSection({super.key, required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return Image.asset(image, width: 600, height: 240, fit: BoxFit.cover);
  }
}

class _FoodDetailsDialog extends StatefulWidget {
  final String photoPath;

  const _FoodDetailsDialog({required this.photoPath});

  @override
  _FoodDetailsDialogState createState() => _FoodDetailsDialogState();
}

class _FoodDetailsDialogState extends State<_FoodDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Food Details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Food image preview
              Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(widget.photoPath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Food name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Food Name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Protein amount
              TextFormField(
                controller: _proteinController,
                decoration: const InputDecoration(
                  labelText: 'Protein (g)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter protein amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Fat amount
              TextFormField(
                controller: _fatController,
                decoration: const InputDecoration(
                  labelText: 'Fat (g)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter fat amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.isEmpty ? null : _nameController.text,
                'protein': double.parse(_proteinController.text),
                'fat': double.parse(_fatController.text),
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}