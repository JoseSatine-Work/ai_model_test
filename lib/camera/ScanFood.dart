import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../services/food_service.dart';

class ScanFood extends StatelessWidget {
  final CameraDescription camera;
  const ScanFood({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScanFoodScreen(camera: camera),
    );
  }
}

class ScanFoodScreen extends StatefulWidget {
  final CameraDescription camera;
  const ScanFoodScreen({super.key, required this.camera});

  @override
  State<ScanFoodScreen> createState() => _ScanFoodScreenState();
}

class _ScanFoodScreenState extends State<ScanFoodScreen> {
  late CameraController _cameraController;
  Future<void>? _initializeControllerFuture;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _takePicture() async {
    try {
      // Ensure the camera is initialized
      await _initializeControllerFuture;

      // Capture the picture
      final image = await _cameraController.takePicture();

      // Update the state with the captured image
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analyze Your Food',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(height: 24),

            // Camera Preview or Captured Image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_capturedImage == null)
                      // Camera Preview
                      FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CameraPreview(_cameraController),
                            );
                          } else {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        },
                      )
                    else
                      // Captured Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_capturedImage!.path),
                          fit: BoxFit.cover,
                          width: 300,
                          height: 400,
                        ),
                      ),
                    // Green Border
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Descriptive Text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                "Place your dish in the square to analyze and view calories",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
            ),
            const Spacer(),

            // Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Retake Button
                  if (_capturedImage != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _capturedImage = null;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Retake',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  
                  // Take Picture / Save Button
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: _capturedImage != null ? 8.0 : 0.0,
                      ),
                      child: ElevatedButton(
                        onPressed: _capturedImage == null
                            ? _takePicture
                            : () async {
                                try {
                                  // Add food item to Firestore
                                  final foodService = FoodService();
                                  await foodService.addFoodItem(
                                    imagePath: _capturedImage!.path,
                                    protein: 0.0, // TODO: Replace with actual analysis
                                    fat: 0.0, // TODO: Replace with actual analysis
                                    name: 'Captured Food', // TODO: Replace with actual food name
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Food item saved successfully!'),
                                      ),
                                    );
                                    Navigator.pop(context); // Go back to previous screen
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error saving food item: $e')),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _capturedImage == null ? Colors.blue : Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _capturedImage == null ? 'Take Picture' : 'Save Food',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
