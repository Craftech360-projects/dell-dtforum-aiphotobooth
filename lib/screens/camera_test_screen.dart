import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraTestScreen extends StatefulWidget {
  const CameraTestScreen({super.key});

  @override
  State<CameraTestScreen> createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen> {
  String _status = 'Initializing...';
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _checkCameraAvailability();
  }

  Future<void> _checkCameraAvailability() async {
    try {
      setState(() {
        _status = 'Checking for cameras...';
      });

      final cameras = await availableCameras();
      
      setState(() {
        _cameras = cameras;
        if (cameras.isEmpty) {
          _status = 'No cameras found!';
        } else {
          _status = 'Found ${cameras.length} camera(s):\n';
          for (var camera in cameras) {
            _status += '- ${camera.name} (${camera.lensDirection})\n';
          }
        }
      });
    } on Exception catch (e) {
      setState(() {
        _status = 'Error: $e\n\n'
            'Please ensure:\n'
            '1. You have granted camera permissions\n'
            '2. You are running on localhost or HTTPS\n'
            '3. Your browser supports WebRTC';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkCameraAvailability,
                child: const Text('Retry Camera Check'),
              ),
              const SizedBox(height: 20),
              if (_cameras != null && _cameras!.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CameraTestScreen(),
                      ),
                    );
                  },
                  child: const Text('Go to Face Capture'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}