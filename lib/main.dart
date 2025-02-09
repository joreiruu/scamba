import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SpamDetectionApp(),
    );
  }
}

class SpamDetectionApp extends StatefulWidget {
  @override
  _SpamDetectionAppState createState() => _SpamDetectionAppState();
}

class _SpamDetectionAppState extends State<SpamDetectionApp> {
  TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String _result = "";
  double _confidence = 0.0;
  int _inferenceTime = 0;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/spam_model.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future<void> classifyText(String text) async {
    setState(() {
      _isLoading = true;
    });
    final startTime = DateTime.now().millisecondsSinceEpoch;

    var predictions = await Tflite.runModelOnText(
      text: text,
      numResults: 2,
      threshold: 0.5,
    );

    final endTime = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _isLoading = false;
      if (predictions != null && predictions.isNotEmpty) {
        _result = predictions[0]['label'];
        _confidence = predictions[0]['confidence'];
        _inferenceTime = endTime - startTime;
      } else {
        _result = "Error in classification";
        _confidence = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scamba")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter SMS Text",
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoading
                    ? CircularProgressIndicator()
                    : SizedBox.shrink(),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => classifyText(_controller.text),
                  child: Text("Predict"),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_result.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text("Prediction: $_result", style: TextStyle(fontSize: 18)),
                    Text("Confidence: ${(_confidence * 100).toStringAsFixed(2)}%"),
                    Text("Inference Time: ${_inferenceTime}ms"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}